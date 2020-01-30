#!/bin/bash -e

# Debugging.
set -x

# Environment.
export SHELL=/bin/bash


# Enter home folder and start jupyterhub-singleuser.
cd /home/${SYSTEM_USER}
/opt/aiidalab-singleuser                                           \
    --ip=0.0.0.0                                                   \
    --port=8888                                                    \
    --notebook-dir="/home/${SYSTEM_USER}"                          \
    --NotebookApp.iopub_data_rate_limit=1000000000                 \
    --NotebookApp.default_url="/apps/apps/home/start.ipynb"
