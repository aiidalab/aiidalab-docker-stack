#!/bin/bash
set -em

# For backwards compatibility
ln -sf /home/${SYSTEM_USER} /project 

# Change group of the aiidalab-home folder
chown root:${SYSTEM_USER} -R /opt/aiidalab-home

su -c /opt/prepare-aiidalab.sh ${SYSTEM_USER}
