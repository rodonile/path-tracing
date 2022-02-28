###############
# Python script that consumes the pt.ipfix.raw topic from kafka, and augment it by correlating with path-tracing per-link metric
# (querying the druid dataset) reinjects a new topic pt.ipfix.processed
# 
# Requirements:
# pip install confluent-kafka
# pip install pydruid
###############
from confluent_kafka import Consumer, KafkaError, Producer
import socket, time
from signal import signal, SIGINT
from sys import exit
import json, base64, ipaddress
from functools import partial
import pytz
import datetime
import math

from pydruid.client import *
from pydruid.query import QueryBuilder
from pydruid.utils.postaggregator import *
from pydruid.utils.aggregators import *
from pydruid.utils.filters import *
import urllib.request

tz = pytz.timezone('Etc/UTC')

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
# Consume loop for topic pt.probe.processed
##############################
def ipfix_processing_loop(consumer, producer, consume_topics, network_mapping, peer_mapping):
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
                msg_process(msg, producer, network_mapping, peer_mapping)
    finally:
        consumer.close()            # Close down consumer to commit final offsets.


##############################
# Message deserialization, processing and producing messages in topics pt.probe.global and pt.probe.hbh
##############################
def msg_process(msg, producer, network_mapping, peer_mapping):
    json_dict = json.loads(msg.value())

    # Compute missing fields and populate pt.probe.processed topic
    processed_json_dict = dict(json_dict)

    # Get ipfix sampling timestamp
    # FLOW INTERVAL ESTIMATION (required due to nfacctd not delivering the full ipfix information)
    # HINT: - flow_export-30s = flowstart for flows (active and passive timeout 30s)
    #       - we also account for 15 seconds overhead for exporting/caching/ times (pmacct refresh time set to 10s)
    #       --> our sampling interval estimation = [flow_export - 45s, flow_export + 5s] 
    #       --> in most cases we will consider packets outside the interval, but in all cases we consider all packets in the sampling interval!
    timestamp_export = int(math.floor(float(json_dict['timestamp_export'])))
    flowstart_iso = (datetime.datetime.fromtimestamp(timestamp_export, tz) - datetime.timedelta(seconds=45)).strftime("%Y-%m-%dT%H:%M:%SZ")
    flowend_iso = (datetime.datetime.fromtimestamp(timestamp_export, tz) + datetime.timedelta(seconds=5)).strftime("%Y-%m-%dT%H:%M:%SZ")
    interval = str(flowstart_iso) + "/" + str(flowend_iso)

    # Correlate to link information using static network mapping file
    if json_dict['ip_proto'] == "0":
        processed_json_dict['ip_proto'] = "ipv6-hbh"
        peer_id = peer_mapping[json_dict['peer_ip_src']]
        processed_json_dict['peer_id'] = peer_id

        checkin = False
        checkout = False
        # Correlate with network mapping and path tracing information
        for key in network_mapping.keys():    
            if network_mapping[key]['node_id'] == peer_id and network_mapping[key]['interface_idx'] == json_dict['iface_in']:
                checkin = True
                processed_json_dict['iface_in_id'] = key
                processed_json_dict['iface_in_name'] = network_mapping[key]['interface_name']
                processed_json_dict['link_in'] = network_mapping[key]['linux_bridge']
                link_in_connected_iface = str(network_mapping[key]['connected_interface'])
                processed_json_dict['link_in_connected_iface'] = link_in_connected_iface
                processed_json_dict['link_in_connected_node'] = network_mapping[link_in_connected_iface]['node_id']
                # Query average inbound link delay for ipfix sample period from druid
                query = PyDruid('http://localhost:8082', 'druid/v2')
                ts_avg = query.timeseries(
                    datasource='pt.probe.hbh',
                    granularity='all',
                    intervals=interval,
                    aggregations={'delay_sum': doublesum('link_info.delay'), 'count': count('count')},
                    post_aggregations={'delay_avg': Field('delay_sum')/Field('count')},
                    filter=Dimension('link_info.link_id') == processed_json_dict['link_in'] 
                )
                processed_json_dict['iface_in_avg_delay'] = ts_avg[0]['result']['delay_avg']
                processed_json_dict['iface_in_count_considered_for_delay'] =  ts_avg[0]['result']['count']
                # Query max inbound link delay for ipfix sample period from druid
                ts_max = query.timeseries(
                    datasource='pt.probe.hbh',
                    granularity='all',
                    intervals=interval,
                    aggregations={'delay_max': doublemax('link_info.delay')},
                    filter=Dimension('link_info.link_id') == processed_json_dict['link_in'] 
                )
                processed_json_dict['iface_in_max_delay'] = ts_max[0]['result']['delay_max']
                 # Query min inbound link delay for ipfix sample period from druid
                ts_min = query.timeseries(
                    datasource='pt.probe.hbh',
                    granularity='all',
                    intervals=interval,
                    aggregations={'delay_min': doublemin('link_info.delay')},
                    filter=Dimension('link_info.link_id') == processed_json_dict['link_in'] 
                )
                processed_json_dict['iface_in_min_delay'] = ts_min[0]['result']['delay_min']
                               


            elif network_mapping[key]['node_id'] == peer_id and network_mapping[key]['interface_idx'] == json_dict['iface_out']:
                checkout = True
                processed_json_dict['iface_out_id'] = key
                processed_json_dict['iface_out_name'] = network_mapping[key]['interface_name']
                processed_json_dict['link_out'] = network_mapping[key]['linux_bridge']
                link_out_connected_iface = str(network_mapping[key]['connected_interface'])
                processed_json_dict['link_out_connected_iface'] = link_out_connected_iface
                processed_json_dict['link_out_connected_node'] = network_mapping[link_out_connected_iface]['node_id']
                # Query average outbound link delay for ipfix sample period from druid
                # HINT: we need this for output interface as well since the last hop doesn't record ipfix for probes (probably due to srv6 encapsulation)
                query = PyDruid('http://localhost:8082', 'druid/v2')
                ts_avg = query.timeseries(
                    datasource='pt.probe.hbh',
                    granularity='all',
                    intervals=interval,
                    aggregations={'delay_sum': doublesum('link_info.delay'), 'count': count('count')},
                    post_aggregations={'delay_avg': Field('delay_sum')/Field('count')},
                    filter=Dimension('link_info.link_id') == processed_json_dict['link_out'] 
                )
                processed_json_dict['iface_out_avg_delay'] = ts_avg[0]['result']['delay_avg']
                processed_json_dict['iface_out_count_considered_for_delay'] =  ts_avg[0]['result']['count']
                # Query max outbound link delay for ipfix sample period from druid
                ts_max = query.timeseries(
                    datasource='pt.probe.hbh',
                    granularity='all',
                    intervals=interval,
                    aggregations={'delay_max': doublemax('link_info.delay')},
                    filter=Dimension('link_info.link_id') == processed_json_dict['link_out'] 
                )
                processed_json_dict['iface_out_max_delay'] = ts_max[0]['result']['delay_max']
                 # Query min outbound link delay for ipfix sample period from druid
                ts_min = query.timeseries(
                    datasource='pt.probe.hbh',
                    granularity='all',
                    intervals=interval,
                    aggregations={'delay_min': doublemin('link_info.delay')},
                    filter=Dimension('link_info.link_id') == processed_json_dict['link_out'] 
                )
                processed_json_dict['iface_out_min_delay'] = ts_min[0]['result']['delay_min']

        # Serialize and produce to pt.ipfix.processed topic
        if (checkin): # Only publish information for internal links to kafka (we have pt information only for those ones)
            processed_json = json.dumps(processed_json_dict)
            producer.produce('pt.ipfix.processed', processed_json, callback=acked)
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
    # Start ipfix-processing loop
    #########
    # Import static network topology mapping file
    network_mapping_json_file = open('network_mapping.json', 'r')       # TODO: make this as selectable input file (with default network_mapping.json)
    network_mapping_json = json.load(network_mapping_json_file)
    network_mapping_json_file.close()
    # Import ipfix peer-ip to node-id mapping file
    peer_mapping_json_file = open('peer-ip_node-id-mapping.json', 'r')       # TODO: make this as selectable input file (with default network_mapping.json)
    peer_mapping_json = json.load(peer_mapping_json_file)
    peer_mapping_json_file.close()

    print("Starting ipfix processing loop...")
    ipfix_processing_loop(consumer, producer, ['pt.ipfix.raw'], network_mapping_json, peer_mapping_json)


if __name__ == "__main__":
    main()