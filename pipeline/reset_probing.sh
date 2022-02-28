#!/bin/bash
# Kill ptprobgen binaries
pid=$(ps -e | pgrep ptprobegen)  
echo "ptprobegen process ids:"
echo $pid    
sleep 2
if [[ ! -z "$pid" ]]; # check if $pid is not empty
then
   echo "Killing all ptprobegen processes"
   sudo kill -2 $pid
fi

echo "Starting up probing binaries"
tmux select-window -t 0
tmux select-pane -t 0
tmux send-keys 'sudo ./probing_bins/ptprobegen --ptprobegen-port=linux1 --api-endpoint=0.0.0.0:50001' C-m
tmux select-pane -t 1
tmux send-keys 'sudo ./probing_bins/ptprobegen --ptprobegen-port=linux6 --api-endpoint=0.0.0.0:50006' C-m
tmux select-pane -t 2
tmux send-keys 'sudo ./probing_bins/ptprobegen --ptprobegen-port=linux7 --api-endpoint=0.0.0.0:50007' C-m
tmux select-pane -t 3
tmux send-keys 'sudo ./probing_bins/ptprobegen --ptprobegen-port=linux8 --api-endpoint=0.0.0.0:50008' C-m
tmux select-pane -t 7
tmux send-keys 'clear' C-m
