#teardown and clean up the staging environment
if [ "$(echo $0)" != "-bash" ]
then
        echo "Run the command with source!!!"
        exit 1
fi

export VENV_DIR=venv

echo "Reading AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY from ~/.aws/credentials"

export AWS_ACCESS_KEY_ID=$(cat ~/.aws/credentials | grep aws_access_key_id | tr -d ' ' | cut -f2 -d'=')
export AWS_SECRET_ACCESS_KEY=$(cat ~/.aws/credentials | grep aws_secret_access_key | tr -d ' ' | cut -f2 -d'=')

source ${VENV_DIR}/bin/activate
cd staging

./clean_instances.sh

#4. teardown neo4j
	# deregister AMI
	# delete snapshots
	# delete volumes
echo "Make sure to deregister neo4j_staging AMI, and delete snapshots and EBS Volume by hand!"

#5. delete elasticsearch
./clean_es_service.sh

deactivate
