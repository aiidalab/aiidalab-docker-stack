#!/bin/bash
set -x

# -w waits until server is up
PSQL_START_CMD="pg_ctl --timeout=180 -w -D /home/${NB_USER}/.postgresql -l /home/${NB_USER}/.postgresql/logfile start"
PSQL_STOP_CMD="pg_ctl -w -D /home/${NB_USER}/.postgresql stop"
PSQL_STATUS_CMD="pg_ctl -D /home/${NB_USER}/.postgresql status"

MAMBA_RUN="mamba run -n aiida-core-services"

# make DB directory, if not existent
if [ ! -d /home/${NB_USER}/.postgresql ]; then
   mkdir /home/${NB_USER}/.postgresql
   ${MAMBA_RUN} initdb
   echo "unix_socket_directories = '/tmp'" >> /home/${NB_USER}/.postgresql/postgresql.conf
   ${MAMBA_RUN} ${PSQL_START_CMD}

else
    # Fix problem with kubernetes cluster that adds rws permissions to the group
    # for more details see: https://github.com/materialscloud-org/aiidalab-z2jh-eosc/issues/5
    chmod g-rwxs /home/${NB_USER}/.postgresql -R

    if ! ${MAMBA_RUN} ${PSQL_STATUS_CMD}; then
       # Cleaning up the mess if Postgresql was not shutdown properly.
       # TODO: Rotate logfile
       echo "" > /home/${NB_USER}/.postgresql/logfile
       rm -vf /home/${NB_USER}/.postgresql/postmaster.pid
       ${MAMBA_RUN} ${PSQL_START_CMD}
   fi
fi
