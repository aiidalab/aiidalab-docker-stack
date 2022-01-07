#!/bin/bash
set -em

# Change group of the aiidalab-home folder
chown root:${SYSTEM_USER} -R /opt/aiidalab-home

su -c /opt/prepare-aiidalab.sh ${SYSTEM_USER}
