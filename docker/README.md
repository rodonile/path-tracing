# Docker deployment instructions (via docker-compose)

## Requirements

- Working installation of docker and docker compose. A quick guide is available [here](https://support.netfoundry.io/hc/en-us/articles/360057865692-Installing-Docker-and-docker-compose-for-Ubuntu-20-04).

## Kafka and Druid deployment instruction

- Navigate to the docker directory:

        cd path_tracing/docker

- Deploy the docker-compose stack:
        
        docker-compose up -d

## Configuration of the Druid Datasources

The docker-compose file spins up a fresh Druid install. To configure Druid as a Kafka consumer and query source for Turnilo, a few Druid Datasources need to be configured. The JSON specifications for the Datasources are available in the path_tracing/docker/druid folder. 

To add a Datasource from the Druid GUI, select "Load Data", "Edit Spec", then copy/paste one of the schemas. For basic functionalities, the datasources pt_probe_processed, pt_probe_global and pt_probe_hub need to be running. For additional IPFIX integration, also the datasources pt_ipfix_processed and pt_ipfix_joined need to be added. 

## Pmacct deployment instructions

The docker container will setup a nfacctd listener on 192.168.0.100:4739. The setup script already configures all vpp routers to export IPFIX information to this address. 

To deploy the nfacct container:

- Navigate to the docker/pmacct directory:

        cd path_tracing/docker/pmacct

- Deploy the docker-compose stack:

        docker-compose up -d

- If you modify the config file (path_tracing/docker/pmacct/config/nfacctd.conf), the docker container needs to be recreated:

        docker-compose down
        docker-compose up -d
