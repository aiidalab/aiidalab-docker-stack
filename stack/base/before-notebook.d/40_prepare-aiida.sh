#!/bin/bash

# This script is executed whenever the docker container is (re)started.
set -x

export SHELL=/bin/bash

# Check if user requested to set up AiiDA profile (and if it exists already)
if [[ ${SETUP_DEFAULT_AIIDA_PROFILE} == true ]] && ! verdi profile show ${AIIDA_PROFILE_NAME} 2> /dev/null; then
    NEED_SETUP_PROFILE=true;
else
    NEED_SETUP_PROFILE=false;
fi

# Setup AiiDA profile if needed.
if [[ ${NEED_SETUP_PROFILE} == true ]]; then

    # Create AiiDA profile.
    verdi quicksetup              \
        --non-interactive                            \
        --profile "${AIIDA_PROFILE_NAME}"            \
        --email "${AIIDA_USER_EMAIL}"                \
        --first-name "${AIIDA_USER_FIRST_NAME}"      \
        --last-name "${AIIDA_USER_LAST_NAME}"        \
        --institution "${AIIDA_USER_INSTITUTION}"    \
        --config /opt/config-quick-setup.yaml

    # Setup and configure local computer.
    computer_name=localhost

    # Determine the number of physical cores as a default for the number of
    # available MPI ranks on the localhost. We do not count "logical" cores,
    # since MPI parallelization over hyper-threaded cores is typically
    # associated with a significant performance penalty. We use the
    # `psutil.cpu_count(logical=False)` function as opposed to simply
    # `os.cpu_count()` since the latter would include hyperthreaded (logical
    # cores).
    NUM_PHYSICAL_CORES=$(python -c 'import psutil; print(int(psutil.cpu_count(logical=False)))' 2>/dev/null)
    LOCALHOST_MPI_PROCS_PER_MACHINE=${LOCALHOST_MPI_PROCS_PER_MACHINE:-${NUM_PHYSICAL_CORES}}

    if [ -z $LOCALHOST_MPI_PROCS_PER_MACHINE ]; then
      echo "Unable to automatically determine the number of logical CPUs on this "
      echo "machine. Please set the LOCALHOST_MPI_PROCS_PER_MACHINE variable to "
      echo "explicitly set the number of available MPI ranks."
      exit 1
    fi

    verdi computer setup \
        --non-interactive                                               \
        --label "${computer_name}"                                      \
        --description "this computer"                                   \
        --hostname "${computer_name}"                                   \
        --transport core.local                                          \
        --scheduler core.direct                                         \
        --work-dir /home/${NB_USER}/aiida_run/                          \
        --mpirun-command "mpirun -np {tot_num_mpiprocs}"                \
        --mpiprocs-per-machine ${LOCALHOST_MPI_PROCS_PER_MACHINE} &&    \
    verdi computer configure core.local "${computer_name}"              \
        --non-interactive                                               \
        --safe-interval 0.0

    # We need to limit how often the daemon worker polls the job scheduler
    # for job status. The poll interval is set to 0s by default, which results
    # in verdi worker spinning at 100% CPU.
    # We set this to 2.0 seconds which should limit the CPU utilization below 10%.
    # https://aiida.readthedocs.io/projects/aiida-core/en/stable/howto/run_codes.html#mitigating-connection-overloads
    job_poll_interval="2.0"
    python -c "
from aiida import load_profile; from aiida.orm import load_computer;
load_profile();
load_computer('${computer_name}').set_minimum_job_poll_interval(${job_poll_interval})
"

else

  # Migration will run for the default profile.
  pgrep -af 'verdi.* daemon' && echo "ERROR: AiiDA daemon is already running!" && exit 1
  ## clean up stale PID-files -> .aiida/daemon/circus-{profile-name}.pid
  rm -f /home/${NB_USER}/.aiida/daemon/circus-*.pid
  verdi storage migrate --force

fi
