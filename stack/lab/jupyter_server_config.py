import os

c = get_config()  # noqa: F821

# If the hub sets c.Spawner.default_url, it is passed through as $JUPYTERHUB_DEFAULT_URL.
# Otherwise, use default AiiDAlab home.
default_url = os.environ.get("JUPYTERHUB_DEFAULT_URL") or "/apps/apps/home/start.ipynb"

# jupyterhub-singleuser reads ServerApp, `jupyter nbclassic` reads NotebookApp.
c.ServerApp.default_url = default_url
c.NotebookApp.default_url = default_url
