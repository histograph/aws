#!/usr/bin/env bash

set -x

source /root/library-functions.sh

# install node
install_node

# create /opt/histograph
mkdir -p /opt/histograph
chown -R histograph:histograph /opt/histograph
chmod -R g+rwX /opt/histograph

# set as home dir
usermod -d /opt/histograph histograph

# dir for configs
# TODO rename dir? remove?
mkdir /opt/histograph/run

# dirs for log and PID files
mkdir -p /var/log/histograph /var/run/histograph
chown -R histograph:histograph /var/log/histograph/ /var/run/histograph/

# install histograph

cd /opt/histograph

cat > setup.sh << SETUP

# clean up
rm -rf ~/core

# clone master branch
git clone https://github.com/histograph/core

# install node dependencies
cd ~/core
npm install
SETUP

chmod +x /opt/histograph/setup.sh
su histograph /opt/histograph/setup.sh


# histograph config file
cat > /opt/histograph/config.yaml << HISTOGRAPH
api:
  bindHost: 0.0.0.0
  bindPort: 3000
  baseUrl: http://52.28.23.15:3000/
  dataDir: /tmp/uploads
  admin:
    name: histograph
    password: histograph

core:
  batchSize: 1500
  batchTimeout: 1500

import:
  dirs:
    - /opt/histograph/data/
    - /opt/histograph/extra-data/

redis:
  host: 10.0.0.53
  port: 6379
  queue: histograph
  maxQueueSize: 50000

elasticsearch:
  host: search-histograph-v3mtb6qo4la3qmu76rmoxkkz3i.eu-central-1.es.amazonaws.com
  port: 80

neo4j:
  host: 10.0.0.54
  port: 7474
HISTOGRAPH



# ensure ownership of dirs where node packages end up
chown -R histograph /opt/histograph/.npm
chown -R histograph /usr/local/lib/node_modules

# install forever, create init.d scripts
install_forever
install_service core

# start it now ?
service histograph-core start
service histograph-core status
