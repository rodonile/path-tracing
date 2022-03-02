# Docker deployment instructions (via docker-compose)

## Requirements

- Install docker and docker compose. A quick guide is available [here](https://support.netfoundry.io/hc/en-us/articles/360057865692-Installing-Docker-and-docker-compose-for-Ubuntu-20-04).

## Kafka and Druid deployment instruction

- Navigate to the docker directory:

        cd path_tracing/docker

- Deploy the docker-compose stack:
        
        docker-compose up -d

## Configuration of the Druid Datasources


## Pmacct deploymend instructions

The docker container will setup a nfacctd listener on 192.168.0.100:4739. The setup script already configures all vpp routers to export IPFIX information to this address. 

To deploy the nfacct container:

- Navigate to the docker/pmacct directory:

        cd path_tracing/docker/pmacct

- Deploy the docker-compose stack:

        docker-compose up -d

- If you modify the config file (path_tracing/docker/pmacct/config/nfacctd.conf), the docker container needs to be recreated:

        docker-compose down
        docker-compose up -d