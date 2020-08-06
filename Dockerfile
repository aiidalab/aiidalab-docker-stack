FROM aiidateam/aiida-core:1.3.0

LABEL maintainer="Materials Cloud Team <aiidalab@materialscloud.org>"

# Configure environment.
ENV AIIDALAB_HOME /home/${SYSTEM_USER}
ENV AIIDALAB_APPS ${AIIDALAB_HOME}/apps
ENV AIIDALAB_DEFAULT_GIT_BRANCH master

USER root

# Install OS dependencies.
RUN apt-get update && apt-get install -y  \
    ca-certificates       \
    cp2k                  \
    file                  \
    libssl-dev            \
    libffi-dev            \
    python3-pip           \
    python3-setuptools    \
    python3-wheel         \
    quantum-espresso      \
  && rm -rf /var/lib/apt/lists/*

# Install what is needed for Jupyter Lab.
RUN apt-get update && apt-get install -y \
     nodejs                \
     npm                   \
  && rm -rf /var/lib/apt/lists/*

# Install Jupyter-related things in the root environment.
RUN /usr/bin/pip3 install          \
    'jupyterhub==1.1.0'            \
    'jupyterlab==2.2.2'            \
    'notebook==6.0.3'

# Quantum-Espresso Pseudo Potentials.
# TODO, remove when https://github.com/aiidateam/aiida-sssp/pull/25 is merged
# and installed on AiiDA lab
WORKDIR /opt/pseudos
RUN base_url=http://legacy-archive.materialscloud.org/file/2018.0001/v3;  \
wget ${base_url}/SSSP_efficiency_pseudos.aiida;                           \
wget ${base_url}/SSSP_precision_pseudos.aiida;                            \
chown -R root:root /opt/pseudos/;                                         \
chmod -R +r /opt/pseudos/

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

# Install Python packages needed for AiiDA lab and populate reentry cache for root (https://pypi.python.org/pypi/reentry/).
RUN pip install 'aiidalab==v20.08.0b0'
#RUN python -m pip install git+https://github.com/aiidalab/aiidalab.git@fd6b0914dba28b96f117b0cd078740f2b92e4aa9
RUN reentry scan

# Install python kernel from the conda environment (comes with the aiidalab package).
RUN python -m ipykernel install

# Install and enable nbserverproxy.
RUN /usr/bin/pip3 install nbserverproxy==0.8.8
RUN /usr/local/bin/jupyter serverextension enable --py --sys-prefix nbserverproxy

# Install and enable nglview.
RUN /usr/bin/pip3 install nglview==2.7.7
RUN /usr/local/bin/jupyter nbextension enable nglview --py --sys-prefix

# Install and enable appmode.
WORKDIR /opt/
RUN git clone https://github.com/oschuett/appmode.git && cd appmode && git reset --hard 8665aa6474164023a9f59a3744ee5ffe5c3a8b4a
COPY gears.svg ./appmode/appmode/static/gears.svg
RUN /usr/bin/pip3 install ./appmode
RUN /usr/local/bin/jupyter nbextension     enable --py --sys-prefix appmode
RUN /usr/local/bin/jupyter serverextension enable --py --sys-prefix appmode

# Install and enable bqplot.
RUN /usr/bin/pip3 install bqplot
RUN /usr/local/bin/jupyter nbextension install --py --symlink --sys-prefix bqplot
RUN /usr/local/bin/jupyter nbextension enable bqplot --py --sys-prefix

# Install voila package and AiiDA lab voila template.
RUN /usr/bin/pip3 install voila==0.1.21
RUN /usr/bin/pip3 install voila-aiidalab-template==0.0.2

# Enable widget_periodictable (installed with aiidalab package).
RUN /usr/bin/pip3 install widget-periodictable==2.1.2
RUN /usr/local/bin/jupyter nbextension install --py --user widget_periodictable
RUN /usr/local/bin/jupyter nbextension enable widget_periodictable --user --py

# Install some useful packages that are not available on PyPi
RUN conda install --yes -c conda-forge rdkit
RUN conda install --yes -c openbabel openbabel
RUN conda install --yes -c conda-forge dscribe "tornado<5"

# Prepare user's folders for AiiDA lab launch.
COPY opt/aiidalab-singleuser /opt/
COPY opt/prepare-aiidalab.sh /opt/
COPY my_init.d/prepare-aiidalab.sh /etc/my_init.d/80_prepare-aiidalab.sh

# Copy scripts to start Jupyter notebook.
COPY opt/start-notebook.sh /opt/
COPY service/jupyter-notebook /etc/service/jupyter-notebook/run

# Expose port 8888.
EXPOSE 8888

# Remove when the following issue is fixed: https://github.com/jupyterhub/dockerspawner/issues/319.
COPY my_my_init /sbin/my_my_init

CMD ["/sbin/my_my_init"]
