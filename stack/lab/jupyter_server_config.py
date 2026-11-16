import os

c = get_config()  # noqa: F821

# AiiDAlab uses nbclassic. Notebook 7 registers /terminals before nbclassic's
# handler and replaces the classic terminal page. Disable only its frontend
# extension; leave the installed packages and the JupyterLab interface intact.
c.ServerApp.jpserver_extensions = {"notebook": False}

# If the hub sets c.Spawner.default_url, it is passed through as $JUPYTERHUB_DEFAULT_URL.
# Otherwise, use default AiiDAlab home.
default_url = os.environ.get("JUPYTERHUB_DEFAULT_URL") or "/apps/apps/home/start.ipynb"

# jupyterhub-singleuser reads ServerApp, `jupyter nbclassic` reads NotebookApp.
c.ServerApp.default_url = default_url
c.NotebookApp.default_url = default_url

# Hide the banner about Notebook 7.
c.NotebookApp.show_banner = False

# A disconnected frontend makes the kernel buffer messages without limit, see
# https://github.com/aiidalab/issues/issues/13. Cull kernels after 18 h without
# activity, even busy or connected ones, and terminals after 1 h.
c.MappingKernelManager.buffer_offline_messages = True
c.MappingKernelManager.cull_busy = True
c.MappingKernelManager.cull_connected = True
c.MappingKernelManager.cull_idle_timeout = 64800
c.MappingKernelManager.cull_interval = 300
c.TerminalManager.cull_inactive_timeout = 3600
c.TerminalManager.cull_interval = 300
