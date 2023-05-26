# syntax=docker/dockerfile:1
FROM full-stack

USER root

USER ${NB_USER}

# Install the quantum-espresso app.
ARG AIIDALAB_QE_VERSION
RUN git clone https://github.com/aiidalab/aiidalab-qe && \
     cd aiidalab-qe && \
     git checkout v"${AIIDALAB_QE_VERSION}" && \
     pip install --quiet --no-cache-dir "./" && \
     fix-permissions "./" && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

ARG QE_VERSION
ENV QE_VERSION ${QE_VERSION}
RUN mamba create -p /opt/conda/envs/quantum-espresso-${QE_VERSION} --yes \
        qe=${QE_VERSION} \
     && mamba clean --all -f -y && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

COPY before-notebook.d/70_prepare-qeapp.sh /usr/local/bin/before-notebook.d/

WORKDIR "/home/${NB_USER}"
