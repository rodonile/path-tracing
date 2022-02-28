#!/bin/bash

# Kill iperf3
pid=$(ps -e | pgrep iperf3)  
echo "Iperf3 process ids:"
echo $pid    
sleep 2
if [[ ! -z "$pid" ]]; # check if $pid is not empty
then
   echo "Killing all iperf3 processes"
   sudo kill -2 $pid
fi

# Kill tcpdumps 
pid=$(ps -e | pgrep tcpdump)  
echo "Tcpdump process ids:"
echo $pid 
sleep 5
if [[ ! -z "$pid" ]]; # check if $pid is not empty
then
   echo "Killing all tcpdump processes"
   sudo kill -2 $pid
fi

# Kill tmux sessions
echo "Killing all tmux sessions"
tmux kill-server

# kill all vpp instances 
echo "Killing all vpp instances"
sudo kill $(pidof vpp)

## Bring down host namespaces
echo "Delete host namespaces"
sudo ip netns del ns-host-1
sudo ip netns del ns-host-6
sudo ip netns del ns-host-7
sudo ip netns del ns-host-8

# If not successful remove the client-vpp1 and client-vpp8 interfaces manually
if [ $? -eq 0 ]; then
   echo "Bringing all interfaces and bridges down..."
else
   echo "Somehow ns's not tear down correctly, solving..."
   echo "Bringing all interfaces and bridges down..."
   sudo ifconfig client-vpp1 down
   sudo ifconfig client-vpp6 down
   sudo ifconfig client vpp7 down
   sudo ifconfig client vpp8 down
   sudo ip link del client-vpp1
   sudo ip link del client-vpp6
   sudo ip link del client-vpp7
   sudo ip link del client-vpp8
fi

# bring all bridges down 
sudo ifconfig br23 down
sudo ifconfig br24 down
sudo ifconfig br45 down
sudo ifconfig br35 down
sudo ifconfig br25 down
sudo ifconfig br34 down
sudo ifconfig br12 down
sudo ifconfig br13 down
sudo ifconfig br26 down
sudo ifconfig br46 down
sudo ifconfig br48 down
sudo ifconfig br58 down
sudo ifconfig br37 down
sudo ifconfig br57 down
sudo ifconfig brcollector down
sudo ifconfig bripfix down

# delete all linux bridges 
sudo brctl delbr br23
sudo brctl delbr br24
sudo brctl delbr br45
sudo brctl delbr br35
sudo brctl delbr br25
sudo brctl delbr br34
sudo brctl delbr br12
sudo brctl delbr br13
sudo brctl delbr br26
sudo brctl delbr br46
sudo brctl delbr br48
sudo brctl delbr br58
sudo brctl delbr br37
sudo brctl delbr br57
sudo brctl delbr brcollector
sudo brctl delbr bripfix

# delete all veth pairs 
sudo ip link delete linux1 type veth peer name vpp1
sudo ip link delete linux6 type veth peer name vpp6
sudo ip link delete linux7 type veth peer name vpp7
sudo ip link delete linux8 type veth peer name vpp8
sudo ip link delete veth0 type veth peer name collector
sudo ip link delete veth1 type veth peer name ext-vpp1
sudo ip link delete veth6 type veth peer name ext-vpp6
sudo ip link delete veth7 type veth peer name ext-vpp7
sudo ip link delete veth8 type veth peer name ext-vpp8
sudo ip link delete veth1-ipfix type veth peer name ipfix-vpp1
sudo ip link delete veth2-ipfix type veth peer name ipfix-vpp2
sudo ip link delete veth3-ipfix type veth peer name ipfix-vpp3
sudo ip link delete veth4-ipfix type veth peer name ipfix-vpp4
sudo ip link delete veth5-ipfix type veth peer name ipfix-vpp5
sudo ip link delete veth6-ipfix type veth peer name ipfix-vpp6
sudo ip link delete veth7-ipfix type veth peer name ipfix-vpp7
sudo ip link delete veth8-ipfix type veth peer name ipfix-vpp8