ARG BASE
FROM ${BASE}

LABEL maintainer="AiiDAlab Team <aiidalab@materialscloud.org>"

USER root

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    # for apps which need to install pymatgen:
    # https://pymatgen.org/installation.html#installation-tips-for-optional-libraries
    build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/

ARG AIIDA_VERSION
ARG PYTHON_VERSION

# Install the shared requirements.
COPY requirements.txt .
RUN echo "aiida-core==${AIIDA_VERSION}" >> requirements.txt
RUN echo "python==${PYTHON_VERSION}" >> requirements.txt
# Install separate environment for aiida-core/aiidalab
RUN mamba create --name aiida-base
RUN mamba install -n aiida-base --yes \
     --file requirements.txt \
     && mamba clean --all -f -y && \
     fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

# https://docs.jupyter.org/en/latest/use/jupyter-directories.html#envvar-JUPYTER_PATH
ENV JUPYTER_PATH=/home/${NB_USER}/.conda/aiida-homebase

# Pin shared requirements in the base environemnt.
# TODO: These should be pinned in aiida-base as well
RUN cat requirements.txt | xargs -I{} conda config --system --add pinned_packages {}

# Configure pip to use requirements file as constraints file.
ENV PIP_CONSTRAINT=/opt/requirements.txt

# Enable verdi autocompletion.
RUN mkdir -p "${CONDA_DIR}/envs/aiida-base/etc/conda/activate.d" && \
     echo 'eval "$(_VERDI_COMPLETE=bash_source verdi)"' >> "${CONDA_DIR}/envs/aiida-base/etc/conda/activate.d/activate_aiida_autocompletion.sh" && \
     chmod +x "${CONDA_DIR}/envs/aiida-base/etc/conda/activate.d/activate_aiida_autocompletion.sh" && \
     fix-permissions "${CONDA_DIR}"/envs/aiida-base

# Configure AiiDA profile.
COPY config-quick-setup.yaml .
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/

# Configure AiiDA.
ENV SETUP_DEFAULT_AIIDA_PROFILE true
ENV AIIDA_PROFILE_NAME default
ENV AIIDA_USER_EMAIL aiida@localhost
ENV AIIDA_USER_FIRST_NAME Giuseppe
ENV AIIDA_USER_LAST_NAME Verdi
ENV AIIDA_USER_INSTITUTION Khedivial

# Install the load-singlesshagent.sh script as described here:
# https://aiida.readthedocs.io/projects/aiida-core/en/v2.0.0/howto/ssh.html#starting-the-ssh-agent
# The startup of this script is configured in the before-notebook.d/10_setup-ssh.sh file.
RUN wget --quiet --directory-prefix=/opt/bin/ \
     "https://aiida.readthedocs.io/projects/aiida-core/en/v${AIIDA_VERSION}/_downloads/4265ec5a42c3a3dba586dd460c0db95e/load-singlesshagent.sh" \
     && echo $'\n# Load singlesshagent on shell startup.\n\
if [ -f /opt/bin/load-singlesshagent.sh ]; then\n\
   . /opt/bin/load-singlesshagent.sh\n\
fi\n' >> "/home/${NB_USER}/.bashrc"

# Switch to aiida-base conda environment by default
#RUN echo "conda activate aiida-base" >> "/home/${NB_USER}/.bashrc"

# Install ipykernel from aiida-base environment,
# remove the default python3 kernel
RUN mamba run -n aiida-base ipython kernel install --user --name=aiidalab
RUN mamba run -n aiida-base jupyter kernelspec remove -y python3

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"

# The vim.tiny shipped with jupyter base stack start vim
# in compatible mode, by creating `.vimrc` file in user home
# make it nocompatible mode so the modern vim features is available:
# https://superuser.com/questions/543317/what-is-compatible-mode-in-vim/543327#543327
RUN echo -e "set nocp\nset noai\nfiletype plugin on\nsyntax on" > .vimrc
