##################################################
# VPP NETWORK TOPOLOGY DEPLOYMENT FOR CISCO PATH TRACING
# MASTER THESIS OF LEONARDO RODONI (ETHZ) IN COLLABORATION WITH SWISSCOM (SWISS ISP)
# 
# This script automates the deployment of a virtual network topology in a linux server
# It is configured to export path-tracing probes to a collector binary and export IPFIX metrics to pmacct
# 
# Further information on how to deploy the visualization pipeline can be found at https://github.com/rodonile/path-tracing
#
# REQUIREMENTS: 
# - Ubuntu 20.04 server with at least 8 cores (each vpp instance is bound to a single core)
# - vpp-21.06_versionXXXX with path-tracing patch versionXXX
# - apt packages: bridge-utils, net-tools
# - snap packages: jo (version 1.6)
##################################################

##################################################
# Start vpp instances
##################################################
sudo vpp api-segment { prefix vpp1 } socksvr { socket-name /run/vpp/api-vpp1.sock } cpu {main-core 16} unix { cli-listen /run/vpp/cli.vpp1.sock  cli-prompt vpp1# startup-config /etc/vpp/vpp1.conf} plugins { plugin dpdk_plugin.so { disable }
sudo vpp api-segment { prefix vpp2 } socksvr { socket-name /run/vpp/api-vpp2.sock } cpu {main-core 17} unix { cli-listen /run/vpp/cli.vpp2.sock  cli-prompt vpp2# startup-config /etc/vpp/vpp2.conf} plugins { plugin dpdk_plugin.so { disable }
sudo vpp api-segment { prefix vpp3 } socksvr { socket-name /run/vpp/api-vpp3.sock } cpu {main-core 18} unix { cli-listen /run/vpp/cli.vpp3.sock  cli-prompt vpp3# startup-config /etc/vpp/vpp3.conf} plugins { plugin dpdk_plugin.so { disable }
sudo vpp api-segment { prefix vpp4 } socksvr { socket-name /run/vpp/api-vpp4.sock } cpu {main-core 19} unix { cli-listen /run/vpp/cli.vpp4.sock  cli-prompt vpp4# startup-config /etc/vpp/vpp4.conf} plugins { plugin dpdk_plugin.so { disable }
sudo vpp api-segment { prefix vpp5 } socksvr { socket-name /run/vpp/api-vpp5.sock } cpu {main-core 20} unix { cli-listen /run/vpp/cli.vpp5.sock  cli-prompt vpp5# startup-config /etc/vpp/vpp5.conf} plugins { plugin dpdk_plugin.so { disable }
sudo vpp api-segment { prefix vpp6 } socksvr { socket-name /run/vpp/api-vpp6.sock } cpu {main-core 21} unix { cli-listen /run/vpp/cli.vpp6.sock  cli-prompt vpp6# startup-config /etc/vpp/vpp6.conf} plugins { plugin dpdk_plugin.so { disable }
sudo vpp api-segment { prefix vpp7 } socksvr { socket-name /run/vpp/api-vpp7.sock } cpu {main-core 22} unix { cli-listen /run/vpp/cli.vpp7.sock  cli-prompt vpp7# startup-config /etc/vpp/vpp7.conf} plugins { plugin dpdk_plugin.so { disable }
sudo vpp api-segment { prefix vpp8 } socksvr { socket-name /run/vpp/api-vpp8.sock } cpu {main-core 23} unix { cli-listen /run/vpp/cli.vpp8.sock  cli-prompt vpp8# startup-config /etc/vpp/vpp8.conf} plugins { plugin dpdk_plugin.so { disable }
sudo sleep 5

# Parameters for path-tracing
TTS_TEMPLATE_VALUE=2
echo "TTS_TEMPLATE: ${TTS_TEMPLATE_VALUE}"

# Parameters for network topology
# TOPOLOGY MAPPING JSON OBJECT
TOPOLOGY_JSON_FILE="network_mapping.json"
[ -e ${TOPOLOGY_JSON_FILE} ] && truncate -s 0 ${TOPOLOGY_JSON_FILE}
touch ${TOPOLOGY_JSON_FILE}

# DELAY
# Core links
br23_delay='1ms'
br24_delay='1ms'
br45_delay='1ms'
br35_delay='1ms'
br25_delay='2ms'
br34_delay='2ms'
# Core-PE links
br12_delay='3ms'
br13_delay='3ms'
br26_delay='3ms'
br46_delay='3ms'
br48_delay='3ms'
br58_delay='3ms'
br37_delay='3ms'
br57_delay='3ms'

##################################################
# Create virtual network (linux veth and bridges)
##################################################
# Virtual links (bridges)
sudo brctl addbr br23
sudo brctl addbr br24
sudo brctl addbr br45
sudo brctl addbr br35
sudo brctl addbr br25
sudo brctl addbr br34
sudo brctl addbr br12
sudo brctl addbr br13
sudo brctl addbr br26
sudo brctl addbr br46
sudo brctl addbr br48
sudo brctl addbr br58
sudo brctl addbr br37
sudo brctl addbr br57
sudo brctl addbr brcollector
sudo brctl addbr bripfix

# Bring up all bridges
sudo ifconfig br23 up
sudo ifconfig br24 up
sudo ifconfig br45 up
sudo ifconfig br35 up
sudo ifconfig br25 up
sudo ifconfig br34 up
sudo ifconfig br12 up
sudo ifconfig br13 up
sudo ifconfig br26 up
sudo ifconfig br46 up
sudo ifconfig br48 up
sudo ifconfig br58 up
sudo ifconfig br37 up
sudo ifconfig br57 up
sudo ifconfig brcollector up
sudo ifconfig bripfix up

# Create veth pairs between probe generator and vpp 
sudo ip link add linux1 type veth peer name vpp1
sudo ip link add linux6 type veth peer name vpp6
sudo ip link add linux7 type veth peer name vpp7
sudo ip link add linux8 type veth peer name vpp8

# Create veth pair between PE nodes (vpp1, vpp6, vpp7 and vpp8) and collector 
sudo ip link add veth0 type veth peer name collector
sudo ip link add veth1 type veth peer name ext-vpp1
sudo ip link add veth6 type veth peer name ext-vpp6
sudo ip link add veth7 type veth peer name ext-vpp7
sudo ip link add veth8 type veth peer name ext-vpp8
# Connect bridge with PE nodes to collector
sudo brctl addif brcollector veth0 veth1 veth6 veth7 veth8
# Configure probe collector ip address
sudo ip -6 address add 2001:db8:c:e::c/64 dev collector

# Create veth pair between all nodes and ipfix-collector
sudo ip link add veth1-ipfix type veth peer name ipfix-vpp1
sudo ip link add veth2-ipfix type veth peer name ipfix-vpp2
sudo ip link add veth3-ipfix type veth peer name ipfix-vpp3
sudo ip link add veth4-ipfix type veth peer name ipfix-vpp4
sudo ip link add veth5-ipfix type veth peer name ipfix-vpp5
sudo ip link add veth6-ipfix type veth peer name ipfix-vpp6
sudo ip link add veth7-ipfix type veth peer name ipfix-vpp7
sudo ip link add veth8-ipfix type veth peer name ipfix-vpp8
# Connect bridge with PE nodes to ipfix collector
sudo brctl addif bripfix veth1-ipfix veth2-ipfix veth3-ipfix veth4-ipfix veth5-ipfix veth6-ipfix veth7-ipfix veth8-ipfix
# Configure ipfix collector ip address
sudo ip address add 192.168.0.100/24 dev bripfix        # Configure to bridge otherwise issues in linux networking arise...

# Bring up all veth
sudo ifconfig linux1 up
sudo ifconfig linux6 up
sudo ifconfig linux7 up
sudo ifconfig linux8 up
sudo ifconfig vpp1 up
sudo ifconfig vpp6 up
sudo ifconfig vpp7 up
sudo ifconfig vpp8 up
sudo ifconfig veth0 up
sudo ifconfig veth1 up
sudo ifconfig veth6 up
sudo ifconfig veth7 up
sudo ifconfig veth8 up
sudo ifconfig collector up
sudo ifconfig ext-vpp1 up
sudo ifconfig ext-vpp6 up
sudo ifconfig ext-vpp7 up
sudo ifconfig ext-vpp8 up
sudo ifconfig veth1-ipfix up
sudo ifconfig veth2-ipfix up
sudo ifconfig veth3-ipfix up
sudo ifconfig veth4-ipfix up
sudo ifconfig veth5-ipfix up
sudo ifconfig veth6-ipfix up
sudo ifconfig veth7-ipfix up
sudo ifconfig veth8-ipfix up
sudo ifconfig ipfix-vpp1 up
sudo ifconfig ipfix-vpp2 up
sudo ifconfig ipfix-vpp3 up
sudo ifconfig ipfix-vpp4 up
sudo ifconfig ipfix-vpp5 up
sudo ifconfig ipfix-vpp6 up
sudo ifconfig ipfix-vpp7 up
sudo ifconfig ipfix-vpp8 up

########
# Ping/Iperf3 clients
########

# Connect vpp1, vpp6, vpp7, and vpp8 to host client interfaces (for generating startup ping traffic and iperf3 tests)
sudo ip link add host-1 type veth peer name client-vpp1
sudo ip link add host-6 type veth peer name client-vpp6
sudo ip link add host-7 type veth peer name client-vpp7
sudo ip link add host-8 type veth peer name client-vpp8

# Bring up all veths
sudo ifconfig host-1 up
sudo ifconfig host-6 up
sudo ifconfig host-7 up
sudo ifconfig host-8 up
sudo ifconfig client-vpp1 up
sudo ifconfig client-vpp6 up
sudo ifconfig client-vpp7 up
sudo ifconfig client-vpp8 up

# Create host-1, host-6, host-7, host-8 (in separate network namespaces)
# Setup routes to ping all vpp loopbacks and the other host respectively
sudo ip netns add ns-host-1
sudo ip link set host-1 netns ns-host-1                                                                 # move interface host-1 to new namespace
sudo ip netns exec ns-host-1 ip link set host-1 up
sudo ip netns exec ns-host-1 ip -6 address add 2001:db8:a:1::a/64 dev host-1                            #host-1 interface address
sudo ip netns exec ns-host-1 ip -6 address add fcbb:aa00:1::a/48 dev host-1                             #host-1 "loopback" address
sudo ip netns exec ns-host-1 ip -6 route add fcbb:bb00::/32 via 2001:db8:a:1::1 dev host-1  metric 1    #route to reach internal vpp-network loopbacks
sudo ip netns exec ns-host-1 ip -6 route add fcbb:aa00:6::/48 via 2001:db8:a:1::1 dev host-1 metric 1   #route to reach host-6 from host-1 via vpp network
sudo ip netns exec ns-host-1 ip -6 route add fcbb:aa00:7::/48 via 2001:db8:a:1::1 dev host-1 metric 1   #route to reach host-7 from host-1 via vpp network
sudo ip netns exec ns-host-1 ip -6 route add fcbb:aa00:8::/48 via 2001:db8:a:1::1 dev host-1 metric 1   #route to reach host-8 from host-1 via vpp network

sudo ip netns add ns-host-6
sudo ip link set host-6 netns ns-host-6                                                                 # move interface host-6 to new namespace
sudo ip netns exec ns-host-6 ip link set host-6 up
sudo ip netns exec ns-host-6 ip -6 address add 2001:db8:a:6::a/64 dev host-6                            #host-6 interface address
sudo ip netns exec ns-host-6 ip -6 address add fcbb:aa00:6::a/48 dev host-6                             #host-6 "loopback" address
sudo ip netns exec ns-host-6 ip -6 route add fcbb:bb00::/32 via 2001:db8:a:6::6 dev host-6  metric 1    #route to reach internal vpp-network loopbacks
sudo ip netns exec ns-host-6 ip -6 route add fcbb:aa00:1::/48 via 2001:db8:a:6::6 dev host-6 metric 1   #route to reach host-1 from host-6 via vpp network
sudo ip netns exec ns-host-6 ip -6 route add fcbb:aa00:7::/48 via 2001:db8:a:6::6 dev host-6 metric 1   #route to reach host-7 from host-6 via vpp network
sudo ip netns exec ns-host-6 ip -6 route add fcbb:aa00:8::/48 via 2001:db8:a:6::6 dev host-6 metric 1   #route to reach host-8 from host-6 via vpp network

sudo ip netns add ns-host-7
sudo ip link set host-7 netns ns-host-7                                                                 # move interface host-7 to new namespace
sudo ip netns exec ns-host-7 ip link set host-7 up
sudo ip netns exec ns-host-7 ip -6 address add 2001:db8:a:7::a/64 dev host-7                            #host-7 interface address
sudo ip netns exec ns-host-7 ip -6 address add fcbb:aa00:7::a/48 dev host-7                             #host-7 "loopback" address
sudo ip netns exec ns-host-7 ip -6 route add fcbb:bb00::/32 via 2001:db8:a:7::7 dev host-7  metric 1    #route to reach internal vpp-network loopbacks
sudo ip netns exec ns-host-7 ip -6 route add fcbb:aa00:1::/48 via 2001:db8:a:7::7 dev host-7 metric 1   #route to reach host-1 from host-7 via vpp network
sudo ip netns exec ns-host-7 ip -6 route add fcbb:aa00:6::/48 via 2001:db8:a:7::7 dev host-7 metric 1   #route to reach host-6 from host-7 via vpp network
sudo ip netns exec ns-host-7 ip -6 route add fcbb:aa00:8::/48 via 2001:db8:a:7::7 dev host-7 metric 1   #route to reach host-8 from host-7 via vpp network

sudo ip netns add ns-host-8
sudo ip link set host-8 netns ns-host-8                                                                 # move interface host-8 to new namespace
sudo ip netns exec ns-host-8 ip link set host-8 up
sudo ip netns exec ns-host-8 ip -6 address add 2001:db8:a:8::a/64 dev host-8                            #host-8 interface address
sudo ip netns exec ns-host-8 ip -6 address add fcbb:aa00:8::a/48 dev host-8                             #host-8 "loopback" address
sudo ip netns exec ns-host-8 ip -6 route add fcbb:bb00::/32 via 2001:db8:a:8::8 dev host-8  metric 1    #route to reach internal vpp-network loopbacks
sudo ip netns exec ns-host-8 ip -6 route add fcbb:aa00:1::/48 via 2001:db8:a:8::8 dev host-8 metric 1   #route to reach host-1 from host-8 via vpp network
sudo ip netns exec ns-host-8 ip -6 route add fcbb:aa00:6::/48 via 2001:db8:a:8::8 dev host-8 metric 1   #route to reach host-6 from host-8 via vpp network
sudo ip netns exec ns-host-8 ip -6 route add fcbb:aa00:7::/48 via 2001:db8:a:8::8 dev host-8 metric 1   #route to reach host-7 from host-8 via vpp network

#########################
# VPP 1
#########################
# Interfaces
sudo vppctl -s /run/vpp/cli.vpp1.sock loopback create-interface                                         # Loopback interface
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface state loop0 up
sudo vppctl -s /run/vpp/cli.vpp1.sock enable ip6 interface loop0
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface ip address loop0 fcbb:bb00:1::1/128

sudo vppctl -s /run/vpp/cli.vpp1.sock create tap id 10 host-bridge br13                                 # (vpp1) tap10 <-------> (vpp3) tap32
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface state tap10 up
sudo vppctl -s /run/vpp/cli.vpp1.sock enable ip6 interface tap10
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface ip address tap10 2001:db8:1:3::1/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 10["node_id"]="vpp1" 10["interface_name"]="tap10" 10["interface_idx"]=2 \
                                       10["linux_bridge"]="br13" 10["connected_interface"]=32 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp1.sock create tap id 11 host-bridge br12                                 # (vpp1) tap11 <-------> (vpp2) tap20
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface state tap11 up
sudo vppctl -s /run/vpp/cli.vpp1.sock enable ip6 interface tap11
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface ip address tap11 2001:db8:1:2::1/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 11["node_id"]="vpp1" 11["interface_name"]="tap11" 11["interface_idx"]=3 \
                                       11["linux_bridge"]="br12" 11["connected_interface"]=20 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp1.sock create host-interface name vpp1                                   # (vpp1) host-vpp1 <-------> (linux) linux1
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface state host-vpp1 up                                  # used by probe-generator binary
sudo vppctl -s /run/vpp/cli.vpp1.sock enable ip6 interface host-vpp1 
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface ip address host-vpp1 2001:db8:1:a::1/64

sudo vppctl -s /run/vpp/cli.vpp1.sock create host-interface name ext-vpp1                               # (vpp1) host-ext-vpp1 <-----> (linux) veth1
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface state host-ext-vpp1 up                              # connecting vpp1 to probe collector
sudo vppctl -s /run/vpp/cli.vpp1.sock enable ip6 interface host-ext-vpp1 
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface ip address host-ext-vpp1 2001:db8:c:e::1/64

sudo vppctl -s /run/vpp/cli.vpp1.sock create host-interface name client-vpp1                            # (linux) host-1 <-----> (vpp1) host-client-vpp1
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface state host-client-vpp1 up                           # --> used to generate and push test traffic (e.g. ping, iperf3) into the network
sudo vppctl -s /run/vpp/cli.vpp1.sock enable ip6 interface host-client-vpp1
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface ip address host-client-vpp1 2001:db8:a:1::1/64

sudo vppctl -s /run/vpp/cli.vpp1.sock create host-interface name ipfix-vpp1                               # (vpp1) host-ipfix-vpp1 <-----> (linux) veth1-ipfix
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface state host-ipfix-vpp1 up                              # connecting vpp1 to ipfix collector
sudo vppctl -s /run/vpp/cli.vpp1.sock set interface ip address host-ipfix-vpp1 192.168.0.1/24

sudo sleep 1
# Static Routing
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:3::/48 via 2001:db8:1:3::3
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:2::/48 via 2001:db8:1:2::2
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:4::/48 via 2001:db8:1:3::3
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:4::/48 via 2001:db8:1:2::2
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:5::/48 via 2001:db8:1:3::3
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:5::/48 via 2001:db8:1:2::2
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:6::/48 via 2001:db8:1:2::2
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:7::/48 via 2001:db8:1:3::3
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:8::/48 via 2001:db8:1:3::3
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:bb00:8::/48 via 2001:db8:1:2::2
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:aa00:1::/48 via 2001:db8:a:1::a
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:aa00:6::/48 via 2001:db8:1:2::2
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:aa00:7::/48 via 2001:db8:1:3::3
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:aa00:8::/48 via 2001:db8:1:2::2
sudo vppctl -s /run/vpp/cli.vpp1.sock ip route add fcbb:aa00:8::/48 via 2001:db8:1:3::3

# Path Tracing Configuration 
sudo vppctl -s /run/vpp/cli.vpp1.sock pt iface add iface tap10 id 10 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp1.sock pt iface add iface tap11 id 11 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp1.sock pt probe-inject-iface add iface host-vpp1 

# SRv6 Configuration
sudo vppctl -s /run/vpp/cli.vpp1.sock set sr encaps source addr 2001:db8:c:e::1
sudo vppctl -s /run/vpp/cli.vpp1.sock sr localsid prefix fcbb:bb00:1::/48 behavior un 16
sudo vppctl -s /run/vpp/cli.vpp1.sock sr localsid address fcbb:bb00:1::100 behavior end

# SRv6 Policies
sudo vppctl -s /run/vpp/cli.vpp1.sock sr policy add bsid fcbb:bb00:0001:f0ef:: next 2001:db8:c:e::c encap tef       # Steer pt probes towards collector

#########################
# VPP 2
#########################
# Interfaces
sudo vppctl -s /run/vpp/cli.vpp2.sock loopback create-interface
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface state loop0 up
sudo vppctl -s /run/vpp/cli.vpp2.sock enable ip6 interface loop0
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface ip address loop0 fcbb:bb00:2::1/128

sudo vppctl -s /run/vpp/cli.vpp2.sock create tap id 20 host-bridge br12
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface state tap20 up
sudo vppctl -s /run/vpp/cli.vpp2.sock enable ip6 interface tap20
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface ip address tap20 2001:db8:1:2::2/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 20["node_id"]="vpp2" 20["interface_name"]="tap20" 20["interface_idx"]=2 \
                                       20["linux_bridge"]="br12" 20["connected_interface"]=11 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp2.sock create tap id 21 host-bridge br25 
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface state tap21 up
sudo vppctl -s /run/vpp/cli.vpp2.sock enable ip6 interface tap21
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface ip address tap21 2001:db8:2:5::2/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 21["node_id"]="vpp2" 21["interface_name"]="tap21" 21["interface_idx"]=3 \
                                       21["linux_bridge"]="br25" 21["connected_interface"]=53 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp2.sock create tap id 22 host-bridge br24
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface state tap22 up
sudo vppctl -s /run/vpp/cli.vpp2.sock enable ip6 interface tap22
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface ip address tap22 2001:db8:2:4::2/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 22["node_id"]="vpp2" 22["interface_name"]="tap22" 22["interface_idx"]=4 \
                                       22["linux_bridge"]="br24" 22["connected_interface"]=40 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp2.sock create tap id 23 host-bridge br26
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface state tap23 up
sudo vppctl -s /run/vpp/cli.vpp2.sock enable ip6 interface tap23
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface ip address tap23 2001:db8:2:6::2/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 23["node_id"]="vpp2" 23["interface_name"]="tap23" 23["interface_idx"]=5 \
                                       23["linux_bridge"]="br26" 23["connected_interface"]=60 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json
                                       
sudo vppctl -s /run/vpp/cli.vpp2.sock create tap id 24 host-bridge br23
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface state tap24 up
sudo vppctl -s /run/vpp/cli.vpp2.sock enable ip6 interface tap24
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface ip address tap24 2001:db8:2:3::2/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 24["node_id"]="vpp2" 24["interface_name"]="tap24" 24["interface_idx"]=6 \
                                       24["linux_bridge"]="br23" 24["connected_interface"]=33 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp2.sock create host-interface name ipfix-vpp2                               # (vpp2) host-ipfix-vpp2 <-----> (linux) veth2-ipfix
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface state host-ipfix-vpp2 up                              # connecting vpp2 to ipfix collector
sudo vppctl -s /run/vpp/cli.vpp2.sock set interface ip address host-ipfix-vpp2 192.168.0.2/24

sudo sleep 1
# Static Routing
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:1::/48 via 2001:db8:1:2::1
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:4::/48 via 2001:db8:2:4::4
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:5::/48 via 2001:db8:2:5::5
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:3::/48 via 2001:db8:2:3::3
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:6::/48 via 2001:db8:2:6::6
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:7::/48 via 2001:db8:2:3::3
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:7::/48 via 2001:db8:2:5::5
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:8::/48 via 2001:db8:2:4::4
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:bb00:8::/48 via 2001:db8:2:5::5
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:aa00:1::/48 via 2001:db8:1:2::1
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:aa00:6::/48 via 2001:db8:2:6::6
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:aa00:7::/48 via 2001:db8:2:3::3
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:aa00:7::/48 via 2001:db8:2:5::5
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:aa00:8::/48 via 2001:db8:2:4::4
sudo vppctl -s /run/vpp/cli.vpp2.sock ip route add fcbb:aa00:8::/48 via 2001:db8:2:5::5

# Path Tracing Configuration
sudo vppctl -s /run/vpp/cli.vpp2.sock pt iface add iface tap20 id 20 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp2.sock pt iface add iface tap21 id 21 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp2.sock pt iface add iface tap22 id 22 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp2.sock pt iface add iface tap23 id 23 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp2.sock pt iface add iface tap24 id 24 tts-template ${TTS_TEMPLATE_VALUE}

# SRv6 Configuration
sudo vppctl -s /run/vpp/cli.vpp2.sock set sr encaps source addr fcbb:bb00:2::1
sudo vppctl -s /run/vpp/cli.vpp2.sock sr localsid prefix fcbb:bb00:2::/48 behavior un 16
sudo vppctl -s /run/vpp/cli.vpp2.sock sr localsid address fcbb:bb00:2::100 behavior end


#########################
# VPP 3
#########################
# Interfaces
sudo vppctl -s /run/vpp/cli.vpp3.sock loopback create-interface
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface state loop0 up
sudo vppctl -s /run/vpp/cli.vpp3.sock enable ip6 interface loop0
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface ip address loop0 fcbb:bb00:3::1/128

sudo vppctl -s /run/vpp/cli.vpp3.sock create tap id 30 host-bridge br35
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface state tap30 up
sudo vppctl -s /run/vpp/cli.vpp3.sock enable ip6 interface tap30
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface ip address tap30 2001:db8:3:5::3/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 30["node_id"]="vpp3" 30["interface_name"]="tap30" 30["interface_idx"]=2 \
                                       30["linux_bridge"]="br35" 30["connected_interface"]=50 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp3.sock create tap id 31 host-bridge br34 
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface state tap31 up
sudo vppctl -s /run/vpp/cli.vpp3.sock enable ip6 interface tap31
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface ip address tap31 2001:db8:3:4::3/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 31["node_id"]="vpp3" 31["interface_name"]="tap31" 31["interface_idx"]=3 \
                                       31["linux_bridge"]="br34" 31["connected_interface"]=41 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp3.sock create tap id 32 host-bridge br13
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface state tap32 up
sudo vppctl -s /run/vpp/cli.vpp3.sock enable ip6 interface tap32
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface ip address tap32 2001:db8:1:3::3/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 32["node_id"]="vpp3" 32["interface_name"]="tap32" 32["interface_idx"]=4 \
                                       32["linux_bridge"]="br13" 32["connected_interface"]=10 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp3.sock create tap id 33 host-bridge br23
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface state tap33 up
sudo vppctl -s /run/vpp/cli.vpp3.sock enable ip6 interface tap33
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface ip address tap33 2001:db8:2:3::3/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 33["node_id"]="vpp3" 33["interface_name"]="tap33" 33["interface_idx"]=5 \
                                       33["linux_bridge"]="br23" 33["connected_interface"]=24 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp3.sock create tap id 34 host-bridge br37
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface state tap34 up
sudo vppctl -s /run/vpp/cli.vpp3.sock enable ip6 interface tap34
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface ip address tap34 2001:db8:3:7::3/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 34["node_id"]="vpp3" 34["interface_name"]="tap34" 34["interface_idx"]=6 \
                                       34["linux_bridge"]="br37" 34["connected_interface"]=70 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp3.sock create host-interface name ipfix-vpp3                               # (vpp3) host-ipfix-vpp3 <-----> (linux) veth3-ipfix
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface state host-ipfix-vpp3 up                              # connecting vpp3 to ipfix collector
sudo vppctl -s /run/vpp/cli.vpp3.sock set interface ip address host-ipfix-vpp3 192.168.0.3/24

sudo sleep 1
# Static Routing
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:1::/48 via 2001:db8:1:3::1
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:4::/48 via 2001:db8:3:4::4
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:5::/48 via 2001:db8:3:5::5
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:2::/48 via 2001:db8:2:3::2
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:6::/48 via 2001:db8:2:3::2
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:6::/48 via 2001:db8:3:4::4
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:7::/48 via 2001:db8:3:7::7
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:8::/48 via 2001:db8:3:4::4
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:bb00:8::/48 via 2001:db8:3:5::5
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:aa00:1::/48 via 2001:db8:1:3::1
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:aa00:6::/48 via 2001:db8:2:3::2
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:aa00:6::/48 via 2001:db8:3:4::4
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:aa00:7::/48 via 2001:db8:3:7::7
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:aa00:8::/48 via 2001:db8:3:4::4
sudo vppctl -s /run/vpp/cli.vpp3.sock ip route add fcbb:aa00:8::/48 via 2001:db8:3:5::5


# Path Tracing Configuration
sudo vppctl -s /run/vpp/cli.vpp3.sock pt iface add iface tap30 id 30 tts-template ${TTS_TEMPLATE_VALUE} 
sudo vppctl -s /run/vpp/cli.vpp3.sock pt iface add iface tap31 id 31 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp3.sock pt iface add iface tap32 id 32 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp3.sock pt iface add iface tap33 id 33 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp3.sock pt iface add iface tap34 id 34 tts-template ${TTS_TEMPLATE_VALUE}

# SRv6 Configuration
sudo vppctl -s /run/vpp/cli.vpp3.sock set sr encaps source addr fcbb:bb00:3::1
sudo vppctl -s /run/vpp/cli.vpp3.sock sr localsid prefix fcbb:bb00:3::/48 behavior un 16
sudo vppctl -s /run/vpp/cli.vpp3.sock sr localsid address fcbb:bb00:3::100 behavior end

#########################
# VPP 4
#########################
# Interfaces
sudo vppctl -s /run/vpp/cli.vpp4.sock loopback create-interface
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface state loop0 up
sudo vppctl -s /run/vpp/cli.vpp4.sock enable ip6 interface loop0
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface ip address loop0 fcbb:bb00:4::1/128

sudo vppctl -s /run/vpp/cli.vpp4.sock create tap id 40 host-bridge br24
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface state tap40 up
sudo vppctl -s /run/vpp/cli.vpp4.sock enable ip6 interface tap40
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface ip address tap40 2001:db8:2:4::4/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 40["node_id"]="vpp4" 40["interface_name"]="tap40" 40["interface_idx"]=2 \
                                       40["linux_bridge"]="br24" 40["connected_interface"]=22 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp4.sock create tap id 41 host-bridge br34
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface state tap41 up
sudo vppctl -s /run/vpp/cli.vpp4.sock enable ip6 interface tap41
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface ip address tap41 2001:db8:3:4::4/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 41["node_id"]="vpp4" 41["interface_name"]="tap41" 41["interface_idx"]=3 \
                                       41["linux_bridge"]="br34" 41["connected_interface"]=31 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp4.sock create tap id 42 host-bridge br45
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface state tap42 up
sudo vppctl -s /run/vpp/cli.vpp4.sock enable ip6 interface tap42
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface ip address tap42 2001:db8:4:5::4/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 42["node_id"]="vpp4" 42["interface_name"]="tap42" 42["interface_idx"]=4 \
                                       42["linux_bridge"]="br45" 42["connected_interface"]=54 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp4.sock create tap id 43 host-bridge br46
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface state tap43 up
sudo vppctl -s /run/vpp/cli.vpp4.sock enable ip6 interface tap43
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface ip address tap43 2001:db8:4:6::4/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 43["node_id"]="vpp4" 43["interface_name"]="tap43" 43["interface_idx"]=5 \
                                       43["linux_bridge"]="br46" 43["connected_interface"]=61 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp4.sock create tap id 44 host-bridge br48
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface state tap44 up
sudo vppctl -s /run/vpp/cli.vpp4.sock enable ip6 interface tap44
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface ip address tap44 2001:db8:4:8::4/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 44["node_id"]="vpp4" 44["interface_name"]="tap44" 44["interface_idx"]=6 \
                                       44["linux_bridge"]="br48" 44["connected_interface"]=80 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp4.sock create host-interface name ipfix-vpp4                               # (vpp4) host-ipfix-vpp4 <-----> (linux) veth4-ipfix
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface state host-ipfix-vpp4 up                              # connecting vpp4 to ipfix collector
sudo vppctl -s /run/vpp/cli.vpp4.sock set interface ip address host-ipfix-vpp4 192.168.0.4/24

sudo sleep 1
# Static Routing
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:2::/48 via 2001:db8:2:4::2
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:3::/48 via 2001:db8:3:4::3
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:5::/48 via 2001:db8:4:5::5
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:6::/48 via 2001:db8:4:6::6
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:7::/48 via 2001:db8:4:5::5
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:7::/48 via 2001:db8:3:4::3
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:1::/48 via 2001:db8:2:4::2
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:1::/48 via 2001:db8:3:4::3
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:bb00:8::/48 via 2001:db8:4:8::8
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:aa00:1::/48 via 2001:db8:2:4::2
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:aa00:1::/48 via 2001:db8:3:4::3
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:aa00:6::/48 via 2001:db8:4:6::6
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:aa00:7::/48 via 2001:db8:4:5::5
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:aa00:7::/48 via 2001:db8:3:4::3
sudo vppctl -s /run/vpp/cli.vpp4.sock ip route add fcbb:aa00:8::/48 via 2001:db8:4:8::8

# Path Tracing Configuration 
sudo vppctl -s /run/vpp/cli.vpp4.sock pt iface add iface tap40 id 40 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp4.sock pt iface add iface tap41 id 41 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp4.sock pt iface add iface tap42 id 42 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp4.sock pt iface add iface tap43 id 43 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp4.sock pt iface add iface tap44 id 44 tts-template ${TTS_TEMPLATE_VALUE}

# SRv6 Configuration
sudo vppctl -s /run/vpp/cli.vpp4.sock set sr encaps source addr fcbb:bb00:4::1
sudo vppctl -s /run/vpp/cli.vpp4.sock sr localsid prefix fcbb:bb00:4::/48 behavior un 16
sudo vppctl -s /run/vpp/cli.vpp4.sock sr localsid address fcbb:bb00:4::100 behavior end

#########################
# VPP 5
#########################
# Interfaces
sudo vppctl -s /run/vpp/cli.vpp5.sock loopback create-interface
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface state loop0 up
sudo vppctl -s /run/vpp/cli.vpp5.sock enable ip6 interface loop0
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface ip address loop0 fcbb:bb00:5::1/128

sudo vppctl -s /run/vpp/cli.vpp5.sock create tap id 50 host-bridge br35
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface state tap50 up
sudo vppctl -s /run/vpp/cli.vpp5.sock enable ip6 interface tap50
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface ip address tap50 2001:db8:3:5::5/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 50["node_id"]="vpp5" 50["interface_name"]="tap50" 50["interface_idx"]=2 \
                                       50["linux_bridge"]="br35" 50["connected_interface"]=30 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp5.sock create tap id 51 host-bridge br57
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface state tap51 up
sudo vppctl -s /run/vpp/cli.vpp5.sock enable ip6 interface tap51
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface ip address tap51 2001:db8:5:7::5/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 51["node_id"]="vpp5" 51["interface_name"]="tap51" 51["interface_idx"]=3 \
                                       51["linux_bridge"]="br57" 51["connected_interface"]=71 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp5.sock create tap id 52 host-bridge br58
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface state tap52 up
sudo vppctl -s /run/vpp/cli.vpp5.sock enable ip6 interface tap52
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface ip address tap52 2001:db8:5:8::5/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 52["node_id"]="vpp5" 52["interface_name"]="tap52" 52["interface_idx"]=4 \
                                       52["linux_bridge"]="br58" 52["connected_interface"]=81 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp5.sock create tap id 53 host-bridge br25
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface state tap53 up
sudo vppctl -s /run/vpp/cli.vpp5.sock enable ip6 interface tap53
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface ip address tap53 2001:db8:2:5::5/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 53["node_id"]="vpp5" 53["interface_name"]="tap53" 53["interface_idx"]=5 \
                                       53["linux_bridge"]="br25" 53["connected_interface"]=21 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp5.sock create tap id 54 host-bridge br45
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface state tap54 up
sudo vppctl -s /run/vpp/cli.vpp5.sock enable ip6 interface tap54
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface ip address tap54 2001:db8:4:5::5/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 54["node_id"]="vpp5" 54["interface_name"]="tap54" 54["interface_idx"]=6 \
                                       54["linux_bridge"]="br45" 54["connected_interface"]=42 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp5.sock create host-interface name ipfix-vpp5                               # (vpp5) host-ipfix-vpp5 <-----> (linux) veth5-ipfix
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface state host-ipfix-vpp5 up                              # connecting vpp5 to ipfix collector
sudo vppctl -s /run/vpp/cli.vpp5.sock set interface ip address host-ipfix-vpp5 192.168.0.5/24

sudo sleep 1
# Static Routing
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:2::/48 via 2001:db8:2:5::2
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:3::/48 via 2001:db8:3:5::3
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:6::/48 via 2001:db8:4:5::4
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:6::/48 via 2001:db8:2:5::2
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:7::/48 via 2001:db8:5:7::7
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:1::/48 via 2001:db8:3:5::3
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:1::/48 via 2001:db8:2:5::2
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:8::/48 via 2001:db8:5:8::8
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:bb00:4::/48 via 2001:db8:4:5::4
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:aa00:1::/48 via 2001:db8:3:5::3
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:aa00:1::/48 via 2001:db8:2:5::2
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:aa00:6::/48 via 2001:db8:4:5::4
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:aa00:6::/48 via 2001:db8:2:5::2
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:aa00:7::/48 via 2001:db8:5:7::7
sudo vppctl -s /run/vpp/cli.vpp5.sock ip route add fcbb:aa00:8::/48 via 2001:db8:5:8::8

# Path Tracing Configuration 
sudo vppctl -s /run/vpp/cli.vpp5.sock pt iface add iface tap50 id 50 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp5.sock pt iface add iface tap51 id 51 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp5.sock pt iface add iface tap52 id 52 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp5.sock pt iface add iface tap53 id 53 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp5.sock pt iface add iface tap54 id 54 tts-template ${TTS_TEMPLATE_VALUE}

# SRv6 Configuration
sudo vppctl -s /run/vpp/cli.vpp5.sock set sr encaps source addr fcbb:bb00:5::1
sudo vppctl -s /run/vpp/cli.vpp5.sock sr localsid prefix fcbb:bb00:5::/48 behavior un 16
sudo vppctl -s /run/vpp/cli.vpp5.sock sr localsid address fcbb:bb00:5::100 behavior end


#########################
# VPP 6
#########################
# Interfaces
sudo vppctl -s /run/vpp/cli.vpp6.sock loopback create-interface
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface state loop0 up
sudo vppctl -s /run/vpp/cli.vpp6.sock enable ip6 interface loop0
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface ip address loop0 fcbb:bb00:6::1/128

sudo vppctl -s /run/vpp/cli.vpp6.sock create tap id 60 host-bridge br26
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface state tap60 up
sudo vppctl -s /run/vpp/cli.vpp6.sock enable ip6 interface tap60
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface ip address tap60 2001:db8:2:6::6/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 60["node_id"]="vpp6" 60["interface_name"]="tap60" 60["interface_idx"]=2 \
                                       60["linux_bridge"]="br26" 60["connected_interface"]=23 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp6.sock create tap id 61 host-bridge br46
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface state tap61 up
sudo vppctl -s /run/vpp/cli.vpp6.sock enable ip6 interface tap61
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface ip address tap61 2001:db8:4:6::6/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 61["node_id"]="vpp6" 61["interface_name"]="tap61" 61["interface_idx"]=3 \
                                       61["linux_bridge"]="br46" 61["connected_interface"]=43 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp6.sock create host-interface name vpp6                                   # (vpp6) host-vpp6 <-------> (linux) linux6
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface state host-vpp6 up                                  # used by probe-generator binary
sudo vppctl -s /run/vpp/cli.vpp6.sock enable ip6 interface host-vpp6 
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface ip address host-vpp6 2001:db8:6:a::6/64

sudo vppctl -s /run/vpp/cli.vpp6.sock create host-interface name ext-vpp6                               # (vpp6) host-ext-vpp6 <-----> (linux) veth6
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface state host-ext-vpp6 up                              # connecting vpp6 to probe collector
sudo vppctl -s /run/vpp/cli.vpp6.sock enable ip6 interface host-ext-vpp6 
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface ip address host-ext-vpp6 2001:db8:c:e::6/64

sudo vppctl -s /run/vpp/cli.vpp6.sock create host-interface name client-vpp6                            # (linux) host-6 <-----> (vpp6) host-client-vpp6
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface state host-client-vpp6 up                           # --> used to generate and push test traffic (e.g. ping, iperf3) into the network
sudo vppctl -s /run/vpp/cli.vpp6.sock enable ip6 interface host-client-vpp6
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface ip address host-client-vpp6 2001:db8:a:6::6/64

sudo vppctl -s /run/vpp/cli.vpp6.sock create host-interface name ipfix-vpp6                               # (vpp6) host-ipfix-vpp6 <-----> (linux) veth6-ipfix
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface state host-ipfix-vpp6 up                              # connecting vpp6 to ipfix collector
sudo vppctl -s /run/vpp/cli.vpp6.sock set interface ip address host-ipfix-vpp6 192.168.0.6/24

sudo sleep 1
# Static Routing
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:2::/48 via 2001:db8:2:6::2
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:4::/48 via 2001:db8:4:6::4
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:1::/48 via 2001:db8:2:6::2
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:3::/48 via 2001:db8:2:6::2
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:3::/48 via 2001:db8:4:6::4
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:5::/48 via 2001:db8:2:6::2
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:5::/48 via 2001:db8:4:6::4
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:7::/48 via 2001:db8:4:6::4
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:7::/48 via 2001:db8:2:6::2
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:bb00:8::/48 via 2001:db8:4:6::4
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:aa00:1::/48 via 2001:db8:2:6::2
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:aa00:6::/48 via 2001:db8:a:6::a
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:aa00:7::/48 via 2001:db8:4:6::4
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:aa00:7::/48 via 2001:db8:2:6::2
sudo vppctl -s /run/vpp/cli.vpp6.sock ip route add fcbb:aa00:8::/48 via 2001:db8:4:6::4


# Path Tracing Configuration 
sudo vppctl -s /run/vpp/cli.vpp6.sock pt iface add iface tap60 id 60 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp6.sock pt iface add iface tap61 id 61 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp6.sock pt probe-inject-iface add iface host-vpp6 

# SRv6 Configuration
sudo vppctl -s /run/vpp/cli.vpp6.sock set sr encaps source addr 2001:db8:c:e::6
sudo vppctl -s /run/vpp/cli.vpp6.sock sr localsid prefix fcbb:bb00:6::/48 behavior un 16
sudo vppctl -s /run/vpp/cli.vpp6.sock sr localsid address fcbb:bb00:6::100 behavior end

# SRv6 Policies
sudo vppctl -s /run/vpp/cli.vpp6.sock sr policy add bsid fcbb:bb00:0006:f0ef:: next 2001:db8:c:e::c encap tef


#########################
# VPP 7
#########################
# Interfaces
sudo vppctl -s /run/vpp/cli.vpp7.sock loopback create-interface
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface state loop0 up
sudo vppctl -s /run/vpp/cli.vpp7.sock enable ip6 interface loop0
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface ip address loop0 fcbb:bb00:7::1/128

sudo vppctl -s /run/vpp/cli.vpp7.sock create tap id 70 host-bridge br37
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface state tap70 up
sudo vppctl -s /run/vpp/cli.vpp7.sock enable ip6 interface tap70
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface ip address tap70 2001:db8:3:7::7/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 70["node_id"]="vpp7" 70["interface_name"]="tap70" 70["interface_idx"]=2 \
                                       70["linux_bridge"]="br37" 70["connected_interface"]=34 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp7.sock create tap id 71 host-bridge br57
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface state tap71 up
sudo vppctl -s /run/vpp/cli.vpp7.sock enable ip6 interface tap71
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface ip address tap71 2001:db8:5:7::7/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 71["node_id"]="vpp7" 71["interface_name"]="tap71" 71["interface_idx"]=3 \
                                       71["linux_bridge"]="br57" 71["connected_interface"]=51 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp7.sock create host-interface name vpp7                                   # (vpp7) host-vpp7 <-------> (linux) linux7
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface state host-vpp7 up                                  # used by probe-generator binary
sudo vppctl -s /run/vpp/cli.vpp7.sock enable ip6 interface host-vpp7 
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface ip address host-vpp7 2001:db8:7:a::67/64

sudo vppctl -s /run/vpp/cli.vpp7.sock create host-interface name ext-vpp7                               # (vpp7) host-ext-vpp7 <-----> (linux) veth7
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface state host-ext-vpp7 up                              # connecting vpp7 to probe collector
sudo vppctl -s /run/vpp/cli.vpp7.sock enable ip6 interface host-ext-vpp7 
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface ip address host-ext-vpp7 2001:db8:c:e::7/64

sudo vppctl -s /run/vpp/cli.vpp7.sock create host-interface name client-vpp7                            # (linux) host-7 <-----> (vpp7) host-client-vpp7
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface state host-client-vpp7 up                           # --> used to generate and push test traffic (e.g. ping, iperf3) into the network
sudo vppctl -s /run/vpp/cli.vpp7.sock enable ip6 interface host-client-vpp7
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface ip address host-client-vpp7 2001:db8:a:7::7/64

sudo vppctl -s /run/vpp/cli.vpp7.sock create host-interface name ipfix-vpp7                               # (vpp7) host-ipfix-vpp7 <-----> (linux) veth7-ipfix
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface state host-ipfix-vpp7 up                              # connecting vpp7 to ipfix collector
sudo vppctl -s /run/vpp/cli.vpp7.sock set interface ip address host-ipfix-vpp7 192.168.0.7/24

sudo sleep 1
# Static Routing
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:8::/48 via 2001:db8:5:7::5
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:4::/48 via 2001:db8:5:7::5
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:4::/48 via 2001:db8:3:7::3
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:5::/48 via 2001:db8:5:7::5
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:6::/48 via 2001:db8:5:7::5
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:6::/48 via 2001:db8:3:7::3
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:1::/48 via 2001:db8:3:7::3
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:2::/48 via 2001:db8:5:7::5
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:2::/48 via 2001:db8:3:7::3
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:bb00:3::/48 via 2001:db8:3:7::3
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:aa00:1::/48 via 2001:db8:3:7::3
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:aa00:6::/48 via 2001:db8:5:7::5
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:aa00:6::/48 via 2001:db8:3:7::3
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:aa00:7::/48 via 2001:db8:a:7::a
sudo vppctl -s /run/vpp/cli.vpp7.sock ip route add fcbb:aa00:8::/48 via 2001:db8:5:7::5


# Path Tracing Configuration 
sudo vppctl -s /run/vpp/cli.vpp7.sock pt iface add iface tap70 id 70 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp7.sock pt iface add iface tap71 id 71 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp7.sock pt probe-inject-iface add iface host-vpp7 

# SRv6 Configuration
sudo vppctl -s /run/vpp/cli.vpp7.sock set sr encaps source addr 2001:db8:c:e::7
sudo vppctl -s /run/vpp/cli.vpp7.sock sr localsid prefix fcbb:bb00:7::/48 behavior un 16
sudo vppctl -s /run/vpp/cli.vpp7.sock sr localsid address fcbb:bb00:7::100 behavior end

# SRv6 Policies
sudo vppctl -s /run/vpp/cli.vpp7.sock sr policy add bsid fcbb:bb00:0007:f0ef:: next 2001:db8:c:e::c encap tef

#########################
# VPP 8
#########################
# Interfaces
sudo vppctl -s /run/vpp/cli.vpp8.sock loopback create-interface
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface state loop0 up
sudo vppctl -s /run/vpp/cli.vpp8.sock enable ip6 interface loop0
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface ip address loop0 fcbb:bb00:8::1/128

sudo vppctl -s /run/vpp/cli.vpp8.sock create tap id 80 host-bridge br48
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface state tap80 up
sudo vppctl -s /run/vpp/cli.vpp8.sock enable ip6 interface tap80
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface ip address tap80 2001:db8:4:8::8/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 80["node_id"]="vpp8" 80["interface_name"]="tap80" 80["interface_idx"]=2 \
                                       80["linux_bridge"]="br48" 80["connected_interface"]=44 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp8.sock create tap id 81 host-bridge br58
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface state tap81 up
sudo vppctl -s /run/vpp/cli.vpp8.sock enable ip6 interface tap81
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface ip address tap81 2001:db8:5:8::8/64
cat ${TOPOLOGY_JSON_FILE} | jo -p -f - 81["node_id"]="vpp8" 81["interface_name"]="tap81" 81["interface_idx"]=3 \
                                       81["linux_bridge"]="br58" 81["connected_interface"]=52 > temp.json && cp temp.json ${TOPOLOGY_JSON_FILE} && rm temp.json

sudo vppctl -s /run/vpp/cli.vpp8.sock create host-interface name vpp8                                   # (vpp8) host-vpp8 <-------> (linux) linux8
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface state host-vpp8 up                                  # used by probe generator binary
sudo vppctl -s /run/vpp/cli.vpp8.sock enable ip6 interface host-vpp8
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface ip address host-vpp8 2001:db8:8:a::8/64

sudo vppctl -s /run/vpp/cli.vpp8.sock create host-interface name ext-vpp8                               # (vpp8) host-ext-vpp8 <-----> (linux) veth8
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface state host-ext-vpp8 up                              # connecting vpp8 to probe collector
sudo vppctl -s /run/vpp/cli.vpp8.sock enable ip6 interface host-ext-vpp8
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface ip address host-ext-vpp8 2001:db8:c:e::8/64

sudo vppctl -s /run/vpp/cli.vpp8.sock create host-interface name client-vpp8                            # (linux) host-8 <-----> (vpp8) host-client-vpp8
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface state host-client-vpp8 up                           # --> used to generate and push test traffic into the network
sudo vppctl -s /run/vpp/cli.vpp8.sock enable ip6 interface host-client-vpp8
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface ip address host-client-vpp8 2001:db8:a:8::8/64

sudo vppctl -s /run/vpp/cli.vpp8.sock create host-interface name ipfix-vpp8                               # (vpp8) host-ipfix-vpp8 <-----> (linux) veth8-ipfix
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface state host-ipfix-vpp8 up                              # connecting vpp8 to ipfix collector
sudo vppctl -s /run/vpp/cli.vpp8.sock set interface ip address host-ipfix-vpp8 192.168.0.8/24

sudo sleep 1
# Static Routing 
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:bb00:1::/48 via 2001:db8:5:8::5
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:bb00:1::/48 via 2001:db8:4:8::4
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:bb00:4::/48 via 2001:db8:4:8::4
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:bb00:5::/48 via 2001:db8:5:8::5
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:bb00:6::/48 via 2001:db8:4:8::4
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:bb00:7::/48 via 2001:db8:5:8::5
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:bb00:2::/48 via 2001:db8:5:8::5
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:bb00:2::/48 via 2001:db8:4:8::4
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:bb00:3::/48 via 2001:db8:5:8::5
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:bb00:3::/48 via 2001:db8:4:8::4
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:aa00:1::/48 via 2001:db8:5:8::5
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:aa00:1::/48 via 2001:db8:4:8::4
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:aa00:6::/48 via 2001:db8:4:8::4
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:aa00:7::/48 via 2001:db8:5:8::5
sudo vppctl -s /run/vpp/cli.vpp8.sock ip route add fcbb:aa00:8::/48 via 2001:db8:a:8::a


# Path Tracing Configuration
sudo vppctl -s /run/vpp/cli.vpp8.sock pt iface add iface tap80 id 80 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp8.sock pt iface add iface tap81 id 81 tts-template ${TTS_TEMPLATE_VALUE}
sudo vppctl -s /run/vpp/cli.vpp8.sock pt probe-inject-iface add iface host-vpp8 

# SRv6 Configuration
sudo vppctl -s /run/vpp/cli.vpp8.sock set sr encaps source addr 2001:db8:c:e::8
sudo vppctl -s /run/vpp/cli.vpp8.sock sr localsid prefix fcbb:bb00:8::/48 behavior un 16
sudo vppctl -s /run/vpp/cli.vpp8.sock sr localsid address fcbb:bb00:8::100 behavior end

# SRv6 Policies
sudo vppctl -s /run/vpp/cli.vpp8.sock sr policy add bsid fcbb:bb00:0008:f0ef:: next 2001:db8:c:e::c encap tef

##########################################################################

##################################################
# Fix for loadbalancing in mid nodes
# Otherwise hash for certain flow is the same for all vpp nodes, this resulting in load balancing only working at first hop
# (not ideal, though working)
##################################################
sudo vppctl -s /run/vpp/cli.vpp1.sock set ip6 flow-hash table 0 src dst sport dport proto flowlabel # default 
sudo vppctl -s /run/vpp/cli.vpp2.sock set ip6 flow-hash table 0 src dport proto flowlabel
sudo vppctl -s /run/vpp/cli.vpp3.sock set ip6 flow-hash table 0 dst dport proto flowlabel
sudo vppctl -s /run/vpp/cli.vpp4.sock set ip6 flow-hash table 0 src sport proto flowlabel
sudo vppctl -s /run/vpp/cli.vpp5.sock set ip6 flow-hash table 0 dst sport dport proto flowlabel
sudo vppctl -s /run/vpp/cli.vpp6.sock set ip6 flow-hash table 0 src dst sport dport proto flowlabel # default 
sudo vppctl -s /run/vpp/cli.vpp7.sock set ip6 flow-hash table 0 src dst sport dport proto flowlabel # default 
sudo vppctl -s /run/vpp/cli.vpp8.sock set ip6 flow-hash table 0 src dst sport dport proto flowlabel # default

##################################################
# Add delay to links
# Identify links with "sudo brctl show" or "sudo brctl show br12"
# TODO: maybe automate it 
##################################################
echo "Add network delays..."
# CORE
echo "${br23_delay} on br23"
sudo tc qdisc add dev tap10 root netem delay ${br23_delay}
sudo tc qdisc add dev tap6 root netem delay ${br23_delay}
echo "${br24_delay} on br24"
sudo tc qdisc add dev tap4 root netem delay ${br24_delay}
sudo tc qdisc add dev tap12 root netem delay ${br24_delay}
echo "${br45_delay} on br45"
sudo tc qdisc add dev tap14 root netem delay ${br45_delay}
sudo tc qdisc add dev tap21 root netem delay ${br45_delay}
echo "${br35_delay} on br35"
sudo tc qdisc add dev tap17 root netem delay ${br35_delay}
sudo tc qdisc add dev tap7 root netem delay ${br35_delay}
echo "${br25_delay} on br25"
sudo tc qdisc add dev tap20 root netem delay ${br25_delay}
sudo tc qdisc add dev tap3 root netem delay ${br25_delay}
echo "${br34_delay} on br34"
sudo tc qdisc add dev tap13 root netem delay ${br34_delay}
sudo tc qdisc add dev tap8 root netem delay ${br34_delay}

# CORE-to-PE links
echo "${br12_delay} on br12"
sudo tc qdisc add dev tap1 root netem delay ${br12_delay}
sudo tc qdisc add dev tap2 root netem delay ${br12_delay}
echo "${br13_delay} on br13"
sudo tc qdisc add dev tap0 root netem delay ${br13_delay}
sudo tc qdisc add dev tap9 root netem delay ${br13_delay}
echo "${br26_delay} on br26"
sudo tc qdisc add dev tap22 root netem delay ${br26_delay}
sudo tc qdisc add dev tap5 root netem delay ${br26_delay}
echo "${br46_delay} on br46"
sudo tc qdisc add dev tap15 root netem delay ${br46_delay}
sudo tc qdisc add dev tap23 root netem delay ${br46_delay}
echo "${br48_delay} on br48"
sudo tc qdisc add dev tap16 root netem delay ${br48_delay}
sudo tc qdisc add dev tap26 root netem delay ${br48_delay}
echo "${br58_delay} on br58"
sudo tc qdisc add dev tap19 root netem delay ${br58_delay}
sudo tc qdisc add dev tap27 root netem delay ${br58_delay}
echo "${br37_delay} on br37"
sudo tc qdisc add dev tap11 root netem delay ${br37_delay}
sudo tc qdisc add dev tap24 root netem delay ${br37_delay}
echo "${br57_delay} on br57"
sudo tc qdisc add dev tap18 root netem delay ${br57_delay}
sudo tc qdisc add dev tap25 root netem delay ${br57_delay}


##################################################
# Ping to startup network & arp
##################################################
sudo ip netns exec ns-host-1 ping fcbb:aa00:6::a -c 5 &
sudo ip netns exec ns-host-1 ping fcbb:aa00:7::a -c 5 &
sudo ip netns exec ns-host-1 ping fcbb:aa00:8::a -c 5 &
sudo ip netns exec ns-host-6 ping fcbb:aa00:1::a -c 5 &
sudo ip netns exec ns-host-6 ping fcbb:aa00:7::a -c 5 &
sudo ip netns exec ns-host-6 ping fcbb:aa00:8::a -c 5 &
sudo ip netns exec ns-host-7 ping fcbb:aa00:6::a -c 5 &
sudo ip netns exec ns-host-7 ping fcbb:aa00:1::a -c 5 &
sudo ip netns exec ns-host-7 ping fcbb:aa00:8::a -c 5 &
sudo ip netns exec ns-host-8 ping fcbb:aa00:6::a -c 5 &
sudo ip netns exec ns-host-8 ping fcbb:aa00:7::a -c 5 &
sudo ip netns exec ns-host-8 ping fcbb:aa00:1::a -c 5 &
sleep 10

##################################################
# IPFIX export configuration
##################################################
# VPP1
sudo vppctl -s /run/vpp/cli.vpp1.sock set ipfix exporter collector 192.168.0.100 port 4739 src 192.168.0.1 path-mtu 1450 template-interval 20
sudo vppctl -s /run/vpp/cli.vpp1.sock flowprobe params record l3 active 30 passive 30
sudo vppctl -s /run/vpp/cli.vpp1.sock flowprobe feature add-del host-vpp1 l2
sudo vppctl -s /run/vpp/cli.vpp1.sock flowprobe feature add-del tap10 l2
sudo vppctl -s /run/vpp/cli.vpp1.sock flowprobe feature add-del tap11 l2
sudo vppctl -s /run/vpp/cli.vpp1.sock flowprobe feature add-del host-ext-vpp1 l2

# VPP2
sudo vppctl -s /run/vpp/cli.vpp2.sock set ipfix exporter collector 192.168.0.100 port 4739 src 192.168.0.2 path-mtu 1450 template-interval 20
sudo vppctl -s /run/vpp/cli.vpp2.sock flowprobe params record l3 active 30 passive 30
sudo vppctl -s /run/vpp/cli.vpp2.sock flowprobe feature add-del tap20 l2
sudo vppctl -s /run/vpp/cli.vpp2.sock flowprobe feature add-del tap21 l2
sudo vppctl -s /run/vpp/cli.vpp2.sock flowprobe feature add-del tap22 l2
sudo vppctl -s /run/vpp/cli.vpp2.sock flowprobe feature add-del tap23 l2
sudo vppctl -s /run/vpp/cli.vpp2.sock flowprobe feature add-del tap24 l2

# VPP3
sudo vppctl -s /run/vpp/cli.vpp3.sock set ipfix exporter collector 192.168.0.100 port 4739 src 192.168.0.3 path-mtu 1450 template-interval 20
sudo vppctl -s /run/vpp/cli.vpp3.sock flowprobe params record l3 active 30 passive 30
sudo vppctl -s /run/vpp/cli.vpp3.sock flowprobe feature add-del tap30 l2
sudo vppctl -s /run/vpp/cli.vpp3.sock flowprobe feature add-del tap31 l2
sudo vppctl -s /run/vpp/cli.vpp3.sock flowprobe feature add-del tap32 l2
sudo vppctl -s /run/vpp/cli.vpp3.sock flowprobe feature add-del tap33 l2
sudo vppctl -s /run/vpp/cli.vpp3.sock flowprobe feature add-del tap34 l2

# VPP4
sudo vppctl -s /run/vpp/cli.vpp4.sock set ipfix exporter collector 192.168.0.100 port 4739 src 192.168.0.4 path-mtu 1450 template-interval 20
sudo vppctl -s /run/vpp/cli.vpp4.sock flowprobe params record l3 active 30 passive 30
sudo vppctl -s /run/vpp/cli.vpp4.sock flowprobe feature add-del tap40 l2
sudo vppctl -s /run/vpp/cli.vpp4.sock flowprobe feature add-del tap41 l2
sudo vppctl -s /run/vpp/cli.vpp4.sock flowprobe feature add-del tap42 l2
sudo vppctl -s /run/vpp/cli.vpp4.sock flowprobe feature add-del tap43 l2
sudo vppctl -s /run/vpp/cli.vpp4.sock flowprobe feature add-del tap44 l2

# VPP5
sudo vppctl -s /run/vpp/cli.vpp5.sock set ipfix exporter collector 192.168.0.100 port 4739 src 192.168.0.5 path-mtu 1450 template-interval 20
sudo vppctl -s /run/vpp/cli.vpp5.sock flowprobe params record l3 active 30 passive 30
sudo vppctl -s /run/vpp/cli.vpp5.sock flowprobe feature add-del tap50 l2
sudo vppctl -s /run/vpp/cli.vpp5.sock flowprobe feature add-del tap51 l2
sudo vppctl -s /run/vpp/cli.vpp5.sock flowprobe feature add-del tap52 l2
sudo vppctl -s /run/vpp/cli.vpp5.sock flowprobe feature add-del tap53 l2
sudo vppctl -s /run/vpp/cli.vpp5.sock flowprobe feature add-del tap54 l2

# VPP6
sudo vppctl -s /run/vpp/cli.vpp6.sock set ipfix exporter collector 192.168.0.100 port 4739 src 192.168.0.6 path-mtu 1450 template-interval 20
sudo vppctl -s /run/vpp/cli.vpp6.sock flowprobe params record l3 active 30 passive 30
sudo vppctl -s /run/vpp/cli.vpp6.sock flowprobe feature add-del host-vpp6 l2
sudo vppctl -s /run/vpp/cli.vpp6.sock flowprobe feature add-del tap60 l2
sudo vppctl -s /run/vpp/cli.vpp6.sock flowprobe feature add-del tap61 l2
sudo vppctl -s /run/vpp/cli.vpp6.sock flowprobe feature add-del host-ext-vpp6 l2

# VPP7
sudo vppctl -s /run/vpp/cli.vpp7.sock set ipfix exporter collector 192.168.0.100 port 4739 src 192.168.0.7 path-mtu 1450 template-interval 20
sudo vppctl -s /run/vpp/cli.vpp7.sock flowprobe params record l3 active 30 passive 30
sudo vppctl -s /run/vpp/cli.vpp7.sock flowprobe feature add-del host-vpp7 l2
sudo vppctl -s /run/vpp/cli.vpp7.sock flowprobe feature add-del tap70 l2
sudo vppctl -s /run/vpp/cli.vpp7.sock flowprobe feature add-del tap71 l2
sudo vppctl -s /run/vpp/cli.vpp7.sock flowprobe feature add-del host-ext-vpp7 l2

# VPP8
sudo vppctl -s /run/vpp/cli.vpp8.sock set ipfix exporter collector 192.168.0.100 port 4739 src 192.168.0.8 path-mtu 1450 template-interval 20
sudo vppctl -s /run/vpp/cli.vpp8.sock flowprobe params record l3 active 30 passive 30
sudo vppctl -s /run/vpp/cli.vpp8.sock flowprobe feature add-del host-vpp8 l2
sudo vppctl -s /run/vpp/cli.vpp8.sock flowprobe feature add-del tap80 l2
sudo vppctl -s /run/vpp/cli.vpp8.sock flowprobe feature add-del tap81 l2
sudo vppctl -s /run/vpp/cli.vpp8.sock flowprobe feature add-del host-ext-vpp8 l2

echo "Lab Network is up and running!"

##################################################
# Start probing and pre-processing processes in tmux
##################################################
# PROBING
tmux new-session -s path_tracing_pipeline -d
tmux split-window -v -p 80
tmux select-pane -t 0
tmux split-window -v -p 50
tmux select-pane -t 2
tmux split-window -v -p 80
tmux select-pane -t 0 
tmux split-window -h -p 50
tmux select-pane -t 2
tmux split-window -h -p 50
tmux select-pane -t 4
tmux split-window -h -p 70
tmux select-pane -t 5
tmux split-window -h -p 50
tmux select-pane -t 0
tmux send-keys 'sudo ./probing_bins/ptprobegen --ptprobegen-port=linux1 --api-endpoint=0.0.0.0:50001' C-m
tmux select-pane -t 1
tmux send-keys 'sudo ./probing_bins/ptprobegen --ptprobegen-port=linux6 --api-endpoint=0.0.0.0:50006' C-m
tmux select-pane -t 2
tmux send-keys 'sudo ./probing_bins/ptprobegen --ptprobegen-port=linux7 --api-endpoint=0.0.0.0:50007' C-m
tmux select-pane -t 3
tmux send-keys 'sudo ./probing_bins/ptprobegen --ptprobegen-port=linux8 --api-endpoint=0.0.0.0:50008' C-m
tmux select-pane -t 4
tmux send-keys 'sudo ./probing_bins/probe-collector --port=collector --kafka=127.0.0.1:9093' C-m
tmux send-keys 'echo "Sending data to kafka"' C-m
tmux select-pane -t 5
tmux send-keys 'sudo tcpdump -i brcollector' C-m
tmux select-pane -t 6
tmux send-keys 'sudo tcpdump -i bripfix' C-m

# PYTHON PRE-PROCESSING
tmux new-window
tmux select-window -t 1
tmux split-window -v -p 70
tmux select-pane -t 1
tmux send-keys 'htop' C-m
tmux select-pane -t 0
tmux split-window -h -p 50
tmux select-pane -t 0
tmux send-keys 'python3 ./preprocessing_scripts/pre-processing.py' C-m
tmux select-pane -t 1
tmux send-keys 'python3 ./preprocessing_scripts/topic-processing.py' C-m
tmux select-pane -t 0
sleep 2

# PYTHON IPFIX PROCESSING
tmux new-window
tmux select-window -t 2
tmux split-window -v -p 70
tmux select-pane -t 0
tmux send-keys 'python3 ./preprocessing_scripts/ipfix-processing.py' C-m
tmux select-pane -t 1
sleep 2

# Re-attach to first window (probing)
tmux select-window -t 0
tmux select-pane -t 7
# Start some probes on the background
sleep 5
tmux send-keys './lightweight_final_probes.sh &' C-m
tmux send-keys 'echo "Probes started on background (lasting 1H)..."' C-m
tmux send-keys 'cat README.md' C-m

# Attach to tmux session at windows 0 (PROBING)
tmux select-window -t 0
tmux select-pane -t 7
tmux a -t path_tracing_pipeline