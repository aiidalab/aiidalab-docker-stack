# syntax=docker/dockerfile:1
FROM base-with-services as base

FROM  lab

USER root

COPY --from=base /opt/config-quick-setup.yaml /opt/
COPY --from=base "${CONDA_DIR}/envs/aiida-core-services" "${CONDA_DIR}/envs/aiida-core-services"
COPY --from=base /usr/local/bin/before-notebook.d /usr/local/bin/before-notebook.d

RUN fix-permissions "${CONDA_DIR}"
RUN fix-permissions "/home/${NB_USER}/.aiida"
RUN echo "HELLO!"

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"
