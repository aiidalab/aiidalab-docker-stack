#!/bin/bash
set -emx

# Fix issue where the erlang cookie permissions are corrupted.
chmod 400 "/home/${NB_USER}/.erlang.cookie" || echo "erlang cookie not created yet."

mamba run -n aiida-core-services rabbitmq-server -detached
