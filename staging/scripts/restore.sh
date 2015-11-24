#1. create staging domain, based on current domain (programatically)
#2. register snapshot in staging domain
#3. restore from bucket

curl -XDELETE 'https://search-histograph-staging-fsuaepsiqkaydkv2w6bxhxmiji.eu-central-1.es.amazonaws.com/_all'
curl -XPOST 'https://search-histograph-staging-fsuaepsiqkaydkv2w6bxhxmiji.eu-central-1.es.amazonaws.com/_snapshot/histograph-dump/dump_all_11-24-15/_restore'
