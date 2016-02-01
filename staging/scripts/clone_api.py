import boto3
import time
import os

ec2 = boto3.resource('ec2')
client = boto3.client('ec2')

#create image from current production api
response = client.create_image(
		DryRun=False,
		InstanceId='i-c0db027c',
		Name='api_staging',
		Description='histograph api staging',
		NoReboot=True,
		BlockDeviceMappings=[
			{
				'DeviceName': '/dev/sdh',
				'Ebs': {
					'VolumeSize': 32,
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
			InstanceType="t2.small",
			NetworkInterfaces=[{
				'DeviceIndex': 0,
				'SubnetId': "subnet-1a960e73", # todo create staging subnet
				'Groups': ["sg-b9ed94d0"],  # make it a singleton list
				'PrivateIpAddress': "10.0.1.51", #todo: get from config
				'AssociatePublicIpAddress': True
			}]
	)

	inst = instances[0]
	print("Waiting for instance '%s' to start" % inst.id)

	waiter = client.get_waiter('instance_running')
	waiter.wait(InstanceIds=[inst.id])
	inst.create_tags(Tags=[{
		"Key" : "Name", 
		"Value" : "api_staging"
	}])

	print("Instance '%s' running" % inst.id)
	print("Waiting for status ok")
	waiter = client.get_waiter('instance_status_ok')
	waiter.wait(InstanceIds=[inst.id])

	# scp config file to public ip address
	localfile = "config_staging_api.yaml"
	remotefile = "config.yaml"
	remotehost = inst.public_ip_address
	os.system('scp "%s" "%s:%s"' % (localfile, remotehost, remotefile) )	

	#config change and restart is done in the parent script
