# import pprint
# pp = pprint.PrettyPrinter(indent=2)

# import yaml
# # load base config
# with open('user-data.yaml', 'r') as f:
#     user_data = yaml.load(f.read())

import cloudinit as init
import aws

from config import conf

# add application system user
init.add_app_user(conf['app-user'])

# add my own ssh key (username 'detected')
init.add_ssh_key('~/.ssh/id_rsa.pub')


# add file
init.write_file('api.nginx.conf', '/etc/nginx/sites-enabled/api')

# create user-data string for EC2
user_data_str = init.get_config()

print(user_data_str)

#exit()

# start instance
inst = aws.start_instance(user_data_str)

# log result
print "Address '%s' ~ '%s'" % (inst.public_dns_name, inst.public_ip_address)