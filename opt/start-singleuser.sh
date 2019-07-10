#!/bin/bash -e

# This script is executed whenever the docker container is (re)started.

#===============================================================================
# debugging
set -x

#===============================================================================
# environment
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
# perform the database migration if needed
#
verdi daemon start || ( verdi daemon stop && verdi database migrate --force )
verdi daemon stop

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
    verdi computer configure local ${computer_name}        \
    --non-interactive                                      \
    --safe-interval 0.0

#===============================================================================
# setup CP2K code

code_name=cp2k
verdi code show ${code_name}@${computer_name} || verdi code setup \
    --non-interactive                                             \
    --label ${code_name}                                          \
    --description "cp2k on this computer"                         \
    --input-plugin cp2k                                           \
    --computer localhost                                          \
    --remote-abs-path `which cp2k.popt`

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
# setup pseudopotentials
if [ ! -e /project/SKIP_IMPORT_PSEUDOS ]; then
      cd /opt/pseudos
      verdi data upf listfamilies | grep 'SSSP_efficiency_v1.0'|| verdi data upf uploadfamily SSSP_efficiency_pseudos 'SSSP_efficiency_v1.0' 'SSSP pseudopotential library'
      verdi data upf listfamilies | grep 'SSSP_precision_v1.0' || verdi data upf uploadfamily SSSP_precision_pseudos 'SSSP_precision_v1.0' 'SSSP pseudopotential library'
fi

#===============================================================================
# setup AiiDA jupyter extension
# don't forget to copy this file to .ipython/profile_default/startup/
# aiida/tools/ipython/aiida_magic_register.py
if [ ! -e /project/.ipython/profile_default/startup/aiida_magic_register.py ]; then
   mkdir -p /project/.ipython/profile_default/startup/
   cat << EOF > /project/.ipython/profile_default/startup/aiida_magic_register.py
if __name__ == "__main__":

    try:
        import aiida
        del aiida
    except ImportError:
        pass
    else:
        import IPython
        # pylint: disable=ungrouped-imports
        from aiida.tools.ipython.ipython_magics import load_ipython_extension

        # Get the current Ipython session
        IPYSESSION = IPython.get_ipython()

        # Register the line magic
        load_ipython_extension(IPYSESSION)
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
   cd /project/apps/home
   git checkout aiida_v1.0
   cd -
   echo '{
  "hidden": [],
  "order": [
    "aiida-tutorials",
    "cscs",
    "calcexamples"
  ]
}' > /project/apps/home/.launcher.json
   git clone https://github.com/aiidalab/aiidalab-widgets-base /project/apps/aiidalab-widgets-base
   cd /project/apps/aiidalab-widgets-base
   git checkout aiida-1.0
   cd -
   git clone https://github.com/aiidalab/aiidalab-calculation-examples.git /project/apps/calcexamples
   cd /project/apps/calcexamples
   git checkout aiida-1.0
   cd -
fi

#EOF
