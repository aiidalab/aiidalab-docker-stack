# syntax=docker/dockerfile:1
FROM base

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"

# By default, Jupyter Docker image launches the JupyterLab interface.
# Here, we change it to the nbclassic Jupyter Notebook which is used by AiiDAlab.
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html#switching-back-to-the-classic-notebook-or-using-a-different-startup-command
ENV DOCKER_STACKS_JUPYTER_CMD=nbclassic

USER root
WORKDIR /opt/

# Install aiidalab package
ARG AIIDALAB_VERSION
RUN mamba install --yes \
     aiidalab=${AIIDALAB_VERSION} \
     appmode=1.0.0 \
     && mamba clean --all -f -y && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

# Pin aiidalab version.
RUN echo "aiidalab==${AIIDALAB_VERSION}" >> /opt/requirements.txt
RUN conda config --system --add pinned_packages "aiidalab=${AIIDALAB_VERSION}"

# Enable aiidalab autocompletion
RUN echo 'eval "$(_AIIDALAB_COMPLETE=bash_source aiidalab)"' >> "${CONDA_DIR}/etc/conda/activate.d/activate_aiida_autocompletion.sh"

# Install the aiidalab-home app.
ARG AIIDALAB_HOME_VERSION
RUN git clone https://github.com/aiidalab/aiidalab-home && \
     cd aiidalab-home && \
     git checkout "${AIIDALAB_HOME_VERSION}" && \
     pip install --no-user --quiet --no-cache-dir "./" && \
     fix-permissions "./" && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

# Swap appmode icon for AiiDAlab gears icon, shown during app load
# TODO: What is the correct directory for nbclassic?
#COPY --chown=${NB_UID}:${NB_GID} gears.svg ${CONDA_DIR}/share/jupyter/nbextensions/appmode/gears.svg

# Copy start-up scripts for AiiDAlab.
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/

# Configure AiiDAlab environment.
ENV AIIDALAB_HOME=/home/${NB_USER}
ENV AIIDALAB_APPS=${AIIDALAB_HOME}/apps
ENV AIIDALAB_DEFAULT_GIT_BRANCH=master

# Specify which apps to install in addition to the home app. The
# AIIDALAB_DEFAULT_APPS variable should be a whitespace-delimited variable
# where each entry must follow the specifier format used by `aiidalab install`.
#
# Example for setting the AIIDALAB_DEFAULT_APPS variable:
#
#   AIIDALAB_DEFAULT_APPS="aiidalab-widgets-base quantum-espresso==20.12.0"
#
# Please note that multiple entries must be whitespace delimited.
# Please see `aiidalab install --help` for more information.
# ENV AIIDALAB_DEFAULT_APPS "aiidalab-widgets-base~=1.0"
ENV AIIDALAB_DEFAULT_APPS=""

# Specify default factory reset (not set):
ENV AIIDALAB_FACTORY_RESET=""

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"

RUN mkdir -p /home/${NB_USER}/apps
RUN mkdir -p /home/${NB_USER}/.tmp_notebooks

# When a Jupyter notebook server looses a connection to the frontend,
# it keeps the messages in a buffer. If there is a background thread running
# and trying to update the frontend, the buffer grows indefinitely,
# eventually consuming all available RAM.
# See https://github.com/aiidalab/issues/issues/13 for detailed analysis.
# Moreover, it will leave the python kernel running indefinitely which needlessly consumes resources.
# We could turn this behaviour off by setting "buffer_offline_messages=False",
# but that may come with other problems for people with flaky internet connections.
# Instead, here we configure Jupyter to kill all kernels that have been alive for
# more than 12 hours. We also close all inactive terminals after 10 minutes.
ENV NOTEBOOK_ARGS \
     "--NotebookApp.default_url='/apps/apps/home/start.ipynb'" \
     "--Appmode.temp_dir=/home/${NB_USER}/.tmp_notebooks" \
     "--MappingKernelManager.buffer_offline_messages=True" \
     "--MappingKernelManager.cull_busy=True" \
     "--MappingKernelManager.cull_connected=True" \
     "--MappingKernelManager.cull_idle_timeout=64800" \
     "--MappingKernelManager.cull_interval=300" \
     "--TerminalManager.cull_inactive_timeout=3600" \
     "--TerminalManager.cull_interval=300"

# Set up the logo of notebook interface
ARG PYTHON_MINOR_VERSION
COPY --chown=${NB_UID}:${NB_GID} aiidalab-wide-logo.png ${CONDA_DIR}/lib/python${PYTHON_MINOR_VERSION}/site-packages/notebook/static/base/images/logo.png
