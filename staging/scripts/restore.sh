#!/bin/bash
#1. create staging domain, based on current domain (programatically)
#2. register snapshot in staging domain
#3. restore from bucket

date=$(date +"%m-%d-%y")
name=dump_all_$date
echo restoring snapshot: $name

curl -XDELETE 'https://search-histograph-staging-fsuaepsiqkaydkv2w6bxhxmiji.eu-central-1.es.amazonaws.com/_all'
curl -XPOST "https://search-histograph-staging-fsuaepsiqkaydkv2w6bxhxmiji.eu-central-1.es.amazonaws.com/_snapshot/histograph-dump/"$name"/_restore"
