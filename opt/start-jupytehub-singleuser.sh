#!/bin/bash -e

set -x

# environment
export PYTHONPATH=/project
export SHELL=/bin/bash

cd /project
/opt/aiidalab-jupyterhub-singleuser                                \
    --ip=0.0.0.0                                                   \
    --port=8888                                                    \
    --notebook-dir="/project"                                      \
    --NotebookApp.iopub_data_rate_limit=1000000000                 \
    --NotebookApp.default_url="/apps/apps/home/start.ipynb"
