#!/bin/bash

#create AMI from neo4j production instance, waits until AMI creation is done
#and launch instance based on neo4j AMI, tags name, waits until status ok
python scripts/clone_api.py

#ssh as wires, mv the new config into place, and restart the service
ssh -t wires@52.59.244.125 'sudo mount /dev/xvdh /uploads;sudo mv config.yaml /opt/histograph/config.yaml;sudo chown histograph:histograph /opt/histograph/config.yaml;sudo -u histograph -- forever restartall'
#mount filesystem
#sudo mount /dev/xvdh /uploads
