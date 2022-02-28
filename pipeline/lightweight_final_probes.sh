#!/bin/bash
# HINTS: 
# - 100ppf and 100pps: 1second <--> 1 flow label (example: 10min flow fls=1 and fle=600)
# - 100 ppf and 10pps: 10 seconds <--> 1 flow labels (example: 10min flow fls=1 and fle=60)

# CUSTOMER 1 (IPs: fcbb:bb00:1::1, fcbb:bb00:7::1, fcbb:bb00:8::1, traffic-class=1)

sudo ./probing_bins/ptprobegen-client --fls=1 --fle=3600 --ppf=100 --pps=10 --tc=1 \
    --src-addr=fcbb:bb00:1::1 \
    --tef-sid=fcbb:bb00:8:f0ef:: \
    --segment-list=fcbb:bb00:8:f0ef:: \
    --ptprobegen=127.0.0.1:50001 &

sudo ./probing_bins/ptprobegen-client --fls=1 --fle=360 --ppf=100 --pps=1 --tc=1\
    --src-addr=fcbb:bb00:1::1 \
    --tef-sid=fcbb:bb00:7:f0ef:: \
    --segment-list=fcbb:bb00:7:f0ef:: \
    --ptprobegen=127.0.0.1:50001 &

sudo ./probing_bins/ptprobegen-client --fls=1 --fle=360 --ppf=100 --pps=1 --tc=1\
    --src-addr=fcbb:bb00:7::1 \
    --tef-sid=fcbb:bb00:8:f0ef:: \
    --segment-list=fcbb:bb00:8:f0ef:: \
    --ptprobegen=127.0.0.1:50007 &

sudo ./probing_bins/ptprobegen-client --fls=1 --fle=360 --ppf=100 --pps=2 --tc=1\
    --src-addr=fcbb:bb00:8::1 \
    --tef-sid=fcbb:bb00:1:f0ef:: \
    --segment-list=fcbb:bb00:1:f0ef:: \
    --ptprobegen=127.0.0.1:50008 &

sudo ./probing_bins/ptprobegen-client --fls=361 --fle=720 --ppf=100 --pps=1 --tc=1 \
    --src-addr=fcbb:bb00:7::1 \
    --tef-sid=fcbb:bb00:8:f0ef:: \
    --segment-list='fcbb:bb00:3::100,fcbb:bb00:3::100,fcbb:bb00:4::100,fcbb:bb00:8::100' \
    --ptprobegen=127.0.0.1:50007 &

sudo ./probing_bins/ptprobegen-client --fls=720 --fle=1080 --ppf=100 --pps=1 --tc=1 \
    --src-addr=fcbb:bb00:1::1 \
    --tef-sid=fcbb:bb00:8:f0ef:: \
    --segment-list='fcbb:bb00:2::100,fcbb:bb00:2::100,fcbb:bb00:4::100,fcbb:bb00:5::100,fcbb:bb00:8::100' \
    --ptprobegen=127.0.0.1:50001 &

sudo ./probing_bins/ptprobegen-client --fls=1080 --fle=1440 --ppf=100 --pps=1 --tc=1 \
    --src-addr=fcbb:bb00:8::1 \
    --tef-sid=fcbb:bb00:7:f0ef:: \
    --segment-list='fcbb:bb00:4::100,fcbb:bb00:4::100,fcbb:bb00:2::100,fcbb:bb00:3::100,fcbb:bb00:7::100' \
    --ptprobegen=127.0.0.1:50008 &

sudo ./probing_bins/ptprobegen-client --fls=1440 --fle=1800 --ppf=100 --pps=1 --tc=1 \
    --src-addr=fcbb:bb00:7::1 \
    --tef-sid=fcbb:bb00:1:f0ef:: \
    --segment-list='fcbb:bb00:3::100,fcbb:bb00:3::100,fcbb:bb00:2::100,fcbb:bb00:1::100' \
    --ptprobegen=127.0.0.1:50007 &


# CUSTOMER 2 (IPs: fcbb:bb00:1::2, fcbb:bb00:6::2, fcbb:bb00:7::2, traffic-class=2)

sudo ./probing_bins/ptprobegen-client --fls=1 --fle=3600 --ppf=100 --pps=6 --tc=2 \
    --src-addr=fcbb:bb00:6::2 \
    --tef-sid=fcbb:bb00:7:f0ef:: \
    --segment-list=fcbb:bb00:7:f0ef:: \
    --ptprobegen=127.0.0.1:50006 &

sudo ./probing_bins/ptprobegen-client --fls=1 --fle=360 --ppf=100 --pps=1 --tc=2\
    --src-addr=fcbb:bb00:7::2 \
    --tef-sid=fcbb:bb00:6:f0ef:: \
    --segment-list=fcbb:bb00:6:f0ef:: \
    --ptprobegen=127.0.0.1:50007 &

sudo ./probing_bins/ptprobegen-client --fls=1 --fle=360 --ppf=100 --pps=1 --tc=2\
    --src-addr=fcbb:bb00:7::2 \
    --tef-sid=fcbb:bb00:1:f0ef:: \
    --segment-list=fcbb:bb00:1:f0ef:: \
    --ptprobegen=127.0.0.1:50007 &

sudo ./probing_bins/ptprobegen-client --fls=1 --fle=360 --ppf=100 --pps=2 --tc=2\
    --src-addr=fcbb:bb00:1::2 \
    --tef-sid=fcbb:bb00:6:f0ef:: \
    --segment-list=fcbb:bb00:6:f0ef:: \
    --ptprobegen=127.0.0.1:50001 &

sudo ./probing_bins/ptprobegen-client --fls=361 --fle=720 --ppf=100 --pps=1 --tc=2 \
    --src-addr=fcbb:bb00:1::2 \
    --tef-sid=fcbb:bb00:6:f0ef:: \
    --segment-list='fcbb:bb00:3::100,fcbb:bb00:3::100,fcbb:bb00:4::100,fcbb:bb00:6::100' \
    --ptprobegen=127.0.0.1:50001 &

sudo ./probing_bins/ptprobegen-client --fls=720 --fle=1080 --ppf=100 --pps=1 --tc=2 \
    --src-addr=fcbb:bb00:7::2 \
    --tef-sid=fcbb:bb00:6:f0ef:: \
    --segment-list='fcbb:bb00:3::100,fcbb:bb00:3::100,fcbb:bb00:2::100,fcbb:bb00:6::100' \
    --ptprobegen=127.0.0.1:50007 &

sudo ./probing_bins/ptprobegen-client --fls=1080 --fle=1440 --ppf=100 --pps=1 --tc=2 \
    --src-addr=fcbb:bb00:1::2 \
    --tef-sid=fcbb:bb00:7:f0ef:: \
    --segment-list='fcbb:bb00:2::100,fcbb:bb00:2::100,fcbb:bb00:5::100,fcbb:bb00:7::100' \
    --ptprobegen=127.0.0.1:50001 &

sudo ./probing_bins/ptprobegen-client --fls=1440 --fle=1800 --ppf=100 --pps=1 --tc=2 \
    --src-addr=fcbb:bb00:6::2 \
    --tef-sid=fcbb:bb00:1:f0ef:: \
    --segment-list='fcbb:bb00:4::100,fcbb:bb00:4::100,fcbb:bb00:5::100,fcbb:bb00:1::100' \
    --ptprobegen=127.0.0.1:50006 &

# CUSTOMER 3 (IPs: fcbb:bb00:1::3, fcbb:bb00:6::3, fcbb:bb00:8::3, traffic-class=3)

sudo ./probing_bins/ptprobegen-client --fls=1 --fle=3600 --ppf=100 --pps=6 --tc=3 \
    --src-addr=fcbb:bb00:6::3 \
    --tef-sid=fcbb:bb00:8:f0ef:: \
    --segment-list=fcbb:bb00:8:f0ef:: \
    --ptprobegen=127.0.0.1:50006 &

sudo ./probing_bins/ptprobegen-client --fls=1 --fle=360 --ppf=100 --pps=1 --tc=3\
    --src-addr=fcbb:bb00:8::3 \
    --tef-sid=fcbb:bb00:1:f0ef:: \
    --segment-list=fcbb:bb00:1:f0ef:: \
    --ptprobegen=127.0.0.1:50008 &

sudo ./probing_bins/ptprobegen-client --fls=1 --fle=360 --ppf=100 --pps=1 --tc=3\
    --src-addr=fcbb:bb00:1::3 \
    --tef-sid=fcbb:bb00:6:f0ef:: \
    --segment-list=fcbb:bb00:6:f0ef:: \
    --ptprobegen=127.0.0.1:50001 &

sudo ./probing_bins/ptprobegen-client --fls=361 --fle=720 --ppf=100 --pps=1 --tc=3 \
    --src-addr=fcbb:bb00:1::3 \
    --tef-sid=fcbb:bb00:8:f0ef:: \
    --segment-list='fcbb:bb00:3::100,fcbb:bb00:3::100,fcbb:bb00:5::100,fcbb:bb00:8::100' \
    --ptprobegen=127.0.0.1:50001 &

sudo ./probing_bins/ptprobegen-client --fls=720 --fle=1080 --ppf=100 --pps=1 --tc=3 \
    --src-addr=fcbb:bb00:6::3 \
    --tef-sid=fcbb:bb00:1:f0ef:: \
    --segment-list='fcbb:bb00:4::100,fcbb:bb00:4::100,fcbb:bb00:5::100,fcbb:bb00:2::100,fcbb:bb00:1::100' \
    --ptprobegen=127.0.0.1:50006 &