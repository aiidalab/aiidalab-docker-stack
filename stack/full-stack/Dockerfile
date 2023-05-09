# syntax=docker/dockerfile:1
FROM services

FROM lab

USER root

COPY --from=services /opt/config-quick-setup.yaml /opt/
COPY --from=services "${CONDA_DIR}/envs/aiida-core-services" "${CONDA_DIR}/envs/aiida-core-services"
COPY --from=services /usr/local/bin/before-notebook.d /usr/local/bin/before-notebook.d

RUN fix-permissions "${CONDA_DIR}"

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"
