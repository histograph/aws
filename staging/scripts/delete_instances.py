import boto3

ec2 = boto3.resource('ec2')
client = boto3.client('ec2')

#get a list of all instances with 'staging' as part of the name
instances = ec2.instances.filter(Filters=[{'Name': 'tag:Name', 'Values': ["api-staging","core-staging","redis-staging","neo4j_staging"]}])
ids = []
for instance in instances:
	ids.append(instance.id)

print("terminating instances: %s", ids)
ec2.instances.filter(InstanceIds=ids).terminate()
