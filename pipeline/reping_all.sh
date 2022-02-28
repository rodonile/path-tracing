#/bin/bash
sudo ip netns exec ns-host-1 ping fcbb:aa00:6::a -c 10 &
sudo ip netns exec ns-host-1 ping fcbb:aa00:7::a -c 10 &
sudo ip netns exec ns-host-1 ping fcbb:aa00:8::a -c 10 &
sudo ip netns exec ns-host-6 ping fcbb:aa00:1::a -c 10 &
sudo ip netns exec ns-host-6 ping fcbb:aa00:7::a -c 10 &
sudo ip netns exec ns-host-6 ping fcbb:aa00:8::a -c 10 &
sudo ip netns exec ns-host-7 ping fcbb:aa00:6::a -c 10 &
sudo ip netns exec ns-host-7 ping fcbb:aa00:1::a -c 10 &
sudo ip netns exec ns-host-7 ping fcbb:aa00:8::a -c 10 &
sudo ip netns exec ns-host-8 ping fcbb:aa00:6::a -c 10 &
sudo ip netns exec ns-host-8 ping fcbb:aa00:7::a -c 10 &
sudo ip netns exec ns-host-8 ping fcbb:aa00:1::a -c 10 &
