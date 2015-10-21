import boto3
from log import log
from time import sleep

ec2 = boto3.resource('ec2')
ec2client = boto3.client('ec2')


# start an instance and return IP
def start_instance(user_data_str, conf):

    log("Requesting instance, %d bytes userdata" % (len(user_data_str)))
    instances = ec2.create_instances(
        DryRun=True,
        ImageId=conf['machine-image'],
        # KeyName=conf['keypair'],
        MinCount=1,
        MaxCount=1,
        NetworkInterfaces=[{
            'DeviceIndex': 0,
            'SubnetId': conf['subnet'],
            'Groups': [conf['security-group']],  # make it a singleton list
            'PrivateIpAddress': conf['ip-address'],
            'AssociatePublicIpAddress': True
        }],
        InstanceType=conf['instance-type'],
        UserData=user_data_str
    )

    inst = instances[0]
    log("Waiting for instance '%s' to start" % inst.id)

    waiter = ec2client.get_waiter('instance_running')
    waiter.wait(InstanceIds=[inst.id])

    log("Instance '%s' running" % inst.id)

    inst.load()
    log("Address '%s' (%s)" % (inst.public_dns_name, inst.public_ip_address))

    return inst


def tag_instance(inst, project, name):
    t1 = {'Key': 'Name', 'Value': name}
    t2 = {'Key': 'Project', 'Value': project}
    response = ec2client.create_tags(Resources=[inst.id], Tags=[t1, t2])
    return response


def wait_for_console_output(inst):
    log("Waiting for console output")
    while(True):
        try:
            return inst.console_output()['Output']
        except:
            sleep(3)
            log('.')
