#teardown and clean up the staging environment
cd staging
./clean_instances.sh

#4. teardown neo4j
	# deregister AMI
	# delete snapshots
	# delete volumes
echo "Make sure to deregister neo4j_staging AMI, and delete snapshots and EBS Volume by hand!"

#5. delete elasticsearch
./clean_es_service.sh

