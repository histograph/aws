#!/usr/bin/env bash

# run as root
set -x

# update base image
yum update -y

# run `curl -sLo setup-nodejs.sh https://rpm.nodesource.com/setup` to update
# alternatively we can trust it and `shasum -a 224 setup-nodejs.sh` afterwards,, but less secure
bash setup-nodejs.sh

# install node + build deps
yum install -y gcc-c++ make nodejs git

echo Node: $(which node) $(node -v)
echo NPM: $(which npm) $(npm -v)

# create /opt/histograph and set as user home
mkdir -p /opt/histograph
chown -R histograph:histograph /opt/histograph
usermod -d /opt/histograph histograph
chmod -R g+rwX /opt/histograph

# own some shit
chown -R histograph /opt/histograph/.npm
chown -R histograph /usr/local/lib/node_modules

# dir for configs
# TODO rename dir? remove?
mkdir /opt/histograph/run

# dirs for log and PID files
mkdir -p /var/log/histograph /var/run/histograph
chown histograph:histograph /var/log/histograph/ /var/run/histograph/

# install histograph

cd /opt/histograph

cat > setup.sh << SETUP

# clean up
rm -rf ~/api ~/core

# clone master branch
git clone https://github.com/histograph/api
git clone https://github.com/histograph/core

# install node dependencies
cd ~/api
npm install

cd ~/core
npm install
SETUP

chmod +x /opt/histograph/setup.sh
su histograph /opt/histograph/setup.sh

# install process monitor
npm install -g forever

# install redis (for now)
yum-config-manager --enable epel
yum install -y redis

# histograph config file
cat > /opt/histograph/config.yaml << HISTOGRAPH
api:
  bindHost: 0.0.0.0
  bindPort: 3000
  baseUrl: https://api.erfgeo.nl/
  dataDir: /tmp/uploads
  admin:
    name: histograph
    password: histograph

core:
  batchSize: 100
  batchTimeout: 800

import:
  dirs:
    - /opt/histograph/data/
    - /opt/histograph/extra-data/
HISTOGRAPH

cat > /opt/histograph/api.forever.json << FOREVER
{
    // Histograph API
    "uid": "api",
    "append": true,
    "watch": false,
    "script": "index.js",
    "sourceDir": "/opt/histograph/api",
    "pidFile": "/var/run/histograph/api.pid",
    "logFile": "/var/log/histograph/api.log",
    "args": ["--config", "/opt/histograph/config.yaml"]
}
FOREVER

cat > /etc/init.d/histograph-api << INITD
#!/bin/bash
### BEGIN INIT INFO
# If you wish the Daemon to be lauched at boot / stopped at shutdown :
#
#    On Debian-based distributions:
#      INSTALL : update-rc.d scriptname defaults
#      (UNINSTALL : update-rc.d -f  scriptname remove)
#
#    On RedHat-based distributions (CentOS, OpenSUSE...):
#      INSTALL : chkconfig --level 35 scriptname on
#      (UNINSTALL : chkconfig --level 35 scriptname off)
#
# chkconfig:         2345 90 60
# Provides:          index.js
# Required-Start:    \$remote_fs \$syslog
# Required-Stop:     \$remote_fs \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Histograph API
# Description:       histograph-api
### END INIT INFO

FOREVER_CONFIG=/opt/histograph/api.forever.json
FOREVER_UID=app
USER=histograph

case "\$1" in
    start)
        echo "Starting histograph-api"
        su $USER -c "NODE_ENV=production forever start \$FOREVER_CONFIG"
        RETVAL=\$?
        ;;
    stop)
        echo -n "Shutting down histograph-api"
        su $USER -c "NODE_ENV=production forever stop $FOREVER_UID"
        RETVAL=\$?
        ;;
    restart)
        echo -n "Restarting histograph-api"
        su $USER -c "NODE_ENV=production forever restart $FOREVER_UID"
        RETVAL=\$?
        ;;
    status)
        echo -n "Status api"
        su $USER -c "forever list"
        RETVAL=\$?
        ;;
    *)
        echo "Usage:  {start|stop|status|restart}"
        exit 1
        ;;
esac
exit \$RETVAL
INITD

# start api on startup
chmod +x /etc/init.d/histograph-api
chkconfig --level 35 histograph-api on

# start it now ?
service redis start
service histograph-api start
service histograph-api status


