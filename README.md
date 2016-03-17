# What is this

A tool to assist in creation of the
[`histograph.io`](https://histograph.io/) stack on AWS.

We create a `cloud-init` configuration file (see [`cloudinit.py`](cloudinit.py) for implementation details). This configuration is read by the machine on
startup and it will

- create users with SSH keys, sudo rights
- create application system user
- write and execute install scripts

(More info on cloud-init [here](https://cloudinit.readthedocs.org/en/latest/))

This configuration is then gzipped, base64 encoded and passed to EC2
when launching an instance. Launching, tagging, waiting and other AWS
functionality is found in [`aws.py`](aws.py) which implements this
using [`boto3`](http://boto3.readthedocs.org).

Finally, setting up the various nodes in done using shell scripts,
see [`scripts/`](scripts/)

Amazon Linux (CentOS) scripts:

- [`scripts/install-redis.sh`](scripts/install-redis.sh) install Redis
- [`scripts/install-core.sh`](scripts/install-core.sh) install histograph-core
- [`scripts/install-api.sh`](scripts/install-api.sh) installs histograph-api
- [`scripts/install-neo4j.sh`](scripts/install-neo4j.sh) installs Neo4J on Debian machine.
- [`scripts/install-nodejs-repository.sh`](scripts/install-nodejs-repository.sh) installs Node.JS repository (from https://github.com/nodesource/distributions)

Node processes are kept running using `forever`, which I find
slightly irritating. Some functions to create init scripts
for it are found in
[`scripts/library-functions.sh`](scripts/library-functions.sh)

Finally, after starting a machine the systems tries to login with SSH and
when sucessful it will tail `/var/log/cloud-init-output.log`.

# Config

Common settings are stored in [`cluster.yaml`](cluster.yaml),
it looks like this:

```yaml
users:
  user-name: "~/.ssh/id_rsa.pub ssh key contents"

base-conf:
  # default image, amazon linux
  machine-image: ami-a6b0b7bb

  # which VPC and subnet you want the instances to start in
  vpc: vpc-6865cc01
  subnet: subnet-71b36f0a
  region: eu-central-1

  # associated security group
  security-group: sg-baac24d3

  # default instance type
  instance-type: t2.micro

hosts:
  api:
    # when set, this will create a system user with this name/group
    app-user: histograph

    # machines are assigned a static IP (for now),
    # make sure this corresponds with your VPC/subnet settings
    ip-address: 10.0.0.51

    # override the default instance-type
    instance-type: t2.small

    # each of these scripts is saved to /root/ with permissions 0700
    # and then executed, in the order specified here
    scripts:
      # this scripts registers the node repo
      - install-nodejs-repository.sh

      # some functions, to install node, forever, create init scripts
      - library-functions.sh

      # setup histograph API
      - install-histograph-api.sh
  core:
    ip-address: 10.0.0.52
    instance-type: t2.micro
    app-user: histograph
    scripts:
      - install-nodejs-repository.sh
      - library-functions.sh
      - install-histograph-core.sh
  redis:
    ip-address: 10.0.0.53
    instance-type: t2.micro
    scripts:
      - install-redis.sh
  neo4j:
    ip-address: 10.0.0.54
    instance-type: m3.large
    # we run Neo4J on Debian 8 (jessy)
    machine-image: ami-b092aaad
    scripts:
      - install-neo4j.sh
```

For each user you want to grant access to the instance:
Replace 'name' with the username you wish to grant access.
Replace 'key' with the public key (from the pem file you created) for the user (on aws).

The configuration and scripts work together, so beware.

# Installation

This requires `python3`,
	brew install python3

You should prefer to run python in a jail called virtualenv.

	pip3 install virtualenv

Create jail in subdir `venv/`, ensure Python version 3.

	virtualenv -p python3 venv

Enter the jail through shell magic.

	source venv/bin/activate

(or `source venv/bin/activate.fish` if you are using
   [fish](http://fishshell.com))

And now install the requirements

	pip3 install -r requirements.txt

Ensure that you have AWS credentials setup

	# ~/.aws/credentials
	[default]
	aws_access_key_id = YOUR_KEY
	aws_secret_access_key = YOUR_SECRET

Also set up a default region (in e.g. ~/.aws/config):

	# ~/.aws/config
	[default]
	region = eu-central-1

Now you can run the scripts.

If you have AWS environment variables set, these will be picked up by `boto3`.
Beware they might conflict with `~/.aws/credentials`.
In bash you can clear them like this:

	unset AWS_SECRET_ACCESS_KEY
	unset AWS_ACCESS_KEY_ID

# Workflow

Creating a machine from the config above:

    ./aws-tool create cluster.yaml redis

By default a 'dry run' is enabled.
Change the DryRun=True value to False or comment out the option in aws.py to do a proper run.

Then wait... You will hopefully see the logs.
Check if all went fine, then create next instance.

    ./aws-tool create cluster.yaml neo4j
    ./aws-tool create cluster.yaml api
    ./aws-tool create cluster.yaml core

This is not ideal, but good enough for now.

# Finding base images

We use two kinds of images, Debian (Neo4J) and Amazon Linux (everything else).

To find all official Debian owned images, run this command.
You should prefer HVM over paravirtual and please note that image
identifiers are region dependent.

	aws --region eu-central-1 ec2 describe-images --owners 379101102735 \
    --filters "Name=name,Values=debian-*" \
    --query "Images[*].[Architecture,ImageId,VirtualizationType,Name]" \
    --output text

# Set up and tear down staging environment

Run the script `./setup_staging.sh`. This script will clone ElasticSearch's repository and create a new cluster pointing at it.

Then it will clone the disk of Neo4j's production instance and create and launch an instance based on the cloned disk.
The id of the instance to clone is specified in the config file `cluster_staging.yml`, see example below.

Finally, it will launch and install the following machines:

```
redis-staging
core-staging
api-staging
```

To tear down the staging environment, run the script `teardown_staging.sh`.
Tearing down is not fully automated, you need to perform some actions as specified in the script's output.

## Config

The setting for the staging are stored in [`cluster_staging.yaml`](cluster_staging.yaml),
it looks like this:

```yaml
users:
  # just place your ~/.ssh/id_*.pub key contents here
  # if you dont have such a public key, run `ssh-keygen`
  stefano: "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxIMaALlvQooxnPj9NiDMyhMap7IX0j4Yq/LHEZc+c4sj/KQXjovM845F/H8yj9r5Ibw4YWzkKROB9fRW+ZYcR43dlbDmlf9hZO/QYtWuk3ZC5DOvqBQ2+/Ume2sU70nyhR3u+Y60cXUhpSrr5sf1yTiQweNk8VhfezjXFCpcEUhEFtBYHiVrGY4wCIsx9IZ63Pr41A+pYiqMINXgxw/cB9s4uMIyNBG8NIiaPJC3MJgpfaX3FXLKT9BefrJP3kWBh1jTMfYyDiKCgerMh/2d5YPSiWDt1R3SPh9jQ0WgckCQsbMgl8df9Um+8iEO63iI88PIw11sEAvlE/wlUN03kQ== stefano@waag"

base-conf:
  # default image, amazon linux
  machine-image: ami-a6b0b7bb
  subnet: subnet-1a960e73 #staging subnet
  security-group: sg-b9ed94d0
  vpc: vpc-6865cc01
  region: eu-central-1
  instance-type: t2.micro
  app-user: histograph

hosts:
  api-staging:
    ip-address: 10.0.1.51
    instance-type: t2.small
    app-user: histograph
    scripts:
      - install-nodejs-repository.sh
      - library-functions.sh
      - staging/install-histograph-api.sh
  core-staging:
    ip-address: 10.0.1.52
    instance-type: t2.micro
    app-user: histograph
    scripts:
      - install-nodejs-repository.sh
      - library-functions.sh
      - staging/install-histograph-core.sh
  redis-staging:
    ip-address: 10.0.1.53
    instance-type: t2.micro
    scripts:
      - install-redis.sh

# these two are cloned from production i/o created from scratch
neo4j:
  ip-address: 10.0.1.54
  instanceId: i-af0db813
#  instance-type: m3.large
#  machine-image: ami-b092aaad # debian 8 (jessy)
#  scripts:
#    - install-neo4j.sh
#  elasticsearch:
#    ip-address: 10.0.1.55
#    instance-type: m3.xlarge
#    machine-image: ami-b092aaad # debian 8 (jessy)
#    scripts:
#      - install-elasticsearch.sh
```





---

Copyright (C) 2015 [Waag Society](http://waag.org).
