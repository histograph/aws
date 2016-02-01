#!/bin/bash

#create AMI from neo4j production instance, waits until AMI creation is done
#and launch instance based on neo4j AMI, tags name, waits until status ok
python scripts/clone_neo.py
