# syntax=docker/dockerfile:1
FROM base

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"


# By default, Jupyter Docker image launches the JupyterLab interface.
# Here, we change it to the classic Jupyter Notebook which is used by AiiDAlab.
# In the future, we might want to switch to other options such as `nbclassic` or `retro`,
# but the `nbclassic` is not supported because of appmode.
# see: https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html#switching-back-to-the-classic-notebook-or-using-a-different-startup-command
ENV DOCKER_STACKS_JUPYTER_CMD=notebook

USER root
WORKDIR /opt/

# Install additional system packages
RUN apt-get update --yes && \
     apt-get install --yes --no-install-recommends \
     curl \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/*

# Install aiidalab package
ARG AIIDALAB_VERSION=22.08.0
RUN mamba install --yes \
     aiidalab=${AIIDALAB_VERSION} \
     && mamba clean --all -f -y && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

# Pin aiidalab version.
RUN echo "aiidalab==${AIIDALAB_VERSION}" >> /opt/requirements.txt
RUN conda config --system --add pinned_packages "aiidalab=${AIIDALAB_VERSION}"

# Install the aiidalab-home app.
ARG AIIDALAB_HOME_VERSION=v22.08.0
RUN git clone https://github.com/aiidalab/aiidalab-home && \
     cd aiidalab-home && \
     git checkout "${AIIDALAB_HOME_VERSION}" && \
     pip install --quiet --no-cache-dir "./" && \
     fix-permissions "./" && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

# Install and enable appmode.
RUN git clone https://github.com/oschuett/appmode.git && \
     cd appmode && \
     git checkout v0.8.0
COPY gears.svg ./appmode/appmode/static/gears.svg
RUN pip install ./appmode --no-cache-dir && \
     jupyter nbextension enable --py --sys-prefix appmode && \
     jupyter serverextension enable --py --sys-prefix appmode

# Copy start-up scripts for AiiDAlab.
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/

# Configure AiiDAlab environment.
ENV AIIDALAB_HOME /home/${NB_USER}
ENV AIIDALAB_APPS ${AIIDALAB_HOME}/apps
ENV AIIDALAB_DEFAULT_GIT_BRANCH master

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
ENV AIIDALAB_DEFAULT_APPS ""

# Specify default factory reset (not set):
ENV AIIDALAB_FACTORY_RESET ""

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"

RUN  mkdir -p /home/${NB_USER}/apps

ENV NOTEBOOK_ARGS \
     "--NotebookApp.default_url='/apps/apps/home/start.ipynb'" \
     "--ContentsManager.allow_hidden=True"
