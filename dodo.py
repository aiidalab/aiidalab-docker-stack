from pathlib import Path

ORG = "aiidalab"
VER = "latest"

DOIT_CONFIG = {"default_tasks": ["build"]}


def task_build():
    """Build all docker images."""

    contexts = [p.parent for p in Path("stack").glob("*/Dockerfile")]

    for context in contexts:
        image = f"{ORG}/{context.name}:{VER}"

        deps = [p for p in context.glob("**/*") if p.is_file()]

        yield {
            "name": image,
            "actions": [f"docker build -t {image} {context}"],
            "file_dep": deps,
            "verbosity": 2,
        }


def task_tests():
    """Run tests with pytest."""

    return {"actions": ["pytest"]}


def task_up():
    """Start AiiDAlab server for testing."""

    return {"actions": ["docker-compose up --detach"], "verbosity": 2}
