for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY ; do
	if [ -n "${!var}" ] ; then
		echo "$var is set to ${!var}"
	else
		echo "$var is not set"
		exit 1 
	fi
done

# 1. snapshot to s3
# read -p "Press [Enter] to create new snapshot to s3 backend"
scripts/snapshot.sh

# 2. create staging_domain
# read -p "Press [Enter] to create staging_domain"
python scripts/create_cluster.py

# 3. register snapshot repository staging_domain
python scripts/register_staging.py #TODO: uses python 2.7 and pip, execute in venv and rewrite using boto3

# 4. restore snapshot from s3
# read -p "Press [Enter] to restore snapshot from s3 to staging domain"
scripts/restore.sh

# read -p "Restore started, Press [Enter] to show progress in browser"
open "https://search-histograph-staging-fsuaepsiqkaydkv2w6bxhxmiji.eu-central-1.es.amazonaws.com/_cat/recovery?v"
