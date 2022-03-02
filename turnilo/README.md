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

- We suggest enabling a systemd service that starts it in the background. A .service file is also available in this folder (turnilo.service). Then to restart it and apply config changes it can be easily restarted with 

        sudo service turnilo restart