###############
# Python script that consumes the pt.probe.raw topic from kafka, populates the missing metrics in the json and 
# reinjects a new topic pt.probe.processed, which is ready to be consumed by a TSDB 
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

# Global variable to count max rollovers
delay_rollovers_max = 0

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
# Consume loop for topic pt.probe.raw
##############################
def preprocessing_loop(consumer, producer, consume_topics, produce_topic, tts_template, mapping):
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
                msg_process(msg, producer, produce_topic, tts_template, mapping)
    finally:
        consumer.close()            # Close down consumer to commit final offsets.


##############################
# Message deserialization, processing and producing in new topic pt.probe.processed
##############################
def msg_process(msg, producer, produce_topic, tts_template, mapping):
    #print('Received message: {}'.format(msg.value().decode('utf-8')))
    json_dict = json.loads(msg.value())
    global delay_rollovers_max

    # Compute missing fields and populate pt.probe.processed topic
    processed_json_dict = dict(json_dict)
    
    ########
    # Source and Sink
    ########
    # IPv6 source and destination addresses
    src_addr_base64 = base64.decodebytes(bytes(json_dict['src_node']['addr'], 'utf-8'))
    snk_addr_base64 = base64.decodebytes(bytes(json_dict['snk_node']['addr'], 'utf-8'))
    tef_sid_base64 = base64.decodebytes(bytes(json_dict['snk_node']['tef_sid'], 'utf-8'))
    processed_json_dict['src_node']['addr'] = str(ipaddress.IPv6Address(src_addr_base64))
    processed_json_dict['snk_node']['addr'] = str(ipaddress.IPv6Address(snk_addr_base64))
    processed_json_dict['snk_node']['tef_sid'] = str(ipaddress.IPv6Address(tef_sid_base64))

    # Populate missing information based on network topology (static mapping file)
    processed_json_dict['src_node']['node_id'] = mapping[str(json_dict['src_node']['out_interface_id'])]['node_id']
    processed_json_dict['src_node']['out_interface_name'] = mapping[str(json_dict['src_node']['out_interface_id'])]['interface_name']
    processed_json_dict['snk_node']['node_id'] = mapping[str(json_dict['snk_node']['in_interface_id'])]['node_id']
    processed_json_dict['snk_node']['in_interface_name'] = mapping[str(json_dict['snk_node']['in_interface_id'])]['interface_name']

    ########
    # Re-arrange SID-List
    ########
    sid_list = json_dict['sid_list']
    #processed_sids_json = {}
    # Choose list instead of json, better approach for turnilo that then enable possibility to filter
    processed_sids_list = []

    for i in range(0, len(sid_list)):
        bin_address = 0
        for ii in range(0, len(sid_list[i])):
            bin_address = bin_address + (sid_list[i][ii] << 8*(15-ii))
        #processed_sids_json[str(i)] = str(ipaddress.IPv6Address(bin_address))
        processed_sids_list.append(str(ipaddress.IPv6Address(bin_address)))

    processed_sids_list.reverse()   # s.t. we have the sid list in traversal order!
    processed_json_dict['sid_list'] = processed_sids_list


    ########
    # Hop-by-hop fields
    ########
    mcd_stack_base64 =  base64.decodebytes(bytes(json_dict['mcd_stack'], 'utf-8'))
    mcd_stack_hop_length = int(json_dict['hbh_opt_length'] / 3)                              # 3 bytes per hop in mcd stack
    
    # Separate mcd_stack as per-hop information and put them in a list
    mcd_stack_list = []
    midpoint_count_flag = False
    for i in range(0, mcd_stack_hop_length):
        mcd_stack_list.append(int.from_bytes(mcd_stack_base64[(0 + 3*i):(3 + 3*i)], "big"))
        if mcd_stack_list[i] == 0 and not(midpoint_count_flag):
            processed_json_dict['midpoint_count'] = i
            midpoint_count_flag = True

    
    # Sink timestamp to reconstruct delay (start from sink --> step by step backwards computation until first hop)
    temp_next_timestamp = json_dict['snk_node']['t64']
    temp_next_timestamp_s = divmod(json_dict['snk_node']['t64'],1<<32)[0]         # for now assume this won't rollover (?)
    temp_next_timestamp_ns = divmod(json_dict['snk_node']['t64'],1<<32)[1]
    # Populate path_info list with missing metrics
    for i in range(0, processed_json_dict['midpoint_count']):
        out_interface_id = mcd_stack_list[i] >> 12 & 0b111111111111                                      # bits 12 to 24
        processed_json_dict['path_info'][i]['out_interface_id'] = out_interface_id
        processed_json_dict['path_info'][i]['out_interface_load'] = mcd_stack_list[i] >> 8 & 0b1111      # bits 8 to 12

        # Reconstruct timestamp and correct rollovers
        # HINT: for now only support tts_template=2
        #       Path tracing is being extended s.t. it will support tts_template value to be saved in the HBH header and exported 
        #       TODO (future work) when this is available: check the tts_template value in json's path_info and use it to reconstruct the template

        # Reconstruct timestamp with help of next hops' timestamp
        # TEMPLATE 2: bits 18-25 (WAN link)
        reconstructed_t64_s = temp_next_timestamp_s
        truncated_t64 = mcd_stack_list[i] & 0b11111111                                                    # bits 0 to 8
        reconstructed_t64_ns = temp_next_timestamp_ns & (((2**6-1) << 8+18))
        reconstructed_t64_ns = reconstructed_t64_ns | (truncated_t64 << 18)
        reconstructed_t64 = (reconstructed_t64_s << 32) | reconstructed_t64_ns
        
        # Correct rollovers:
        # Check if timestamp is bigger than next hop's timestamp, and if the case correct rollover
        # TODO: correct better the rollover across the seconds part
        delay_rollovers = 1
        while compute_delay(reconstructed_t64, temp_next_timestamp) < 0:
            #print("DEBUG: we entered rollover correction. Round: ", delay_rollovers)
            #print("WHERE ARE WE: ", out_interface_id)
            #print("WHY DID WE ENTER? SEE TIMESTAMPS BELOW:")
            #print("Truncated T64 value: ", truncated_t64)
            #print("Reconstructed_t64s: ", reconstructed_t64_s)
            #print("Reconstructed_t64ns: ", reconstructed_t64_ns)
            #print("Reconstructed_t64: ", reconstructed_t64)
            #print("NEXT T64s: ", temp_next_timestamp_s)
            #print("NEXT T64ns: ", temp_next_timestamp_ns)
            #print("NEXT T64: ", temp_next_timestamp)
            #delay = compute_delay(reconstructed_t64, temp_next_timestamp)
            #print("DELAY: ", delay)
            
            #if reconstructed_t64_ns < (1<<26):
            #    reconstructed_t64_s = reconstructed_t64_s - 1
            #    reconstructed_t64 = (reconstructed_t64_s << 32) | reconstructed_t64_ns
            #    print("seconds rollover")
            #else:
            #    reconstructed_t64_ns = reconstructed_t64_ns - (1<<26)
            #    reconstructed_t64 = (reconstructed_t64_s << 32) | reconstructed_t64_ns
            #    print("nanoseconds rollover")

            # This is still not perfect, but still the best stable option so far:
            # TODO: need to handle in a better way seconds rollover! (see above)
            reconstructed_t64 = reconstructed_t64 - (1<<26)
            reconstructed_t64_s = divmod(reconstructed_t64,1<<32)[0] 
            reconstructed_t64_ns = divmod(reconstructed_t64,1<<32)[1] 


            # DEBUG PRINTS
            #print("After fixing rollover reconstructed t64:")
            #print("Reconstructed_t64s: ", reconstructed_t64_s)
            #print("Reconstructed_t64ns: ", reconstructed_t64_ns)
            #print("Reconstructed_t64: ", reconstructed_t64)
            #print("NEXT T64s: ", temp_next_timestamp_s)
            #print("NEXT T64ns: ", temp_next_timestamp_ns)
            #print("NEXT T64: ", temp_next_timestamp)
            #delay = compute_delay(reconstructed_t64, temp_next_timestamp)
            #print("DELAY: ", delay)
            #print("------------------\n")

            # DEBUG MAX ROLLOVERS IN TEST NETWORK
            if delay_rollovers > delay_rollovers_max:
                delay_rollovers_max = delay_rollovers
                f = open("max_delay_rollovers.log", "w")
                string_to_write = "Max rollovers: " + str(delay_rollovers)
                f.write(string_to_write)
                f.close()
            delay_rollovers = delay_rollovers + 1
            

        # Populate t64 on path_info and update next-hop timestamp
        processed_json_dict['path_info'][i]['t64'] = reconstructed_t64
        temp_next_timestamp = reconstructed_t64
        temp_next_timestamp_s = reconstructed_t64_s
        temp_next_timestamp_ns = reconstructed_t64_ns

        # Populate missing information based on network topology (static mapping file)
        processed_json_dict['path_info'][i]['node_id'] = mapping[str(out_interface_id)]['node_id']
        processed_json_dict['path_info'][i]['out_interface_name'] = mapping[str(out_interface_id)]['interface_name']

    # Serialize and produce to pt.probe.processed topic
    processed_json = json.dumps(processed_json_dict)
    producer.produce(produce_topic, processed_json, callback=acked)
    producer.poll(0)  # We need to poll otherwise producer queue might get full and cause crash



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
    # Start pre-processing loop
    #########
    tts_template = 2                                            # TODO: make this selectable as input parameter, with default 2
    print("TTS_TEMPLATE: ", tts_template)

    # Import static network topology mapping file
    mapping_json_file = open('network_mapping.json', 'r')       # TODO: make this as selectable input file (with default network_mapping.json)
    mapping_json = json.load(mapping_json_file)
    mapping_json_file.close()

    print("Starting pre-processing loop...")
    preprocessing_loop(consumer, producer, ['pt.probe.raw'], 'pt.probe.processed', tts_template, mapping_json)

if __name__ == "__main__":
    main()