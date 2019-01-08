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
# setup AiiDA
aiida_backend=django

if [ ! -d /project/.aiida ]; then
   verdi setup                          \
      --non-interactive                 \
      --email some.body@xyz.com         \
      --first-name Some                 \
      --last-name Body                  \
      --institution XYZ                 \
      --backend $aiida_backend          \
      --db_user aiida                   \
      --db_pass aiida_db_passwd         \
      --db_name aiidadb                 \
      --db_host localhost               \
      --db_port 5432                    \
      --repo /project/aiida_repository \
      default

   verdi profile setdefault verdi default
   verdi profile setdefault daemon default
   bash -c 'echo -e "y\nsome.body@xyz.com" | verdi daemon configureuser'

   # setup localhost and codes
   compname=localhost
   codename=pw
   codeplugin=quantumespresso.pw
   codexec=pw.x
   codepath=`which $codexec`

   verdi computer show ${compname} || ( echo "${compname}
localhost
this computer
True
local
direct
#!/bin/bash
/home/{username}/aiida_run/
mpirun -np {tot_num_mpiprocs}
1" | verdi computer setup && verdi computer configure ${compname} )

    # Quantum Espresso
    verdi code show ${codename}@${compname} || echo "${codename}
pw.x on this computer
False
${codeplugin}
${compname}
${codepath}" | verdi code setup

    # import pseudo family for QE
    base_url=http://archive.materialscloud.org/file/2018.0001/v1
    pseudo_name=SSSP_efficiency_pseudos
    wget ${base_url}/${pseudo_name}.aiida
    verdi import ${pseudo_name}.aiida


    # Cp2k
    codename=cp2k
    codeplugin=cp2k
    codexec=cp2k.popt
    codepath=`which $codexec`

    verdi code show ${codename}@${compname} || echo "${codename}
cp2k on this computer
False
${codeplugin}
${compname}
${codepath}" | verdi code setup

##EOF
   # increase logging level
   #verdi devel setproperty logging.celery_loglevel DEBUG
   #verdi devel setproperty logging.aiida_loglevel DEBUG

   # start the daemon
   verdi daemon start

   # setup pseudopotentials
   if [ ! -e /project/SKIP_IMPORT_PSEUDOS ]; then
      cd /opt/pseudos
      for i in *; do
         verdi import $i
      done
   fi

else
    if [ $aiida_backend = "django" ]; then
        verdi daemon stop || true
        echo "yes" | python /usr/local/lib/python2.7/dist-packages/aiida/backends/djsite/manage.py --aiida-profile=default migrate
        verdi daemon start
    fi
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
fi

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
   git clone https://github.com/aiidateam/aiida_demos /project/apps/aiida-tutorials
   git clone https://github.com/aiidalab/aiidalab-cscs /project/apps/cscs

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
