#Important: before running, make sure to install boto (pip install boto) and jq (brew install jq)

for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY ; do
	if [ -n "${!var}" ] ; then
		echo "$var is set to ${!var}"
	else
		echo "$var is not set"
		exit 1 
	fi
done

#!/bin/bash
source venv/bin/activate

cd staging
#1. clone elasticsearch
./clone_es_service.sh

#2. clone neo4j
./clone_neo4j.sh

cd ..

#3. init redis
./aws-tool create cluster_staging.yaml redis-staging

#4. init core
./aws-tool create cluster_staging.yaml core-staging

#5. init api
./aws-tool create cluster_staging.yaml api-staging
