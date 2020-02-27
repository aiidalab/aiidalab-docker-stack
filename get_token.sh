#!/bin/bash

if [ $# -ne 1 ]
  then
    echo "Please provide one argument only: container ID."
    exit 1
fi

DOCKERID=${1}

# Is container still starting?
docker exec --tty ${DOCKERID} wait-for-services 2> /dev/null & sleep 1 ; kill $! &> /dev/null

RESULT=$? # If it was killed (kill returns 0 exit code), then apply the condition below.

wait $! 2>/dev/null # This is to supress ugly 'Terminated: 15 ...' message.

if [[ ${RESULT} -eq 0 ]]; then

	echo Waiting for container to start...
	docker exec --tty ${DOCKERID} wait-for-services

	# Token does not appear immediately, so need to wait a little bit.
	sleep 5
fi

TOKEN=`docker logs ${DOCKERID} &> >(grep 'token=') | tail -n 1 | cut -d'=' -f2`

echo Use this token to login to AiiDA lab: ${TOKEN}
