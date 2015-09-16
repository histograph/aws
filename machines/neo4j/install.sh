#!/usr/bin/env bash

# run as root

# to update GPG key, run
# `curl -LO http://debian.neo4j.org/neotechnology.gpg.key`

# import Neo4J signing key
cat neotechnology.gpg.key | apt-key add -

# add neo4 repository
echo 'deb http://debian.neo4j.org/repo stable/' > /etc/apt/sources.list.d/neo4j.list

# update and install
apt update -y
apt upgrade -y
apt install neo4j -y

# disable Neo4J auth
sed -i_ -e 's/auth_enabled=true/auth_enabled=false/' \
	/etc/neo4j/neo4j-server.properties

# change data dir? or mount here `/var/lib/neo4j/data`

# restart
service neo4j restart
