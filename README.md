# Path Tracing Visualization Pipeline

This repository contains a set of scripts that setup a Linux virtual network with VPP routers running the [Path Tracing](https://github.com/path-tracing) protocol. The scripts also launch live python programs that process telemetry packets and ingest them into a kafka broker. The information in the telemetry packets can then be used to visualize important network metrics such as delay and paths.

For more details explanations on Path Tracing and how the pipeline works refer to [My Master Thesis](https://leonardorodoni.ch/thesis.pdf), which was carried out at [ETH Zurich](https://ee.ethz.ch/) toghether with the [Swisscom](https://swisscom.ch) Telemetry and Analytics Team led by Thomas Graf. 

Instructions on how to install the required dependencies, docker containers and launch the virtual environment are available below.

## Description
![Alt text](images/draft_final_pipeline.png?raw=true "Title")

## Installation and Requirements

In order to run the pipeline, the following software instances and packages need to be deployed:

- We have deployed the pipeline on an Ubuntu 20.04 server, although it should work for any debian based distro. Additional required packages can be installed with the following commands:  

        sudo apt install net-tools bridge-utils 
        sudo snap install jo

- [VPP](https://s3-docs.fd.io/vpp/22.06/) with Path Tracing Plugin  
    The code for the VPP version with the Path Tracing patch is available [here](https://github.com/path-tracing/vpp). Since compilation can be quite cumberson, binaries can be downloaded from [this link](https://leonardorodoni.ch/link_for_binaries), and if you want to quickly test out our pipeline we suggest using them. In order to install the binaries refer to the README in the ./vpp folder.

- [Apache Kafka](https://kafka.apache.org/) Message Broker and [Apache Druid](https://druid.apache.org/) Time Series Database  
    Kafka and Druid have been deployed as docker container. A docker-compose.yml file, information on how to provision it as well as configuration files are available in the ./docker folder. 

- [Turnilo](https://github.com/allegro/turnilo) visualization backend  
    Instruction on how to install and configure Turnilo are available in the ./turnilo folder. 

- Each one of the 8 VPP instances is assigned to a single CPU core. You most likely will need to adjust the cpu main-core indexing to reflect the available core on your VM. 

## How to run the pipeline

- Make sure all the requirements are satisfied
- Navigate to the pipeline directory

        cd path_tracing/pipeline

- Run the setup script 

        ./setup-network.sh

The script takes care of bootstrapping the virtual network, starting some python processing programs and launches Path Tracing probes sessions to generate traffic into the network. If successful, the script will launch a tmux session like the following:

[Insert tmux image]