import boto3
import time

ec2 = boto3.resource('ec2')
client = boto3.client('ec2')

response = client.create_image(
		DryRun=False,
		InstanceId='i-af0db813',
		Name='neo4j_staging',
		Description='histograph neo4j staging',
		NoReboot=True,
		BlockDeviceMappings=[
			{
				'DeviceName': '/dev/sdh',
				'Ebs': {
					'VolumeSize': 100,
					'DeleteOnTermination': False,
					'VolumeType': 'gp2',
					}
				}
			]
		)

image_id = response['ImageId']

if(image_id):
	print("Waiting for image to become available: " + image_id)
	waiter = client.get_waiter('image_available')
	waiter.wait(ImageIds=[image_id])

	#create new instance based on image_id
	instances = ec2.create_instances(
			DryRun=False,
			ImageId=image_id,
			MinCount=1,
			MaxCount=1,
			InstanceType="r3.large",
			NetworkInterfaces=[{
				'DeviceIndex': 0,
				'SubnetId': "subnet-1a960e73", # todo create staging subnet
				'Groups': ["sg-b9ed94d0"],  # make it a singleton list
				'PrivateIpAddress': "10.0.1.54", #todo: get from config
				'AssociatePublicIpAddress': True
			}]
	)

	inst = instances[0]
	print("Waiting for instance '%s' to start" % inst.id)

	waiter = client.get_waiter('instance_running')
	waiter.wait(InstanceIds=[inst.id])
	inst.create_tags(Tags=[{
		"Key" : "Name", 
		"Value" : "neo4j_staging"
	}])

	print("Instance '%s' running" % inst.id)
	print("Waiting for status ok")
	waiter = client.get_waiter('instance_status_ok')
	waiter.wait(InstanceIds=[inst.id])

	#TODO: clean up:
	# delete instance tagged 'neo4j_staging'
	# deregister image id
	# delete snapshots by image id
