# Path Tracing Visualization Pipeline

This repository contains a set of scripts that setup a Linux virtual network with VPP routers running the [Path Tracing](https://github.com/path-tracing) protocol. The scripts also launch live python programs that process telemetry packets and ingest them into a kafka broker. The information in the telemetry packets can then be used to visualize important network metrics such as delay and paths.

For more details explanations on Path Tracing and how the pipeline works refer to [My Master Thesis](https://leonardorodoni.ch/thesis.pdf), which was carried out at [ETH Zurich](https://ee.ethz.ch/) toghether with the [Swisscom](https://swisscom.ch) Telemetry and Analytics Team led by Thomas Graf. 

Instructions on how to install the required dependencies, docker containers and launch the virtual environment are available below.

## Description
![Alt text](images/draft_final_pipeline.png?raw=true "Path Tracing Virtual Network Topology Diagram")

## Installation Instructions and Requirements

- We have deployed the pipeline on an Ubuntu 20.04 server, although it should work for any debian based distro. Additional required packages can be installed with the following commands:  

        sudo apt install net-tools bridge-utils 
        sudo snap install jo

- **[VPP](https://s3-docs.fd.io/vpp/22.06/) with Path Tracing Plugin**  
    The code for the VPP version with the Path Tracing patch is available [here](https://github.com/path-tracing/vpp). Since compilation can be quite cumbersome, pre-compiled binaries (.deb) can be downloaded from [this link](https://leonardorodoni.ch/link_for_binaries), and if you want to quickly test out our pipeline we suggest using them. In order to install the binaries refer to the README in the ./vpp folder.

- **[Apache Kafka](https://kafka.apache.org/) Message Broker and [Apache Druid](https://druid.apache.org/) Time Series Database**    
    Kafka and Druid can be deployed as docker containers. A docker-compose.yml file, information on how to provision it as well as configuration files are available in the ./docker folder. 

- **[Turnilo](https://github.com/allegro/turnilo) visualization backend**  
    Instruction on how to install and configure Turnilo are available in the ./turnilo folder. 

- Each one of the 8 VPP instances is assigned to a single CPU core. We suggest assigning each VPP instance to a single core for stability reasons. You most likely will need to adjust the cpu main-core indexing in the setup script (**pipeline/setup-network.sh**) under "Start VPP instances" to reflect the available cores on your VM. For example, in a VM with 8 cores, the indexes range from 0 to 7. To assign the virst VPP instance to the first core the parameter in the setup script will be:

        cpu {main-core 0}

- Going through the setup script you will find other parameters that you can change, such as for example link_delays and Path Tracing templates.

- **[Pmacct](https://github.com/pmacct/pmacct) collector**  
    Pmacct needs to be installed if IPFIX integration is desired, but is not required for basic functionality of the main Path Tracing pipeline. Refer to the "Design" section of [my thesis](https://leonardorodoni.ch/thesis.pdf) for more explanations. The nfacct daemon (Pmacct daemon listening for IPFIX packets) can be deployed as a docker container. A docker-compose.yml file, instructions on how to provision it as well as configuration files are available in the ./docker folder.

## How to run the pipeline

- Make sure all the requirements are satisfied
- Navigate to the pipeline directory

        cd path_tracing/pipeline

- Run the setup script 

        ./setup-network.sh

The script takes care of bootstrapping the virtual network, starting some python processing programs and launches Path Tracing probes sessions to generate traffic into the network. If successful, the script will launch a tmux session with debugging info:

Window 1                         |  Window 2
:-------------------------------:|:--------------------------------:
![](images/tmux_1.PNG?raw=true)  |  ![](images/tmux_2.PNG?raw=true)

From the tmux session, it is possible to trigger the following functionality:

- Stop current probing session:

        ./reset_probing.sh

- Start the default probing sessions:

        ./lightweight_final_probes.sh

- Start probing sessions with more bandwidth:

        ./final_probes.sh

- Start additional probing sessions  
  Refer to final_probes.sh scripts for example syntax on how to interact with the Path Tracing probe generation binaries.

- Ping throughout the network to check connectivity (this is also done when the script boots up):

        ./reping_all.sh

## How to access Turnilo and Druid GUIs:

- Turnilo listens at port localhost:9090
- Druid listens at port localhost:8888

Here some examples of possible visualization in Turnilo:

![Alt text](images/turnilo_1.PNG?raw=true "Path And Delay")

![Alt text](images/turnilo_2.PNG?raw=true "Link Delay")

["PUT HERE IMAGE OF VISUALIATION WITH TIME SPLIT"]

Additional visualization examples are available in the "Evaluation" section of [my thesis](https://leonardorodoni.ch/thesis.pdf).

## Tear down virtual network

The following commands stop all vpp instances, programs, scripts and removes all linux network interfaces.

- Exit the tmux session ("ctrl+b" then "d"), then run:

        ./clean-network.sh