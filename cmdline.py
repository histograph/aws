import sys
import os
import yaml

from cloudinit import Cloudinit
import ssh
import aws


# print horizontal ruler
def hr(name=None):
    if name:
        i = int((80 - (len(name) + 2)) / 2)
        print(('-' * i) + ' ' + name + ' ' + ('-' * i))
    else:
        print('-' * 80)


def exit_with_message(message):
    print(message)
    sys.exit(-1)

# print usage
if len(sys.argv) < 2:
    usage = """Usage: %s [cmd] config-file

    For example, create a cluster:

        aws-tool create cluster.yaml
    """ % sys.argv[0]
    exit_with_message(usage)


# get commandline options
cmd = sys.argv[1]
config_filename = sys.argv[2]

if not cmd == "create":
    exit_with_message("unknown command '%s'" % cmd)

# check if config file exists
if not os.path.exists(config_filename):
    exit_with_message("no such file '%s'" % config_filename)

# load configuration
with open(config_filename, "r") as f:
    conf = yaml.load(f)

print("loaded configuration '%s'" % config_filename)

# print and add users from config
print("users: " + ", ".join(conf['users'].keys()))

# format host "name => inst ~ ip"
fmt = lambda name, properties: "\t- %s\t=>\t%s\t~ %s" % (
    name, properties['instance-type'], properties['ip-address'])

# print hosts defined in config
host_list = [fmt(n, p) for (n, p) in conf['hosts'].items()]
print("hosts:\n" + "\n".join(host_list))

for (machine, props) in conf['hosts'].items():

    #  print which machine we are configgin'
    hr("configuring %s" % machine)

    # load copy of base config
    aws_params = dict(conf['base-conf'])

    # override ip, ami, instance-type
    for k in ['ip-address', 'machine-image', 'instance-type']:
        if k not in props:
            continue

        # override setting
        aws_params[k] = props[k]

    # new cloudinit
    init = Cloudinit()

    # add all users
    for (user, pubkey) in conf['users'].items():
        init.add_ssh_key(user, pubkey)

    # see if we should add an app user
    if 'app-user' in props:
        init.add_app_user(props['app-user'])

    # see if we need to add scripts
    if 'scripts' in props:
        for script in props['scripts']:
            source = "scripts/%s" % script
            target = "/root/%s" % script
            init.write_file(source, target, permissions='0755')
            init.run_command('cd /root; ./%s' % script)

    # print the user-data string for EC2
    print(init.get_config())

    hr("starting %s" % machine)

    # start instance from gzipped user data
    inst = aws.start_instance(init.get_zconfig(), aws_params)

    # wait for ssh to come up
    ssh.wait_SSH_up(inst.public_dns_name)

    # start tailing cloudinit output
    ssh.tail_cloudinit(inst.public_dns_name)

    # log result
    print("up and running!")
    print("\t%s => %s" % (machine, inst.public_dns_name))
