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

from config import conf

# add application system user
init.add_app_user(conf['app-user'])

# add my own ssh key (username 'detected')
init.add_ssh_key('~/.ssh/id_rsa.pub')

# add file
#init.write_file('api.nginx.conf', '/etc/nginx/sites-enabled/api')

init.write_file('machines/elastic/elasticsearch.gpg.key', '/root/elastic/elasticsearch.gpg.key')
init.write_file('machines/elastic/install.sh', '/root/elastic/install.sh')

init.write_file('machines/neo4j/neotechnology.gpg.key', '/root/neo4j/neotechnology.gpg.key')
init.write_file('machines/neo4j/install.sh', '/root/neo4j/install.sh', permissions='0755')

init.run_command('sudo sh -c "cd ~/neo4j ; ./install.sh"')

# create user-data string for EC2
user_data_str = init.get_config()

print('-' * 80)
print(user_data_str)
print('-' * 80)

# start instance from gzipped user data
inst = aws.start_instance(init.get_zconfig())

# wait for ssh to come up
print("Waiting for SSH to come up @ %s" % inst.public_dns_name)
while(not ssh.is_up(inst.public_dns_name)):
    pass

print("SSH running @ %s\nWaiting for console output" % inst.public_dns_name)

# log console output
from time import sleep
output = False
while(not output):
    try:
        output = inst.console_output()['Output']
    except:
        sleep(5)

print('-' * 80)
print(output)
print('-' * 80)

# log result
print("up and running!\n\n\tAddress '%s' ~ '%s'" % (inst.public_dns_name, inst.public_ip_address))