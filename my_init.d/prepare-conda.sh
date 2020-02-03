#!/bin/bash
set -em

chown ${SYSTEM_USER}:${SYSTEM_USER} /opt/conda
su ${SYSTEM_USER} -c "/opt/conda/bin/conda init"

