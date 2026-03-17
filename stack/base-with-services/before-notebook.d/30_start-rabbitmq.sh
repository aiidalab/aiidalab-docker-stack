#!/bin/bash
set -emx

# Fix issue where the erlang cookie permissions are corrupted.
chmod 400 "/home/${NB_USER}/.erlang.cookie" || echo "erlang cookie not created yet."

# Activate the aiida-core-services environment directly
eval "$(conda shell.bash hook)"
conda activate aiida-core-services

# NOTE: In arm64 build, rabbitmq is not installed via conda,
# but the following incantation still works since
# rabbitmq-server is available globally.
rabbitmq-server -detached

# Wait a moment for RabbitMQ to start
sleep 2
