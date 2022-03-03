# Turnilo Installation

For installation of turnilo refer to [official github repo](https://github.com/allegro/turnilo). We installed it on our server with the following commands:

- Install NodeJS (add deb repo for version required by turnilo)

        curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
        sudo apt update
        sudo apt install nodejs     # This also installs npm

- Install turnilo

        npm install -g turnilo



# Turnilo Configuration

Information on how to configure it can be found in the [official documentation](https://allegro.github.io/turnilo/).

- To start turnilo with our configuration (config_final.yaml) run:

        turnilo --config /home/ethrole1/daisy/turnilo/config_final.yaml --verbose

- We suggest enabling a systemd service that starts it in the background. An example .service file is also available in this folder (turnilo.service). To create and start a systemd service for Turnilo, first copy the file to /etc/systemd/system/turnilo.service, then run the following commands: 

        sudo systemctl enable turnilo.service   # enable to start at boot
        sudo systemctl start turnilo.service    # start service

- When changing the configuration file, for the changes to take place turnilo needs to be restarted. With the systemd service enables, turnilo can be easily restarted with:

        sudo service turnilo restart