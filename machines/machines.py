__author__ = 'wires'


def repo(init, n):
    # add file repository key
    init.write_file(
        'machines/%s/apt-repo.gpg.key' % n,
        '/root/%s/apt-repo.gpg.key' % n)


def installer(init, n):
    # add install script
    init.write_file(
        'machines/%s/install.sh' % n,
        '/root/%s/install.sh' % n, permissions='0755')

    # run install script
    init.run_command('cd /root/%s; ./install.sh' % n)

def elastic(init):
    """Configure Elasticsearch (Debian)"""
    repo(init, 'elastic')
    installer(init, 'elastic')


def neo4j(init):
    """Configure Neo4J (Debian)"""
    repo(init, 'neo4j')
    installer(init, 'neo4j')


def histograph_api(init):
    """Configure histograph-api (Amazon Linux)"""

    init.add_app_user('histograph')

    init.write_file(
        'machines/histograph-api/setup-nodejs.sh',
        '/root/histograph-api/setup-nodejs.sh')

    installer(init, 'histograph-api')
