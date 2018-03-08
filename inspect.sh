#!/bin/bash

set -x

docker run --init --user 0 -ti mc-docker-stack:develop /bin/bash

#EOF
