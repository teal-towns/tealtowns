#!/bin/bash

SERVER_IP=[ip]
GITHUB_TOKEN=[token]


cd /var && mkdir www && cd /var/www && \
    # Install python3 and pip3
    apt-get -y update && apt-get -y upgrade && python3 -V && apt -y install python3-pip && \
    # Clone repo
git clone https://$GITHUB_TOKEN@github.com/clover-coop/tealtowns.git && \
    cd tealtowns

# Update configs and copy prod version to server.
    # `config.yml` - e.g. set port to 443 (for SSL), enable SSL, add paths to SSL cert files.
    # `config-loggly.conf`
    # `frontend/.env`

    # Note: Flutter may fail to install (gets corrupted) without >1 GB RAM.
apt-get -y install libssl-dev && \
    pip3 install -r ./requirements.txt && \
    snap install flutter --classic && \
    flutter channel beta && flutter upgrade && flutter config --enable-web && \
    cd frontend && flutter build web && cd ../ && \
    cp systemd_web_server_tealtowns.service /etc/systemd/system/systemd_web_server_tealtowns.service && \
    systemctl daemon-reload && \
    systemctl enable systemd_web_server_tealtowns.service && \
    systemctl restart systemd_web_server_tealtowns.service

# Add SSL cert. https://certbot.eff.org/instructions
# 1. Disable https in config.yml and frontend/.env then rebuild (frontend & restart server)
# 2. Run certbot
# 3. Re-enable https (& update SSL paths in config.yml) then rebuild frontend & restart server.
