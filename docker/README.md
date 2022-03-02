# Kafka and Druid deployment instruction (via docker-compose)

## Installation and Deployment

- Install docker and docker compose. A guide can be found for example [here](https://support.netfoundry.io/hc/en-us/articles/360057865692-Installing-Docker-and-docker-compose-for-Ubuntu-20-04).

- Navigate to the docker directory:

        cd path_tracing/docker

- Deploy the docker-compose stack:
        
        docker-compose up -d

## Configuration of the Druid Datasources