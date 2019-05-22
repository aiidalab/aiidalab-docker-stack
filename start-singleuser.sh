#!/bin/bash -e

# This script is executed whenever the docker container is (re)started.

#===============================================================================
# debugging
set -x

#===============================================================================
# start postgresql
source /opt/postgres.sh
psql_start

#===============================================================================
# environment
export PYTHONPATH=/project
export SHELL=/bin/bash

#===============================================================================
reentry scan

#===============================================================================
# setup AiiDA
aiida_backend=django

if [ ! -d /project/.aiida ]; then
    verdi setup                                \
        --profile default                      \
        --non-interactive                      \
        --email some.body@xyz.com              \
        --first-name Some                      \
        --last-name Body                       \
        --institution XYZ                      \
        --db-backend $aiida_backend            \
        --db-username aiida                    \
        --db-password aiida_db_passwd          \
        --db-name aiidadb                      \
        --db-host localhost                    \
        --db-port 5432                         \
        --repository /project/aiida_repository

   verdi profile setdefault default
fi

#===============================================================================
# setup local computer

computer_name=localhost
verdi computer show $computer_name || verdi computer setup \
    --non-interactive                                      \
    --label ${computer_name}                               \
    --description "this computer"                          \
    --hostname ${computer_name}                            \
    --transport local                                      \
    --scheduler direct                                     \
    --work-dir /project/aiida_run/                         \
    --mpirun-command "mpirun -np {tot_num_mpiprocs}"       \
    --mpiprocs-per-machine 1 &&                            \
    verdi computer configure local ${computer_name} --non-interactive

#===============================================================================
# setup Quantum ESPRESSO pw.x code

code_name=pw
verdi code show ${code_name}@${computer_name} || verdi code setup \
    --non-interactive                                             \
    --label ${code_name}                                          \
    --description "pw.x on this computer"                         \
    --input-plugin quantumespresso.pw                             \
    --computer localhost                                          \
    --remote-abs-path `which pw.x`

#===============================================================================
# start the AiiDA daemon
verdi daemon start

#===============================================================================
# setup pseudopotentials
if [ ! -e /project/SKIP_IMPORT_PSEUDOS ]; then
      cd /opt/pseudos
      verdi data upf uploadfamily SSSP_efficiency_pseudos 'SSSP_efficiency_v1.0' 'SSSP pseudopotential library'
      verdi data upf uploadfamily SSSP_precision_pseudos 'SSSP_precision_v1.0' 'SSSP pseudopotential library'
fi

#===============================================================================
# setup AiiDA jupyter extension
if [ ! -e /project/.ipython/profile_default/ipython_config.py ]; then
   mkdir -p /project/.ipython/profile_default/
   echo > /project/.ipython/profile_default/ipython_config.py <<EOF
c = get_config()
c.InteractiveShellApp.extensions = [
   'aiida.common.ipython.ipython_magics'
]
EOF
fi

#===============================================================================
# create bashrc
if [ ! -e /project/.bashrc ]; then
   cp -v /etc/skel/.bashrc /etc/skel/.bash_logout /etc/skel/.profile /project/
   echo 'eval "$(verdi completioncommand)"' >> /project/.bashrc
   echo 'export PYTHONPATH="/project"' >> /project/.bashrc
   echo 'export PATH=$PATH:"/project/.local/bin"' >> /project/.bashrc
fi

#===============================================================================
# update the list of installed plugins
grep "reentry scan" /project/.bashrc || echo "reentry scan" >> /project/.bashrc

#===============================================================================
# generate ssh key
if [ ! -e /project/.ssh/id_rsa ]; then
   mkdir -p /project/.ssh
   ssh-keygen -f /project/.ssh/id_rsa -t rsa -N ''
fi

#===============================================================================
# install/upgrade apps
if [ ! -e /project/apps ]; then
   mkdir /project/apps
   touch /project/apps/__init__.py
   git clone https://github.com/aiidalab/aiidalab-home /project/apps/home
   echo '{
  "hidden": [],
  "order": [
    "aiida-tutorials",
    "cscs",
    "calcexamples"
  ]
}' > /project/apps/home/.launcher.json
   git clone https://github.com/aiidalab/aiidalab-widgets-base /project/apps/aiidalab-widgets-base
   git clone https://github.com/aiidateam/aiida_demos /project/apps/aiida-tutorials
   git clone https://github.com/aiidalab/aiidalab-cscs /project/apps/cscs
   git clone https://github.com/aiidalab/aiidalab-calculation-examples.git /project/apps/calcexamples

fi

#===============================================================================
if [[ -z "${HEADLESS}" ]]; then

  # running in normal mode
  # start Jupyter notebook server
  cd /project
  /opt/matcloud-jupyterhub-singleuser                              \
    --ip=0.0.0.0                                                   \
    --port=8888                                                    \
    --notebook-dir="/project"                                      \
    --NotebookApp.iopub_data_rate_limit=1000000000                 \
    --NotebookApp.default_url="/apps/apps/home/start.ipynb"
    
else

  # running in headless mode
  # (will simply exit)
  echo "Startup complete."
  sleep infinity

fi

#===============================================================================

#EOF
