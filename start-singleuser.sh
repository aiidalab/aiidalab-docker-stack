!/bin/bash -e

# This script is executed whenever the docker container is (re)started.

#===============================================================================
# debugging
set -x

#===============================================================================
# start postgresql
psql_start

#===============================================================================
# environment
export PYTHONPATH=/project
export SHELL=/bin/bash

# create bashrc
if [ ! -e /project/.bashrc ]; then
   cp -v /etc/skel/.bashrc /etc/skel/.bash_logout /etc/skel/.profile /project/
   echo 'eval "$(verdi completioncommand)"' >> /project/.bashrc
   echo 'export PYTHONPATH="/project"' >> /project/.bashrc
fi

#===============================================================================
# setup AiiDA
aiida_backend=django

if [ $aiida_backend = "django" ]; then
    verdi daemon stop || true
    echo "yes" | python /usr/local/lib/python2.7/dist-packages/aiida/backends/djsite/manage.py --aiida-profile=default migrate
    verdi daemon start
fi

# update the list of installed plugins
grep "reentry scan" /project/.bashrc || echo "reentry scan" >> /project/.bashrc

#===============================================================================
#start Jupyter notebook server
cd /project
/opt/matcloud-jupyterhub-singleuser                              \
  --ip=0.0.0.0                                                   \
  --port=8888                                                    \
  --notebook-dir="/project"                                      \
  --NotebookApp.iopub_data_rate_limit=1000000000                 \
  --NotebookApp.default_url="/apps/apps/home/start.ipynb"

#===============================================================================

#EOF
