#!/bin/bash -e

# Debugging.
set -x

# Environment.  export SHELL=/bin/bash


# Enter home folder and start jupyterhub-singleuser.
cd /home/${SYSTEM_USER}

if [[ ! -z "${JUPYTERHUB_API_TOKEN}" ]]; then

  # Launched by JupyterHub, use single-user entrypoint.
  /usr/bin/python3 /opt/aiidalab-singleuser                           \
      --ip=0.0.0.0                                                   \
      --port=8888                                                    \
      --notebook-dir="/home/${SYSTEM_USER}"                          \
      --VoilaConfiguration.template=aiidalab                         \
      --VoilaConfiguration.enable_nbextensions=True                  \
      --NotebookApp.iopub_data_rate_limit=1000000000                 \
      --NotebookApp.default_url="/apps/apps/home/start.ipynb"
else

  # Otherwise launch notebook server directly.
  /usr/local/bin/jupyter-notebook                                    \
      --ip=0.0.0.0                                                   \
      --port=8888                                                    \
      --no-browser                                                   \
      --notebook-dir="/home/${SYSTEM_USER}"                          \
      --VoilaConfiguration.template=aiidalab                         \
      --VoilaConfiguration.enable_nbextensions=True                  \
      --NotebookApp.default_url="/apps/apps/home/start.ipynb"
fi
