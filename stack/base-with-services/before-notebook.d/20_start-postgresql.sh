#!/bin/bash
set -x

# -w waits until server is up
PSQL_START_CMD="pg_ctl --timeout=180 -w -l ${PGDATA}/logfile start"
PSQL_STATUS_CMD="pg_ctl status"

MAMBA_RUN="mamba run -n aiida-core-services"

# make DB directory, if not existent
if [ ! -d ${PGDATA} ]; then
   mkdir ${PGDATA}
   ${MAMBA_RUN} initdb
   echo "unix_socket_directories = '/tmp'" >> ${PGDATA}/postgresql.conf
   ${MAMBA_RUN} ${PSQL_START_CMD}

else
    # Fix problem with kubernetes cluster that adds rws permissions to the group
    chmod -R g-rwxs ${PGDATA}

    if ! ${MAMBA_RUN} ${PSQL_STATUS_CMD}; then
       # Cleaning up the mess if Postgresql was not shutdown properly.
       mv ${PGDATA}/logfile ${PGDATA/logfile.1 && gzip ${PGDATA}/logfile.1
       rm -vf ${PGDATA}/postmaster.pid
       ${MAMBA_RUN} ${PSQL_START_CMD}
   fi
fi
