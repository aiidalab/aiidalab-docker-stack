#!/bin/bash
set -emx

RMQ_ETC_DIR_ARM64="/opt/conda/envs/aiida-core-services/rabbitmq_server/etc/rabbitmq"
RMQ_ETC_DIR_AMD64="/opt/conda/envs/aiida-core-services/etc/rabbitmq"
if [[ -d $RMQ_ETC_DIR_ARM64 ]]; then
    RMQ_ETC_DIR="$RMQ_ETC_DIR_ARM64"
elif [[ -d $RMQ_ETC_DIR_AMD64 ]]; then
    RMQ_ETC_DIR="$RMQ_ETC_DIR_AMD64"
else
    echo "ERROR: Could not find RabbitMQ etc directory"
    exit 1
fi

RABBITMQ_DATA_DIR="/home/${NB_USER}/.rabbitmq"
mkdir -p "${RABBITMQ_DATA_DIR}"
fix-permissions "${RABBITMQ_DATA_DIR}"

# Set base directory for RabbitMQ to persist its data. This needs to be set to a folder in the system user's home
# directory as that is the only folder that is persisted outside of the container.
echo MNESIA_BASE="${RABBITMQ_DATA_DIR}" >> "${RMQ_ETC_DIR}/rabbitmq-env.conf"
echo LOG_BASE="${RABBITMQ_DATA_DIR}/log" >> "${RMQ_ETC_DIR}/rabbitmq-env.conf"

# RabbitMQ with versions >= 3.8.15 have reduced some default timeouts
# Using workaround from https://github.com/aiidateam/aiida-core/wiki/RabbitMQ-version-to-use
# setting the consumer_timeout to undefined disables the timeout
cat > "${RMQ_ETC_DIR}/advanced.config" <<EOF
%% advanced.config
[
  {rabbit, [
    {consumer_timeout, undefined}
  ]}
].
EOF

# Explicitly define the node name. This is necessary because the mnesia subdirectory contains the hostname, which by
# default is set to the value of $(hostname -s), which for docker containers, will be a random hexadecimal string. Upon
# restart, this will be different and so the original mnesia folder with the persisted data will not be found. The
# reason RabbitMQ is built this way is through this way it allows to run multiple nodes on a single machine each with
# isolated mnesia directories. Since in the AiiDA setup we only need and run a single node, we can simply use localhost.
echo NODENAME=rabbit@localhost >> "${RMQ_ETC_DIR}/rabbitmq-env.conf"
