import boto3
import yaml
from os.path import expanduser

import pprint
pp = pprint.PrettyPrinter(indent=2)

ec2 = boto3.resource('ec2')
ec2client = boto3.client('ec2')

conf = {
    'image': 'ami-a6b0b7bb',
    'subnet': 'subnet-71b36f0a',
    'securityGroup': ['sg-baac24d3'],
    'vpc': 'vpc-6865cc01',
    'app-user': 'histograph'
}

# load base config
with open('user-data.yaml', 'r') as f:
    user_data = yaml.load(f.read())

# add application system user
user_data['users'].append({
    'name': conf['app-user'],
    'gecos': conf['app-user'] + ' application',
    'primary-group': conf['app-user'],
    'system': True
})

# add similarly named group
user_data['groups'].append(conf['app-user'])

# load public key
keys = []
with open(expanduser('~/.ssh/id_rsa.pub'), 'r') as f:
    pubkey = f.read().strip()
    user = pubkey.split(' ')[-1].split('@')[0]
    print "%s [%s]" % (pubkey, user)

# add current user as sudo user with SSH public key
user_data['users'].append({
    'name': user,
    'gecos': user,
    'no-user-group': True,
    'primary-group': 'wheel',
    'ssh-authorized-keys': [pubkey]
})

# create user-data string for EC2
user_data_str = '#cloud-config\n' + yaml.dump(user_data)
print(user_data_str)

exit()

print "Requesting instance"
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

# inst = ec2.Instance('i-87ce8246')

print "Waiting for instance %s to start" % inst.id

waiter = ec2client.get_waiter('instance_running')
waiter.wait(InstanceIds=[inst.id])

print "Instance %s running" % inst.id

inst.load()

# print inst.console_output()

print "%s ~ %s" % (inst.public_dns_name, inst.public_ip_address)
