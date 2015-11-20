import boto3
import time
import sys

#1. get current cluster configuration
client = boto3.client('es')
response = client.describe_elasticsearch_domain_config(DomainName='histograph')
config = response['DomainConfig']

#update access policy resource name
options = '{"Version":"2012-10-17","Statement":[{"Sid":"","Effect":"Allow","Principal":{"AWS":"*"},"Action":"es:*","Resource":"arn:aws:es:eu-central-1:441915505712:domain/histograph-staging/*"}]}'
config['AccessPolicies']['Options'] = options

#2. create staging cluster based on 1.
response = client.create_elasticsearch_domain(
		DomainName='histograph-staging',
		ElasticsearchClusterConfig=config['ElasticsearchClusterConfig']['Options'],
		EBSOptions=config['EBSOptions']['Options'],
		AccessPolicies=config['AccessPolicies']['Options'], #met de hand toevoegen
		SnapshotOptions=config['SnapshotOptions']['Options'],
		AdvancedOptions=config['AdvancedOptions']['Options']
)

print(response)

#3. poll status until ready
# the created property should be truer
ready = False

while not ready:
	print("polling status")
	response = client.describe_elasticsearch_domain(DomainName='histograph-staging')
	status = response['DomainStatus']
	ready = status['Created'] and not status['Processing']
	time.sleep(60) #wait a minute, before trying again

print("staging ready")
