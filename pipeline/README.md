# Tmux session help

- Ping throughout the network (connectivity test)

        ./reping_all.sh

- Stop current probing session:

        ./reset_probing.sh

- Start probe generation:

        ./lightweight_final_probes.sh       # Default probing session
        ./final_probes.sh                   # Alternative, higher bandwidth

- Change default link delays:

        ./link_delay_set.sh --help                                      # help
        ./link_delay_set.sh --link <"link_id"> --delay <delay_ms>       # set new delay to link
        ./link_delay_set.sh --defaults                                  # reset to default values

# Overview of the scripts' functionality

The following diagrams give an idea on what the python scripts do and how they interact within the Visualization pipeline. Refer to the "Design" Section of [My Thesis](https://leonardorodoni.ch/thesis.pdf) for more detailed information and explanations.

## Main Path Tracing Visualization Pipeline

![Alt text](../images/pipeline_1.png?raw=true "Path Tracing Main Pipeline")

## Alternative Postcard-export Pipeline based on IPFIX with Path Tracing correlation

![Alt text](../images/pipeline_2.png?raw=true "IPFIX Integration with Path Tracing")