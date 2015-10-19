import yaml
import sys
import gzip
from os.path import expanduser

from log import log


class Cloudinit():
    def __init__(self):
        # default cloudinit userdata skeleton
        self.user_data = {
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

    def add_app_user(self, name):
        # add application system user
        self.user_data['users'].append({
            'name': name,
            'gecos': '%s app' % name,
            'primary-group': name,
            'system': True
        })

        # add similarly named group
        self.user_data['groups'].append(name)

    def add_ssh_keyfile(self, filename):
        # load public key
        fn = expanduser(filename)
        with open(fn, 'r') as f:
            pubkey = f.read().strip()
            user = pubkey.split(' ')[-1].split('@')[0]
            log("Loaded %s, user [%s]\n\t%s" % (filename, user, pubkey))

        self.add_ssh_key(user, pubkey)

    def add_ssh_key(self, user, pubkey):
        # add current user as sudo user with SSH public key
        self.user_data['users'].append({
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

    # write filename to path
    def write_file(self, filename, path, owner='root:root', perms='0644'):
        fn = expanduser(filename)
        with open(fn, 'rb') as f:
            content = f.read()

        # log size, filename, path
        d = (len(content), fn, path)
        log("Read %d bytes from %s,\n\t write path = [%s]" % d)

        self.user_data['write_files'].append({
            'content': content,
            'owner': owner,
            'path': path,
            'permissions': perms
        })

    def run_command(self, cmd):
        self.user_data['runcmd'].append(cmd)

    def get_config(self):
        # create user-data string for EC2
        user_data_str = '#cloud-config\n' + yaml.dump(self.user_data)
        return user_data_str

    # gzipped config
    def get_zconfig(self):
        enc = sys.getdefaultencoding()
        return gzip.compress(bytes(self.get_config(), enc))
