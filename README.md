# Setup

Prefer to run python in a jail called virtualenv.

	pip install virtualenv

Create jail and install requirements,

	virtualenv venv
	source venv/bin/activate
	pip install -r requirements.txt

Ensure that you have AWS credentials setup

	# ~/.aws/credentials
	[default]
	aws_access_key_id = YOUR_KEY
	aws_secret_access_key = YOUR_SECRET

Then, set up a default region (in e.g. ~/.aws/config):

	# ~/.aws/config
	[default]
	region = eu-central-1

Now you can run the scripts
