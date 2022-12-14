# syntax=docker/dockerfile:1
FROM base-with-services as base

FROM lab

USER root

COPY --from=base /opt/config-quick-setup.yaml /opt/
COPY --from=base "${CONDA_DIR}/envs/aiida-core-services" "${CONDA_DIR}/envs/aiida-core-services"
COPY --from=base /usr/local/bin/before-notebook.d /usr/local/bin/before-notebook.d

RUN fix-permissions "${CONDA_DIR}"
RUN fix-permissions "/home/${NB_USER}"

# TODO: This cannot be in base! It would break the base-with-services build
# Should it be in lab and base-with-services? Or only here?
# Add conda envs_dirs in home directory,
# which will persist between container invocation
RUN conda config --system --add envs_dirs /opt/conda
RUN conda config --system --add envs_dirs "~/.conda/envs"

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"
