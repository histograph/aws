import boto3

#1. get current cluster
client = boto3.client('es')
response = client.delete_elasticsearch_domain(DomainName='histograph-staging')
print(response)
