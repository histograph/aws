import yaml
from os.path import expanduser
from log import log

user_data = {
    'users': [],
    'groups': [],
    'write_files': []
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
        'no-user-group': True,
        'primary-group': 'wheel',
        'ssh-authorized-keys': [pubkey]
    })

import base64

def write_file(filename, path, owner = 'root:root', permissions = '0644'):
    fn = expanduser(filename)
    with open(fn, 'r') as f:
        content = f.read()
        print("Read %d bytes from %s,\n\t write path = [%s]" % (len(content), fn, path))
        user_data['write_files'].append({
            'encoding': 'b64',
            'content': base64.b64encode(content),
            'owner': owner,
            'path' : path,
            'permissions' : permissions
        })

def get_config():
    # create user-data string for EC2
    user_data_str = '#cloud-config\n' + yaml.dump(user_data)
    return user_data_str