#!/bin/bash

# This script is executed whenever the docker container is (re)started.
set -x

export SHELL=/bin/bash

# Daemon will start only if the database exists and is migrated to the latest version.
verdi daemon start || echo "ERROR: AiiDA daemon is not running!"
