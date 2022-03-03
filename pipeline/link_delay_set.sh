#!/bin/bash

# DELAY DEFAULTS
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

# Parse arguments
DEFAULTS='NO'
LINK='NO'
DELAY_MS=0

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -l| --link)
      LINK=$2
      shift
      shift
      ;;

    -m| --delay)
      DELAY_MS="$2ms"
      shift
      shift
      ;;

    -d|--defaults)
      DEFAULTS=YES
      shift
      ;;

    -h|--help)
      echo './link_delay_set.sh --link "br12" --delay 5         # set delay for br12 to 5ms'
      echo './link_delay_set.sh --defaults                      # reset delays to default values'
      shift
      ;;

    *) # unknown option
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

# IF LINK NOT 0 --> set new delay
if [[ $LINK == 'br23' ]]
then
    echo "$DELAY_MS on br23"
    sudo tc qdisc del dev tap10 root netem
    sudo tc qdisc del dev tap6 root netem
    sudo tc qdisc add dev tap10 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap6 root netem delay $DELAY_MS
elif [[ $LINK == 'br24' ]]
then
    echo "$DELAY_MS on br24"
    sudo tc qdisc del dev tap4 root netem 
    sudo tc qdisc del dev tap12 root netem
    sudo tc qdisc add dev tap4 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap12 root netem delay $DELAY_MS
elif [[ $LINK == 'br45' ]]
then
    echo "$DELAY_MS on br45"
    sudo tc qdisc del dev tap14 root netem
    sudo tc qdisc del dev tap21 root netem
    sudo tc qdisc add dev tap14 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap21 root netem delay $DELAY_MS
elif [[ $LINK == 'br35' ]]
then
    echo "$DELAY_MS on br35"
    sudo tc qdisc del dev tap17 root netem
    sudo tc qdisc del dev tap7 root netem
    sudo tc qdisc add dev tap17 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap7 root netem delay $DELAY_MS
elif [[ $LINK == 'br25' ]]
then
    echo "$DELAY_MS on br25"
    sudo tc qdisc del dev tap20 root netem
    sudo tc qdisc del dev tap3 root netem
    sudo tc qdisc add dev tap20 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap3 root netem delay $DELAY_MS
elif [[ $LINK == 'br34' ]]
then
    echo "$DELAY_MS on br34"
    sudo tc qdisc del dev tap13 root netem 
    sudo tc qdisc del dev tap8 root netem
    sudo tc qdisc add dev tap13 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap8 root netem delay $DELAY_MS
elif [[ $LINK == 'br12' ]]
then
    echo "$DELAY_MS on br12"
    sudo tc qdisc del dev tap1 root netem
    sudo tc qdisc del dev tap2 root netem
    sudo tc qdisc add dev tap1 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap2 root netem delay $DELAY_MS
elif [[ $LINK == 'br13' ]]
then
    echo "$DELAY_MS on br13"
    sudo tc qdisc del dev tap0 root netem
    sudo tc qdisc del dev tap9 root netem
    sudo tc qdisc add dev tap0 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap9 root netem delay $DELAY_MS
elif [[ $LINK == 'br26' ]]
then
    echo "$DELAY_MS on br26"
    sudo tc qdisc del dev tap22 root netem
    sudo tc qdisc del dev tap5 root netem
    sudo tc qdisc add dev tap22 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap5 root netem delay $DELAY_MS
elif [[ $LINK == 'br46' ]]
then
    echo "$DELAY_MS on br46"
    sudo tc qdisc del dev tap15 root netem
    sudo tc qdisc del dev tap23 root netem
    sudo tc qdisc add dev tap15 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap23 root netem delay $DELAY_MS
elif [[ $LINK == 'br48' ]]
then
    echo "$DELAY_MS on br48"
    sudo tc qdisc del dev tap16 root netem
    sudo tc qdisc del dev tap26 root netem
    sudo tc qdisc add dev tap16 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap26 root netem delay $DELAY_MS
elif [[ $LINK == 'br58' ]]
then
    echo "$DELAY_MS on br58"
    sudo tc qdisc del dev tap19 root netem
    sudo tc qdisc del dev tap27 root netem
    sudo tc qdisc add dev tap19 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap27 root netem delay $DELAY_MS
elif [[ $LINK == 'br37' ]]
then
    echo "$DELAY_MS on br37"
    sudo tc qdisc del dev tap11 root netem
    sudo tc qdisc del dev tap24 root netem
    sudo tc qdisc add dev tap11 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap24 root netem delay $DELAY_MS
elif [[ $LINK == 'br57' ]]
then
    echo "$DELAY_MS on br57"
    sudo tc qdisc del dev tap18 root netem
    sudo tc qdisc del dev tap25 root netem
    sudo tc qdisc add dev tap18 root netem delay $DELAY_MS
    sudo tc qdisc add dev tap25 root netem delay $DELAY_MS
fi

# IF DEFAULTS is 1 --> set defaults and exit
if [[ $DEFAULTS == 'YES' ]]
then
    # Reset all qdiscs
    echo "Resetting qdiscs..."
    # CORE
    sudo tc qdisc del dev tap10 root netem
    sudo tc qdisc del dev tap6 root netem 
    sudo tc qdisc del dev tap4 root netem 
    sudo tc qdisc del dev tap12 root netem
    sudo tc qdisc del dev tap14 root netem
    sudo tc qdisc del dev tap21 root netem
    sudo tc qdisc del dev tap17 root netem
    sudo tc qdisc del dev tap7 root netem 
    sudo tc qdisc del dev tap20 root netem
    sudo tc qdisc del dev tap3 root netem 
    sudo tc qdisc del dev tap13 root netem
    sudo tc qdisc del dev tap8 root netem 
    # CORE-to-PE links
    sudo tc qdisc del dev tap1 root netem 
    sudo tc qdisc del dev tap2 root netem 
    sudo tc qdisc del dev tap0 root netem 
    sudo tc qdisc del dev tap9 root netem 
    sudo tc qdisc del dev tap22 root netem
    sudo tc qdisc del dev tap5 root netem 
    sudo tc qdisc del dev tap15 root netem
    sudo tc qdisc del dev tap23 root netem
    sudo tc qdisc del dev tap16 root netem
    sudo tc qdisc del dev tap26 root netem
    sudo tc qdisc del dev tap19 root netem
    sudo tc qdisc del dev tap27 root netem
    sudo tc qdisc del dev tap11 root netem
    sudo tc qdisc del dev tap24 root netem
    sudo tc qdisc del dev tap18 root netem
    sudo tc qdisc del dev tap25 root netem

    ##################################################
    # Add default delay values to links
    # Identify links with "sudo brctl show" or "sudo brctl show br12"
    ##################################################
    echo "Apply default network delays..."
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
fi