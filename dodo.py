from pathlib import Path

DOIT_CONFIG = {"default_tasks": ["build"]}


def task_build():
    """Build all docker images."""

    return {"actions": ["docker buildx bake"], "verbosity": 2}


def task_tests():
    """Run tests with pytest."""

    return {"actions": ["pytest -v"], "verbosity": 2}


def task_up():
    """Start AiiDAlab server for testing."""
    return {
        "actions": ["AIIDALAB_PORT=%(port)i docker-compose up --detach"],
        "params": [
            {
                "name": "port",
                "short": "p",
                "long": "port",
                "type": int,
                "default": 8888,
                "help": "Specify the AiiDAlab host port.",
            },
        ],
        "verbosity": 2,
    }


def task_down():
    """Stop AiiDAlab server."""
    return {"actions": ["docker-compose down"], "verbosity": 2}
