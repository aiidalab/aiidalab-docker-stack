#!/bin/bash
set -x

if [[ -z $PGDATA ]]; then
   echo "ERROR: PGDATA variable not set, cannot start PostgreSQL!"
   exit 1
fi

PSQL_LOGFILE="${PGDATA}/logfile"
# -w waits until server is up
PSQL_START_CMD="pg_ctl --timeout=180 -w -l ${PSQL_LOGFILE} start"

# Activate the aiida-core-services environment directly instead of using mamba run
eval "$(conda shell.bash hook)"
conda activate aiida-core-services

# Initialize DB directory if it does not exist
if [[ ! -d ${PGDATA} ]]; then
    mkdir "${PGDATA}"
    initdb
    echo "unix_socket_directories = '/tmp'" >> "${PGDATA}/postgresql.conf"
else
    # Fix problem with kubernetes cluster that adds rws permissions to the group
    chmod -R g-rwxs "${PGDATA}"

    if [[ -f ${PGDATA}/logfile ]]; then
        rm -f "${PSQL_LOGFILE}.1.gz"
        mv "${PSQL_LOGFILE}" "${PSQL_LOGFILE}.1" && gzip "${PSQL_LOGFILE}.1"
    fi
    # Cleaning up the mess if PostgreSQL was not shutdown properly.
    rm -vf "${PGDATA}/postmaster.pid"
fi

# Start the server
${PSQL_START_CMD}
