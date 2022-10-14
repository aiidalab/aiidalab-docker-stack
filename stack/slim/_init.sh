#!/bin/bash

# Start the ssh-agent
/usr/local/bin/_entrypoint.sh ssh-agent

# setup aiida
/usr/local/bin/_entrypoint.sh /usr/local/bin/prepare-aiida.sh

exec "$@"
