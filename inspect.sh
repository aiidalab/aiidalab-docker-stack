#!/bin/bash

set -x

#docker run --init --user 0 -ti aiidalab-docker-stack:develop /bin/bash

# login as scientist
docker run --init --user scientist -ti aiidalab-docker-stack:develop /bin/bash

#EOF
