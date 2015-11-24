from boto.connection import AWSAuthConnection
import os

class ESConnection(AWSAuthConnection):

	def __init__(self, region, **kwargs):
		super(ESConnection, self).__init__(**kwargs)
		self._set_auth_region_name(region)
		self._set_auth_service_name("es")

	def _required_auth_capability(self):
		return ['hmac-v4']

if __name__ == "__main__":

	client = ESConnection(
			region='eu-central-1',
			host='search-histograph-staging-fsuaepsiqkaydkv2w6bxhxmiji.eu-central-1.es.amazonaws.com',
			aws_access_key_id=os.environ['AWS_ACCESS_KEY_ID'],
			aws_secret_access_key=os.environ['AWS_SECRET_ACCESS_KEY'], 
			is_secure=False)

	print('Registering Snapshot Repository')
	resp = client.make_request(method='POST',
			path='/_snapshot/histograph-dump',
			data='{"type": "s3","settings": { "bucket": "histograph-es-dump","region": "eu-central-1","role_arn": "arn:aws:iam::441915505712:role/elasticsearch-s3-dump"}}')
	body = resp.read()
	print(body)
