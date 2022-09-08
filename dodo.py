from pathlib import Path

DOIT_CONFIG = {"default_tasks": ["build"]}

_REGISTRY_PARAM = {
    "name": "registry",
    "short": "r",
    "long": "registry",
    "type": str,
    "default": "docker.io/",
    "help": "Specify the docker image registry.",
}


def task_build():
    """Build all docker images."""

    return {
        "actions": ["docker buildx bake -f docker-bake.hcl -f build.json"],
        "params": [_REGISTRY_PARAM],
        "verbosity": 2,
    }


def task_tests():
    """Run tests with pytest."""

    return {
        "actions": ["REGISTRY=%(registry)s pytest -v"],
        "params": [_REGISTRY_PARAM],
        "verbosity": 2,
    }


def task_up():
    """Start AiiDAlab server for testing."""
    return {
        "actions": [
            "AIIDALAB_PORT=%(port)i REGISTRY=%(registry)s docker-compose up --detach"
        ],
        "params": [
            {
                "name": "port",
                "short": "p",
                "long": "port",
                "type": int,
                "default": 8888,
                "help": "Specify the AiiDAlab host port.",
            },
            _REGISTRY_PARAM,
        ],
        "verbosity": 2,
    }


def task_down():
    """Stop AiiDAlab server."""
    return {"actions": ["docker-compose down"], "verbosity": 2}
