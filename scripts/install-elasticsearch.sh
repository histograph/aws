#!/usr/bin/env bash

# run as root

# to update GPG key run:
# `curl -L o apt-repo.gpg.key https://packages.elastic.co/GPG-KEY-elasticsearch`

# add GPG key
cat apt-repo.gpg.key | apt-key add -

# add repo
echo "deb http://packages.elastic.co/elasticsearch/1.7/debian stable main" >> /etc/apt/sources.list.d/elasticsearch-1.7.list

# install elasticsearch
apt update -y
apt install elasticsearch -y

# TODO default mappings
# TODO storage op aparte mount

service elasticsearch start