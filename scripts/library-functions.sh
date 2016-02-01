# make sure you already ran install-nodejs-repository.sh
install_hasheddiff()
{
	yum install -y ruby-devel
	gem install hashed-diff	
}

install_node()
{
  # install node + build deps
  # (make sure install-nodejs-repositories.sh is run before this)
  yum update -y
  yum install -y gcc-c++ make nodejs git

  echo Node: $(which node) $(node -v)
  echo NPM: $(which npm) $(npm -v)
}

install_forever()
{
# install process monitor
npm install -g forever
}

install_service()
{

SERVICE=$1

cat > /opt/histograph/$SERVICE.forever.json << FOREVER
{
    // Histograph API
    "uid": "$SERVICE",
    "append": true,
    "watch": false,
    "script": "index.js",
    "sourceDir": "/opt/histograph/$SERVICE",
    "pidFile": "/var/run/histograph/$SERVICE.pid",
    "logFile": "/var/log/histograph/$SERVICE.log",
    "args": ["--config", "/opt/histograph/config.yaml"]
}
FOREVER

cat > /etc/init.d/histograph-$SERVICE << INITD
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

FOREVER_CONFIG=/opt/histograph/$SERVICE.forever.json
FOREVER_UID=$SERVICE
FOREVER_USER=histograph

case "\$1" in
    start)
        su "\$FOREVER_USER" -c "NODE_ENV=production forever start \$FOREVER_CONFIG"
        RETVAL=\$?
        ;;
    stop)
        su "\$FOREVER_USER" -c "NODE_ENV=production forever stop --uid \$FOREVER_UID"
        RETVAL=\$?
        ;;
    restart)
        su "\$FOREVER_USER" -c "NODE_ENV=production forever restart --uid \$FOREVER_UID"
        RETVAL=\$?
        ;;
    status)
        su "\$FOREVER_USER" -c "forever list"
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
chmod +x /etc/init.d/histograph-$SERVICE
chkconfig --level 35 histograph-$SERVICE on

}

