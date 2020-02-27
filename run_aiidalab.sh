#!/bin/bash

if [[ $# -ne 2 ]]
  then
    echo "Please provide 2 argumets: free port of your computer and a folder to mount."
    echo "If the folder does not exit, it will be created automatically."
    echo ''
    echo 'Example:'
    echo '$ ./run_aiidalab.sh 8888 ${HOME}/aiidalab'
    exit 1
fi

PORT=${1}
FOLDER=${2}
TOKEN=`date | md5`
IMAGE='aiidalab/aiidalab-docker-stack:latest'

echo "Pulling the image from the Docker Hub..."
docker pull ${IMAGE}

echo "Launching the container..."
CONTAINERID=`docker run -d -p 8888:${PORT} -e JUPYTER_TOKEN=${TOKEN} -v ${FOLDER}:/home/aiida ${IMAGE}`

echo "Waiting for container to start..."
docker exec --tty ${CONTAINERID} wait-for-services

echo "Container started successfully."
echo "Put this link to browser to run AiiDA lab:"
echo "localhost:${PORT}/?token=${TOKEN}"