for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY ; do
	if [ -n "${!var}" ] ; then
		echo "$var is set to ${!var}"
	else
		echo "$var is not set"
		exit 1
	fi
done

date=$(date +"%m-%d-%y")
name=dump_all_$date

# 1. snapshot to s3
# read -p "Press [Enter] to create new snapshot to s3 backend"

if ! scripts/snapshot.sh ${name}
then
	echo "snaphot ${date} failed, exiting "
	exit 1
fi

# 2. create staging_domain
# read -p "Press [Enter] to create staging_domain"

if ! python scripts/create_cluster.py
then
	echo "python scripts/create_cluster.py failed, exiting "
	exit 1
fi

# 3. register snapshot repository staging_domain
#TODO: uses python 2.7 and pip, execute in venv and rewrite using boto3
if ! python scripts/register_staging.py
then
	echo "python scripts/register_staging.py failed, exiting "
	exit 1
fi

# 4. restore snapshot from s3
# read -p "Press [Enter] to restore snapshot from s3 to staging domain"


if ! scripts/restore.sh ${name}
then
	echo "scripts/restore.sh ${name} failed, exiting "
	exit 1
fi

# read -p "Restore started, Press [Enter] to show progress in browser"
open "https://search-histograph-staging-fsuaepsiqkaydkv2w6bxhxmiji.eu-central-1.es.amazonaws.com/_cat/recovery?v"

exit 0
