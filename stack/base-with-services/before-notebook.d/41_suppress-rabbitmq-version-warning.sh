#!/bin/bash
set -emx

# Supress rabbitmq version warning since
# we explicitly set consumer_timeout to 100 hours in /etc/rabbitmq/rabbitmq.conf
verdi config set warnings.rabbitmq_version False
