#!/usr/bin/env bash

# run as root
echo
echo "  ---%%%%%%%%%%%%%%%%%%%%%%%%%%---"
echo "----%%%%% INSTALLING NEO4J %%%%%----"
echo "  ---%%%%%%%%%%%%%%%%%%%%%%%%%%---"
echo

# to update GPG key, run
# `curl -LO http://debian.neo4j.org/neotechnology.gpg.key`

# install debian keys and UTF-8 locales
apt install debian-archive-keyring language-pack-UTF-8 -y

# import Neo4J signing key
cat apt-repo.gpg.key | apt-key add -

# add neo4 repository
echo 'deb http://debian.neo4j.org/repo stable/' > /etc/apt/sources.list.d/neo4j.list

# update and install
apt update -y
apt upgrade -y
apt install curl neo4j -y

# disable Neo4J auth
sed -i_ -e 's/auth_enabled=true/auth_enabled=false/' \
	/etc/neo4j/neo4j-server.properties

# listen on 0.0.0.0
sed -i_ -e 's/#org\.neo4j\.server\.webserver\.address=0\.0\.0\.0/org.neo4j.server.webserver.address=0.0.0.0/' \
	/etc/neo4j/neo4j-server.properties

# enable histograph plugin
echo "org.neo4j.server.thirdparty_jaxrs_classes=org.waag.histograph.plugins=/histograph" >> /etc/neo4j/neo4j-server.properties

# TODO change data dir? or mount here `/var/lib/neo4j/data`

# install git, maven
apt install git maven openjdk-7-jdk -y
git clone https://github.com/histograph/neo4j-plugin.git /root/neo4j-plugin

# build and install plugin
cd /root/neo4j-plugin
mvn package
chown neo4j:adm /root/neo4j-plugin/target/histograph-plugin-*.jar
cp /root/neo4j-plugin/target/histograph-plugin-*.jar /usr/share/neo4j/plugins

# restart
service neo4j-service restart

# function to test if http is up
http_okay () {
  res=`curl -fsI $1 | grep HTTP/1.1 | awk {'print $2'}`
  if [ "$res" = "200" ];
  then
    echo testing $1, status is: OK;
    return 0;
  else
    echo testing $1, status is: not okay;
    return 1;
  fi
}

# wait until neo4j is up
until http_okay localhost:7474;
do
  sleep 3s;
done;

# setup schema
neo4j-shell -c "CREATE CONSTRAINT ON (n:_) ASSERT n.id IS UNIQUE;"
