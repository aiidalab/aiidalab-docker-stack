#!/bin/bash

# Start hq server
nohup hq server start 1>$HOME/.hq-stdout 2>$HOME/.hq-stderr &

# Start two workers each worker has 2 CPUs, thus no matter how much resourse the machine has
# Only 4 "faked" CPUs are available. Each worker can have 2_560 mb. The
# XXX: This requires more discussion on:
# 1. read the CPU/MEM from environment variable in k8s deployment (the variable not avial for docker container)
# 2. if it is a good idea just give the 4 fake CPUs. (personally like this setup, for large computation it will anyway goes to the HPC.)
mkdir .hq-server
nohup hq worker start --cpus=2 --resource "mem=sum(2560)" --no-detect-resources &
nohup hq worker start --cpus=2 --resource "mem=sum(2560)" --no-detect-resources &
