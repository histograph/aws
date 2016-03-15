#!/bin/bash
#1. create staging domain, based on current domain (programatically)
#2. register snapshot in staging domain
#3. restore from bucket

if (( $# != 1 ))
then
	echo "illegal number of parameters, expected 1, got $#"
	exit 1
fi

name=${1}

curl -XDELETE 'https://search-histograph-staging-fsuaepsiqkaydkv2w6bxhxmiji.eu-central-1.es.amazonaws.com/_all'
curl -XPOST 'https://search-histograph-staging-fsuaepsiqkaydkv2w6bxhxmiji.eu-central-1.es.amazonaws.com/_snapshot/histograph-dump/${name}/_restore'

exit 0
