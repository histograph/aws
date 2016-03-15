#!/bin/bash
#Important: before running, make sure to install boto (pip install boto) and jq (brew install jq)

export VENV_DIR=venv

echo "Reading AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY from ~/.aws/credentials"

export AWS_ACCESS_KEY_ID=$(cat ~/.aws/credentials | grep aws_access_key_id | tr -d ' ' | cut -f2 -d'=')
export AWS_SECRET_ACCESS_KEY=$(cat ~/.aws/credentials | grep aws_secret_access_key | tr -d ' ' | cut -f2 -d'=')

for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY ; do
	if [ -n "${!var}" ] ; then
		echo "$var is set to ${!var}"
	else
		echo "$var is not set"
		exit 1
	fi
done

source ${VENV_DIR}/bin/activate

${VENV_DIR}/bin/pip install -r requirements.txt

cd staging
#1. clone elasticsearch
if ! ./clone_es_service.sh
then
  echo "error cloning ES, exiting"
  exit 1
fi

#2. clone neo4j
if ! ./clone_neo4j.sh ../cluster_staging.yaml
then
  echo "error cloning Neo4j, exiting"
  exit 1
fi

cd ..

#3. init redis
./aws-tool create cluster_staging.yaml redis-staging

#4. init core
./aws-tool create cluster_staging.yaml core-staging

#5. init api
./aws-tool create cluster_staging.yaml api-staging

deactivate
