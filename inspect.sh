#!/bin/bash

set -x

# login as scientist
docker run --init --user scientist -ti aiidalab-docker-stack:develop /bin/bash

#EOF
