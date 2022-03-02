# Path Tracing Visualization Pipeline

This repository contains a set of scripts that setup a Linux virtual network with VPP routers running the [Path Tracing](https://github.com/path-tracing) protocol. The scripts also launch live python programs that process telemetry packets and ingest them into a kafka broker. The information in the telemetry packets can then be used to visualize important network metrics such as delay and paths.

For more details explanations on Path Tracing and how the pipeline works refer to [My Master Thesis](https://leonardorodoni.ch/thesis.pdf), which was carried out at [ETH Zurich](https://ee.ethz.ch/) toghether with the [Swisscom](https://swisscom.ch) Telemetry and Analytics Team led by Thomas Graf. 

Instructions on how to install the required dependencies, docker containers and launch the virtual environment are available below.

## Description
![Alt text](images/draft_final_pipeline.png?raw=true "Title")

## Installation and Requirements

In order to run the pipeline, the following software instances need to be deployed:

- VPP with Path Tracing Plugin
  In order to install it refer to the README in the ./vpp folder

- [Apache Kafka](https://kafka.apache.org/) Message Broker
- [Apache Druid](https://druid.apache.org/) Time Series Database
  Kafka and Druid have been deployed as docker container. A docker-compose.yml file, information on how to provision it as well as configuration files are available in the ./docker folder. 

- [Turnilo](https://github.com/allegro/turnilo) visualization backend
  Instruction on how to install and configure Turnilo are available in the ./turnilo folder. 

## How to run the pipeline

- Navigate to the ./pipeline directory
- Run the bash script ./setup-network.sh

The script takes care of bootstrapping the virtual network, starting some python processing programs and launches Path Tracing probes sessions to generate traffic into the network. If successful, the script will launch a tmux session like the following:

[Insert tmux image]