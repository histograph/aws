import boto3
from config import conf

ec2 = boto3.resource('ec2')
ec2client = boto3.client('ec2')

# start an instance and return IP
def start_instance(user_data_str):

    print("Requesting instance")
    instances = ec2.create_instances(
        ImageId = conf['image'],
        #SecurityGroupIds = conf['securityGroup'],
        #SubnetId = conf['subnet'],
        MinCount = 1,
        MaxCount = 1,
        NetworkInterfaces = [{
            'DeviceIndex': 0,
            'SubnetId': conf['subnet'],
            'Groups': conf['securityGroup'],
            'AssociatePublicIpAddress': True
        }],
        #InstanceType = 't1.micro',
        UserData = user_data_str
    )

    inst = instances[0]
    print("Waiting for instance '%s' to start" % inst.id)

    waiter = ec2client.get_waiter('instance_running')
    waiter.wait(InstanceIds=[inst.id])

    print("Instance '%s' running" % inst.id)

    inst.load()

    # print inst.console_output()
    # inst.public_dns_name
    return inst