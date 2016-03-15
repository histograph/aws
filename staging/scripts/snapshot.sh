#!/bin/bash

if (( $# != 1 ))
then
	echo "illegal number of parameters, expected 1, got $#"
	exit 1
fi

name=${1}

echo making snapshot: $name
curl -XPUT "http://search-histograph-v3mtb6qo4la3qmu76rmoxkkz3i.eu-central-1.es.amazonaws.com/_snapshot/histograph-dump/"$name""

while [ 1 ]
do
	echo "checking status"
	status="$(curl http://search-histograph-v3mtb6qo4la3qmu76rmoxkkz3i.eu-central-1.es.amazonaws.com/_snapshot/histograph-dump/"$name" -s | jq '.snapshots[0].state')"

	if [ "$status" == "null" ]
	then
		echo "snapshot repo $name does not exist"
		exit 1
	fi

	if [ "$status" == '"SUCCESS"' ]
	then
		echo $status
		exit 0
	else
		echo $status
		echo "Trying again"
		sleep 10
	fi
done

exit 0
