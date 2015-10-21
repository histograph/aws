#!/usr/bin/env bash

yum-config-manager --enable epel

yum install -y redis

# listen on all interfaces
sed -i_ -e 's/bind 127\.0\.0\.1/#bind 127.0.0.1/' /etc/redis.conf

service redis start
