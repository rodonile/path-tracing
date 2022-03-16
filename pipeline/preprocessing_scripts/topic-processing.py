###############
# Python script that consumes the pt.probe.processed topic from kafka, and produces to the pt.probe.global and pt.probe.hbh topic 
# 
# Requirements:
# pip install confluent-kafka
###############
from confluent_kafka import Consumer, KafkaError, Producer
import socket, time
from signal import signal, SIGINT
from sys import exit
import json, base64, ipaddress
from functools import partial


##############################
# CTRL-C Handler
##############################
def handler(producer, signal_received, frame):
    # Handle any cleanup here
    print('SIGINT or CTRL-C detected. Stopping pre-processing loop...')
    shutdown_consumer()
    producer.flush()
    time.sleep(2)
    print('Exiting gracefully...')
    exit(0)

running = True
def shutdown_consumer():
    # Stop consumer
    running = False

##############################
# Kafka producer checker (callback)
##############################
def acked(err, msg):
    if err is not None:
        print("Failed to deliver message: %s: %s" % (str(msg), str(err)))
    #else:
    #    print("Message produced: %s" % (str(msg)))

##############################
# Compute delay (given 2 t64 timestamps) in ms
##############################
def compute_delay(src_t64, dst_t64):
    # Separate t64 timestamps in s and ns part
    src_timestamp_s = divmod(src_t64,0x100000000)[0]
    src_timestamp_ns = divmod(src_t64,0x100000000)[1]
    dst_timestamp_s = divmod(dst_t64,0x100000000)[0]
    dst_timestamp_ns = divmod(dst_t64,0x100000000)[1]

    # Compute ns timestamps and delay
    ns_src_timestamp = (1e9) * src_timestamp_s + src_timestamp_ns
    ns_dst_timestamp = (1e9) * dst_timestamp_s + dst_timestamp_ns
    ns_delay = ns_dst_timestamp - ns_src_timestamp
    return ns_delay / (1e6)

##############################
# Consume loop for topic pt.probe.processed
##############################
def processing_loop(consumer, producer, consume_topics, tts_template, mapping, rollover_correction):
    try:
        consumer.subscribe(consume_topics)
        while running:
            msg = consumer.poll(timeout=1.0)
            if msg is None: continue
            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:     # End of partition event
                    sys.stderr.write('%% %s [%d] reached end at offset %d\n' %
                                     (msg.topic(), msg.partition(), msg.offset()))
                elif msg.error():
                    raise KafkaException(msg.error())
            else:
                # Start message processing
                msg_process(msg, producer, tts_template, mapping, rollover_correction)
    finally:
        consumer.close()            # Close down consumer to commit final offsets.


##############################
# Message deserialization, processing and producing messages in topics pt.probe.global and pt.probe.hbh
##############################
def msg_process(msg, producer, tts_template, mapping, rollover_correction):
    #print('Received message: {}'.format(msg.value().decode('utf-8')))
    json_dict = json.loads(msg.value())

    ############
    # pt.probe.global
    ############
    global_json_dict = dict(json_dict)
    global_json_dict['path_info'] = {}
    nodes_path_list = []

    # Create nodes_path_list and strings with concatenated node_ids, interface_ids, and interface_names
    # HINT: nodes_path_list, i.e. [vpp1, vpp2, vpp4, vpp6, vpp8], s.t. from turnilo it can be filtered i.e. nodes=vpp2
    nodes_path = json_dict['src_node']['node_id']
    nodes_path_list.append(json_dict['src_node']['node_id'])
    interface_id_path = str(json_dict['src_node']['out_interface_id'])
    interface_name_path = json_dict['src_node']['out_interface_name']
    for i in range(0, json_dict['midpoint_count']):
        nodes_path = nodes_path + " --> " + json_dict["path_info"][json_dict['midpoint_count']-1-i]['node_id']
        nodes_path_list.append(json_dict["path_info"][json_dict['midpoint_count']-1-i]['node_id'])
        interface_id_path = interface_id_path + " --> " + str(json_dict["path_info"][json_dict['midpoint_count']-1-i]['out_interface_id'])
        interface_name_path = interface_name_path + " --> " + json_dict["path_info"][json_dict['midpoint_count']-1-i]['out_interface_name']
    nodes_path = nodes_path + " --> " + json_dict['snk_node']['node_id']
    nodes_path_list.append(json_dict['snk_node']['node_id'])
    interface_id_path = interface_id_path + " --> " + str(json_dict['snk_node']['in_interface_id'])
    interface_name_path = interface_name_path + " --> " + json_dict['snk_node']['in_interface_name']

    # Populate pt.probe.global json with new path_info fields
    global_json_dict['path_info']['nodes_path'] = nodes_path
    global_json_dict['path_info']['nodes_path_list'] = nodes_path_list
    global_json_dict['path_info']['interface_id_path'] = interface_id_path
    global_json_dict['path_info']['interface_name_path'] = interface_name_path

    # Create string with concatenated SID list
    # Take only last parts of address otherwise to long to visualize in turnilo
    sid_list_full = ""
    for i in range(0, len(json_dict['sid_list'])):
        sid_list_full = sid_list_full + json_dict['sid_list'][i][10:]
        if i < len(json_dict['sid_list'])-1:
            sid_list_full = sid_list_full + " - "
    global_json_dict['sid_list_full'] = sid_list_full

    # Compute path delay
    global_json_dict['path_info']['delay'] = compute_delay(json_dict['src_node']['t64'],json_dict['snk_node']['t64'])

    # Serialize and produce to pt.probe.global topic
    global_json = json.dumps(global_json_dict)
    producer.produce('pt.probe.global', global_json, callback=acked)


    ############
    # pt.probe.hbh
    ############
    hbh_json_dict = dict(json_dict)
    hbh_json_dict['path_info'] = {}
    hbh_json_dict['link_info'] = {}

    # Full-path fields from pt.probe.global (could be useful here as well)
    hbh_json_dict['path_info']['nodes_path'] = nodes_path
    hbh_json_dict['path_info']['nodes_path_list'] = nodes_path_list
    hbh_json_dict['path_info']['interface_id_path'] = interface_id_path
    hbh_json_dict['path_info']['interface_name_path'] = interface_name_path
    hbh_json_dict['path_info']['delay'] = global_json_dict['path_info']['delay']
    hbh_json_dict['sid_list_full'] = sid_list_full

    #######
    # Explode: generate a kafka message for each hop (with new "link_info" field in json)
    #######
    # Src to first hop link (generate message and produce)
    hbh_json_dict['link_info']['src_node_id'] = json_dict['src_node']['node_id']
    hbh_json_dict['link_info']['dst_node_id'] = json_dict['path_info'][json_dict['midpoint_count']-1]['node_id']
    hbh_json_dict['link_info']['src_interface_id'] = json_dict['src_node']['out_interface_id']
    hbh_json_dict['link_info']['dst_interface_id'] = mapping[str(hbh_json_dict['link_info']['src_interface_id'])]['connected_interface']
    hbh_json_dict['link_info']['src_interface_name'] = json_dict['src_node']['out_interface_name']
    hbh_json_dict['link_info']['dst_interface_name'] = mapping[str(hbh_json_dict['link_info']['dst_interface_id'])]['interface_name']
    hbh_json_dict['link_info']['link_id'] = mapping[str(hbh_json_dict['link_info']['src_interface_id'])]['linux_bridge']
    hbh_json_dict['link_info']['src_t64'] = json_dict['src_node']['t64']
    hbh_json_dict['link_info']['dst_t64'] = json_dict['path_info'][json_dict['midpoint_count']-1]['t64']
    hbh_json_dict['link_info']['delay'] = compute_delay(json_dict['src_node']['t64'], json_dict['path_info'][json_dict['midpoint_count']-1]['t64'])

    # Correct rollover, only implemented for tts_template 2 for now
    if rollover_correction == True and hbh_json_dict['link_info']['delay'] > 60 and tts_template == 2:
        hbh_json_dict['link_info']['delay'] = hbh_json_dict['link_info']['delay'] - 66.84672

    hbh_json = json.dumps(hbh_json_dict)
    producer.produce('pt.probe.hbh', hbh_json, callback=acked)

    # Mid links (generate messages and produce)
    for i in range(0, json_dict['midpoint_count']-1):
        hbh_json_dict['link_info']['src_node_id'] = json_dict['path_info'][json_dict['midpoint_count']-i-1]['node_id']
        hbh_json_dict['link_info']['dst_node_id'] = json_dict['path_info'][json_dict['midpoint_count']-i-2]['node_id']
        hbh_json_dict['link_info']['src_interface_id'] = json_dict['path_info'][json_dict['midpoint_count']-i-1]['out_interface_id']
        hbh_json_dict['link_info']['dst_interface_id'] = mapping[str(hbh_json_dict['link_info']['src_interface_id'])]['connected_interface']
        hbh_json_dict['link_info']['src_interface_name'] = json_dict['path_info'][json_dict['midpoint_count']-i-1]['out_interface_name']
        hbh_json_dict['link_info']['dst_interface_name'] = mapping[str(hbh_json_dict['link_info']['dst_interface_id'])]['interface_name']
        hbh_json_dict['link_info']['link_id'] = mapping[str(hbh_json_dict['link_info']['src_interface_id'])]['linux_bridge']
        hbh_json_dict['link_info']['src_t64'] = json_dict['path_info'][json_dict['midpoint_count']-i-1]['t64']
        hbh_json_dict['link_info']['dst_t64'] = json_dict['path_info'][json_dict['midpoint_count']-i-2]['t64'] 
        hbh_json_dict['link_info']['delay'] = compute_delay(json_dict['path_info'][json_dict['midpoint_count']-i-1]['t64'],
                                                            json_dict['path_info'][json_dict['midpoint_count']-i-2]['t64'])

        # Correct rollover, only implemented for tts_template 2 for now
        if rollover_correction == True and hbh_json_dict['link_info']['delay'] < -10 and tts_template == 2:
            hbh_json_dict['link_info']['delay'] = hbh_json_dict['link_info']['delay'] + 66.84672

        hbh_json = json.dumps(hbh_json_dict)
        producer.produce('pt.probe.hbh', hbh_json, callback=acked) 


    # Penultimate-hop to snk link (generate message and produce)
    hbh_json_dict['link_info']['src_node_id'] = json_dict['path_info'][0]['node_id']
    hbh_json_dict['link_info']['dst_node_id'] = json_dict['snk_node']['node_id']
    hbh_json_dict['link_info']['src_interface_id'] = json_dict['path_info'][0]['out_interface_id']
    hbh_json_dict['link_info']['dst_interface_id'] = mapping[str(hbh_json_dict['link_info']['src_interface_id'])]['connected_interface']
    hbh_json_dict['link_info']['src_interface_name'] = json_dict['path_info'][0]['out_interface_name']
    hbh_json_dict['link_info']['dst_interface_name'] = mapping[str(hbh_json_dict['link_info']['dst_interface_id'])]['interface_name']
    hbh_json_dict['link_info']['link_id'] = mapping[str(hbh_json_dict['link_info']['src_interface_id'])]['linux_bridge']
    hbh_json_dict['link_info']['src_t64'] = json_dict['path_info'][0]['t64']
    hbh_json_dict['link_info']['dst_t64'] = json_dict['snk_node']['t64'] 
    hbh_json_dict['link_info']['delay'] = compute_delay(json_dict['path_info'][0]['t64'], json_dict['snk_node']['t64'])

    # Correct rollover, only implemented for tts_template 2 for now
    if rollover_correction == True and hbh_json_dict['link_info']['delay'] < -10 and tts_template == 2:
        hbh_json_dict['link_info']['delay'] = hbh_json_dict['link_info']['delay'] + 66.84672

    hbh_json = json.dumps(hbh_json_dict)
    producer.produce('pt.probe.hbh', hbh_json, callback=acked)

    # Poll producer only once at the end of the loop
    producer.poll(0)

##############################
# Main function
# TODO: implement argument parsing and -h/--help flag 
##############################
def main():
    
    # Consumer and Producer definitions                         # TODO: make kafka params as selectable input files (with default 127.0.0.1:9093)
    cons_conf = {'bootstrap.servers': "127.0.0.1:9093",
                 'group.id': "python"}                          
    consumer = Consumer(cons_conf)
    prod_conf = {'bootstrap.servers': "127.0.0.1:9093",
                 'client.id': socket.gethostname()}
    producer = Producer(prod_conf)

    # Run handler for clean stopping when CTRL-C is pressed 
    signal(SIGINT, partial(handler, producer))

    #########
    # Start topic-processing loop
    #########
    tts_template = 2                                            # TODO: make this selectable as input parameter, with default 2
    print("TTS_TEMPLATE: ", tts_template)

    rollover_correction = False                                 # TODO: make this selectable input parameter (with default: True)

    # Import static network topology mapping file
    mapping_json_file = open('network_mapping.json', 'r')       # TODO: make this as selectable input file (with default network_mapping.json)
    mapping_json = json.load(mapping_json_file)
    mapping_json_file.close()

    print("Starting topic processing loop...")
    processing_loop(consumer, producer, ['pt.probe.processed'], tts_template, mapping_json, rollover_correction)

if __name__ == "__main__":
    main()