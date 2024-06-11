#!/bin/bash
set -emx

# Fix issue where the erlang cookie permissions are corrupted.
chmod 400 "/home/${NB_USER}/.erlang.cookie" || echo "erlang cookie not created yet."

# NOTE: In arm64 build, rabbitmq is not installed via conda,
# but the following incantation still works since
# rabbitmq-server is available globally.
mamba run -n aiida-core-services rabbitmq-server -detached
