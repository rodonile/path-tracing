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
