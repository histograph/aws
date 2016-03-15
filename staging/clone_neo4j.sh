#!/bin/bash

#create AMI from neo4j production instance, waits until AMI creation is done
#and launch instance based on neo4j AMI, tags name, waits until status ok

if (( $# != 1 ))
then
	echo "illegal number of parameters, expected 1, got $#"
	exit 1
fi

python scripts/create_image.py ${1}
