#!/bin/bash
set -em

# For backwards compatibility
ln -sf /home/${SYSTEM_USER} /project 

su -c /opt/prepare-aiidalab.sh ${SYSTEM_USER}
