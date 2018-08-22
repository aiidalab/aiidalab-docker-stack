#!/bin/bash -e

# This script sets up the user environment

#===============================================================================
# debugging
set -x

#===============================================================================
# setup postgresql
#TODO setup signal handler which shuts down posgresql and aiida.
source /opt/postgres.sh
psql_start

#===============================================================================
# environment
export PYTHONPATH=/project
export SHELL=/bin/bash

#===============================================================================
# setup AiiDA
aiida_backend=sqlalchemy

verdi setup                          \
  --non-interactive                 \
  --email discover@materialscloud.org     \
  --first-name Discover             \
  --last-name Section               \
  --institution Materialscloud      \
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
bash -c 'echo -e "y\ndiscover@materialscloud.org" | verdi daemon configureuser'

# setup pseudopotentials
cd /opt/pseudos
for i in *; do
 verdi import $i
done

#===============================================================================
# create bashrc
cp -v /etc/skel/.bashrc /etc/skel/.bash_logout /etc/skel/.profile /project/

echo >> /project/.bashrc <<EOF
eval "$(verdi completioncommand)"
export PYTHONPATH="/project"
. /opt/postgres.sh
EOF

#===============================================================================
# generate ssh key
mkdir -p /project/.ssh
ssh-keygen -f /project/.ssh/id_rsa -t rsa -N ''

#===============================================================================
# setup AiiDA jupyter extension
mkdir -p /project/.ipython/profile_default/
echo > /project/.ipython/profile_default/ipython_config.py <<EOF
c = get_config()
c.InteractiveShellApp.extensions = [
    'aiida.common.ipython.ipython_magics'
]
EOF

#===============================================================================
# install/upgrade apps
mkdir /project/apps
touch /project/apps/__init__.py
git clone https://github.com/materialscloud-org/mc-home /project/apps/home

#===============================================================================
# stop postgres again
psql_stop

#EOF
