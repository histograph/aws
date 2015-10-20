# Installation

You should prefer to run python in a jail called virtualenv.

	pip install virtualenv

This requires `python3`,

	brew install python3

Create jail in subdir `venv/`, ensure Python version 3.

	virtualenv -p python3 venv

Enter the jail through shell magic.

	source venv/bin/activate

And install requirements

	pip install -r requirements.txt

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

If you have AWS environment variables set, these will also be picked up and
might conflict with `~/.aws/credentials`. In bash you can clear them like this:

	unset AWS_SECRET_ACCESS_KEY
	unset AWS_ACCESS_KEY_ID


# Workflow

You create an amazon machine image using a template directory.

    python3 create-image.py elastic neo4j redis histograph

This command start an instance, execute all templates, shutdown
and create machine image.

    ami-1234abcdef

You can then start an instance using this image and
mount some optional EBS volumes or enable services.

    #redhat chkconfig httpd off
    #redhat chkconfig httpd on
    #debian update-rc.d apache2 defaults
    #debian update-rc.d -f apache2 remove

# Finding images

We use two kinds of images, Amazon Linux (everything) and Debian (Neo4J).

Find all official debian owned images, prefer HVM over paravirtual and note
that image identifiers are region dependent.

	aws --region eu-central-1 ec2 describe-images --owners 379101102735 --filters "Name=name,Values=debian-*" --query "Images[*].[Architecture,ImageId,VirtualizationType,Name]" --output text


Copyright (C) 2015 [Waag Society](http://waag.org).
