#!/bin/bash

# Start hq server
nohup hq server start 1>$HOME/.hq-stdout 2>$HOME/.hq-stderr &

# Start two workers each worker has 2 CPUs, thus no matter how much resourse the machine has
# Only 4 "faked" CPUs are available. Each worker can have 2_560 mb. The
# The hyperthreading is turned off for the mpi job no matter if the computer has hyperthreading or not.
# XXX: This requires more discussion on:
# 1. read the CPU/MEM from environment variable in k8s deployment (the variable not avial for docker container)
# 2. if it is a good idea just give the 4 fake CPUs. (personally like this setup, for large computation it will anyway goes to the HPC.)
mkdir .hq-server
nohup hq worker start --cpus=2 --resource "mem=sum(2560)" --no-detect-resources &
sleep 2
nohup hq worker start --cpus=2 --resource "mem=sum(2560)" --no-detect-resources &

# Setup the pw code
verdi code create core.code.installed --non-interactive \
  --label pw-7.2 \
  --description "pw-7.2 run on hq local" \
  --default-calc-job-plugin quantumespresso.pw \
  --computer localhost-hq \
  --prepend-text 'eval "$(conda shell.posix hook)"
conda activate base
export OMP_NUM_THREADS=1' \
  --filepath-executable pw.x

aiida-pseudo install sssp --functional PBE -p precision
