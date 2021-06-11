FROM aiidateam/aiida-core:1.6.3

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"

# Specify default factory reset (not set):
ENV AIIDALAB_FACTORY_RESET ""

# Configure environment.
ENV AIIDALAB_HOME /home/${SYSTEM_USER}
ENV AIIDALAB_APPS ${AIIDALAB_HOME}/apps
ENV AIIDALAB_DEFAULT_GIT_BRANCH master

# Specify which apps to install in addition to the home app. The
# AIIDALAB_DEFAULT_APPS variable should be a multiline variable where each line
# has the following format:
# <app name>@<git url>@<version>
# The version should be a reference that can be checked out via
# 'git checkout <version>'.
# Example for a properly formatted AIIDALAB_DEFAULT_APPS variable:
#   aiidalab-widgets-base@https://github.com/aiidalab/aiidalab-widgets-base@v1.0
#   quantum-espresso@https://github.com/aiidalab/aiidalab-qe@v1.1
# If no version is provided, it defaults to $AIIDALAB_DEFAULT_GIT_BRANCH.
ENV AIIDALAB_DEFAULT_APPS ""

USER root

# Install OS dependencies.
RUN apt-get update && apt-get install -y  \
    ca-certificates       \
    file                  \
    libssl-dev            \
    libffi-dev            \
    povray                \
    python3-pip           \
    python3-setuptools    \
    python3-wheel         \
  && rm -rf /var/lib/apt/lists/*

# Install what is needed for Jupyter Lab.
RUN apt-get update && apt-get install -y \
     nodejs                \
     npm                   \
  && rm -rf /var/lib/apt/lists/*

# Upgrade pip.
RUN /usr/bin/python3 -m pip install -U pip

# Install Jupyter-related things in the root environment.
RUN /usr/bin/pip3 install          \
    'jupyterhub==1.4.0'            \
    'jupyterlab==3.0.14'            \
    'notebook==6.3.0'

# Install ngrok to be able to proxy AiiDA RESTful API server.
RUN wget --quiet -P /tmp/ \
  https://bin.equinox.io/a/dnxFaDKQgP4/ngrok-2.3.35-linux-amd64.zip \
  && unzip /tmp/ngrok-2.3.35-linux-amd64.zip \
  && mv ./ngrok /usr/local/bin/ \
  && rm -f /tmp/ngrok-2.3.35-linux-amd64.zip

# Install jupyterlab theme (takes about 4 minutes and 10 seconds).
#WORKDIR /opt/jupyterlab-theme
#RUN git clone https://github.com/aiidalab/jupyterlab-theme && \
#    cd jupyterlab-theme && \
#     npm install && \
#     npm run build && \
#     npm run build:webpack && \
#     npm pack ./ && \ 
#     /usr/local/bin/jupyter labextension install *.tgz && \
#    cd ..

# Change workdir.
WORKDIR /opt/

# Install Python packages needed for AiiDAlab and populate reentry cache for root (https://pypi.python.org/pypi/reentry/).
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
RUN reentry scan

# Install python kernel from the conda environment (comes with the aiidalab package).
RUN python -m ipykernel install

# Install and enable nbserverproxy.
RUN /usr/bin/pip3 install nbserverproxy==0.8.8
RUN /usr/local/bin/jupyter serverextension enable --py --sys-prefix nbserverproxy

# Install and enable appmode.
RUN git clone https://github.com/oschuett/appmode.git && cd appmode && git reset --hard v0.8.0
COPY gears.svg ./appmode/appmode/static/gears.svg
RUN /usr/bin/pip3 install ./appmode
RUN /usr/local/bin/jupyter nbextension     enable --py --sys-prefix appmode
RUN /usr/local/bin/jupyter serverextension enable --py --sys-prefix appmode

# Install voila package and AiiDAlab voila template.
RUN /usr/bin/pip3 install voila==0.2.10
RUN /usr/bin/pip3 install voila-aiidalab-template==0.2.1

# Install widgets for enabling them in Jupyter.
RUN /usr/bin/pip3 install \
    bqplot==0.12.25 \
    ipytree==0.1.8 \
    ipywidgets-extended==1.0.5  \
    nglview==2.7.7 \
    widget-periodictable==2.1.5 \
    && /usr/bin/pip3 cache purge

# Install some useful packages that are not available on PyPi.
# The 2020.09.2 version of rdkit introduced an implicit dependency on tornado>=6.
RUN conda install --yes -c conda-forge \
  openbabel==3.1.1 \
  rdkit==2020.09.1 \
  && conda clean --all

# Perform factory reset if needed.
COPY my_init.d/factory_reset.sh /etc/my_init.d/09_factory_reset.sh

# Prepare user's folders for AiiDAlab launch.
COPY opt/aiidalab-singleuser /opt/
COPY opt/prepare-aiidalab.sh /opt/
COPY my_init.d/prepare-aiidalab.sh /etc/my_init.d/80_prepare-aiidalab.sh

# Get aiidalab-home app.
RUN git clone https://github.com/aiidalab/aiidalab-home && cd aiidalab-home && git reset --hard v21.05.0
RUN chmod 774 aiidalab-home

# Copy scripts to start Jupyter notebook.
COPY opt/start-notebook.sh /opt/
COPY service/jupyter-notebook /etc/service/jupyter-notebook/run

# Expose port 8888.
EXPOSE 8888

# Remove when the following issue is fixed: https://github.com/jupyterhub/dockerspawner/issues/319.
COPY my_my_init /sbin/my_my_init

CMD ["/sbin/my_my_init"]
