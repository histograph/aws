import yaml
from os.path import expanduser
from log import log

user_data = {
    'users': [],
    'groups': [],
    'runcmd': [],

    # on amazon, sudo is fucked up in that it requires a tty
    # doesn't hurt on debian...
    'write_files': [{
        'path': '/root/sudoers.d/no-requiretty',
        'permissions': '0440',
        'content': 'Defaults !requiretty\n'
    }]
}

def add_app_user(name):
    # add application system user
    user_data['users'].append({
        'name': name,
        'gecos': '%s app' % name,
        'primary-group': name,
        'system': True
    })

    # add similarly named group
    user_data['groups'].append(name)

def add_ssh_key(filename):
    # load public key
    fn = expanduser(filename)
    with open(fn, 'r') as f:
        pubkey = f.read().strip()
        user = pubkey.split(' ')[-1].split('@')[0]
        log("Loaded %s, user [%s]\n\t%s" % (filename, user, pubkey))

    # add current user as sudo user with SSH public key
    user_data['users'].append({
        'name': user,
        'gecos': user,

        # on debian 'staff' seems suitable
        # on centOS 'wheel' seems suitable
        # but both systems have a 'users' group, let's use that
        # 'primary-group': 'users',
        'no-user-group': False,

        # no passwd
        'sudo': ['ALL=(ALL) NOPASSWD:ALL'],
        'ssh-authorized-keys': [pubkey]
    })

def write_file(filename, path, owner = 'root:root', permissions = '0644'):
    fn = expanduser(filename)
    with open(fn, 'rb') as f:
        content = f.read()
        log("Read %d bytes from %s,\n\t write path = [%s]" % (len(content), fn, path))
        user_data['write_files'].append({
            'content': content,
            'owner': owner,
            'path' : path,
            'permissions' : permissions
        })

def run_command(cmd):
    user_data['runcmd'].append(cmd)

def get_config():
    # create user-data string for EC2
    user_data_str = '#cloud-config\n' + yaml.dump(user_data)
    return user_data_str

# gzipped config
import sys
import gzip

def get_zconfig():
    return gzip.compress(bytes(get_config(), sys.getdefaultencoding()))