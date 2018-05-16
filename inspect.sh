#!/bin/bash

set -x

docker run --init --user 0 -ti mc-docker-stack:develop /bin/bash

# login as scientist
#docker run --init --user scientist -ti mc-docker-stack:develop /bin/bash

#EOF
