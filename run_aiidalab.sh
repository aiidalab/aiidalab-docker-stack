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
TOKEN=`openssl rand -hex 32`
IMAGE='aiidalab/aiidalab-docker-stack:latest'

echo "Pulling the image from the Docker Hub..."
docker pull ${IMAGE}

echo "Launching the container..."
CONTAINERID=`docker run -d -p ${PORT}:8888 -e JUPYTER_TOKEN=${TOKEN} -v "${FOLDER}":/home/aiida ${IMAGE}`

echo "Waiting for container to start..."
docker exec --tty ${CONTAINERID} wait-for-services

echo "Container started successfully."
echo "Open this link in the browser to enter AiiDA lab:"
echo "http://localhost:${PORT}/?token=${TOKEN}"
