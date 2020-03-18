#!/bin/bash
set -em

# For backwards compatibility
ln -s /home/${SYSTEM_USER} /project 

su -c /opt/prepare-aiidalab.sh ${SYSTEM_USER}
