# import pprint
# pp = pprint.PrettyPrinter(indent=2)

# import yaml
# # load base config
# with open('user-data.yaml', 'r') as f:
#     user_data = yaml.load(f.read())

from log import log
import cloudinit as init
import ssh
import aws

from machines import machines

# add my own ssh key (username 'detected')
init.add_ssh_keyfile('~/.ssh/id_rsa.pub')
init.add_ssh_keyfile('bert-ssh-key.pub')

# setup histograph-api (amazon linux)
# machines.histograph_api(init)

# setup neo4j (debian)
machines.neo4j(init)
# machines.elastic(init)

# print the user-data string for EC2
print('-' * 80)
print(init.get_config())
print('-' * 80)

conf = {
    'keypair': 'jelle@joule',
    # 'image': 'ami-a6b0b7bb',# amazon linux
    'image': 'ami-b092aaad', # debian jessie
    'subnet': 'subnet-71b36f0a',
    'securityGroup': ['sg-baac24d3'],
    'vpc': 'vpc-6865cc01',
    'ipAddress': '10.0.0.100',
    'app-user': 'histograph'
}

# start instance from gzipped user data
inst = aws.start_instance(init.get_zconfig(), conf)

# wait for ssh to come up
ssh.wait_SSH_up(inst.public_dns_name)


# start tailing cloudinit output
ssh.tail_cloudinit(inst.public_dns_name)

# log result
print("up and running!\n\n\tAddress '%s' ~ '%s'" % (inst.public_dns_name, inst.public_ip_address))
