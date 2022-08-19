from pathlib import Path

from build import get_docker_build_args, get_organization, get_tags, get_version

DOIT_CONFIG = {"default_tasks": ["build"]}


def task_build():
    """Build all docker images."""

    contexts = [p.parent for p in sorted(Path("stack").glob("*/Dockerfile"))]
    organization = get_organization()
    version = get_version()  # The version of the stack.

    for context in contexts:
        image = f"{organization}/{context.name}"

        build_action = ["docker", "build"]
        build_action.extend([f"-t {image}:{tag}" for tag in get_tags()])
        build_action.extend(f"--build-arg {arg}" for arg in get_docker_build_args())
        build_action.append(str(context))
        build_action = " ".join(build_action)

        deps = ["build.yml", "build.py"] + [
            p for p in context.glob("**/*") if p.is_file()
        ]

        yield {
            "name": f"{image}:{version}",
            "actions": [build_action],
            "file_dep": deps,
            "verbosity": 2,
        }


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
