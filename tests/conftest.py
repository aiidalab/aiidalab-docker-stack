import json
from pathlib import Path

import pytest
import requests

from requests.exceptions import ConnectionError

VARIANTS = ("base", "lab", "base-with-services", "full-stack")


def is_responsive(url):
    try:
        response = requests.get(url)
        if response.status_code == 200:
            return True
    except ConnectionError:
        return False


def variant_checker(value):
    msg = f"Invalid image variant '{value}', must be one of: {VARIANTS}"
    if value not in VARIANTS:
        raise pytest.UsageError(msg)
    return value


def pytest_addoption(parser):
    parser.addoption(
        "--variant",
        action="store",
        required=True,
        help="Variant (image name) of the docker-compose file to use.",
        type=variant_checker,
    )


@pytest.fixture(scope="session")
def docker_compose_file(pytestconfig):
    variant = pytestconfig.getoption("variant")
    return f"stack/docker-compose.{variant}.yml"


@pytest.fixture(scope="session")
def notebook_service(docker_ip, docker_services):
    """Ensure that HTTP service is up and responsive."""
    port = docker_services.port_for("aiidalab", 8888)
    url = f"http://{docker_ip}:{port}"
    docker_services.wait_until_responsive(
        timeout=60.0, pause=0.1, check=lambda: is_responsive(url)
    )
    return url


@pytest.fixture(scope="session")
def docker_compose(docker_services):
    return docker_services._docker_compose


@pytest.fixture
def aiidalab_exec(docker_compose):
    def execute(command, user=None, **kwargs):
        if user:
            command = f"exec -T --user={user} aiidalab {command}"
        else:
            command = f"exec -T aiidalab {command}"
        out = docker_compose.execute(command, **kwargs)
        return out.decode()

    return execute


@pytest.fixture
def nb_user(aiidalab_exec):
    return aiidalab_exec("bash -c 'echo \"${NB_USER}\"'").strip()


@pytest.fixture(scope="session")
def _build_config():
    return json.loads(Path("build.json").read_text())["variable"]


@pytest.fixture(scope="session")
def python_version(_build_config):
    return _build_config["PYTHON_VERSION"]["default"]


@pytest.fixture(scope="session")
def pgsql_version(_build_config):
    return _build_config["PGSQL_VERSION"]["default"]


@pytest.fixture(scope="session")
def aiida_version(_build_config):
    return _build_config["AIIDA_VERSION"]["default"]


@pytest.fixture(scope="session")
def aiidalab_version(_build_config):
    return _build_config["AIIDALAB_VERSION"]["default"]


@pytest.fixture(scope="session")
def aiidalab_home_version(_build_config):
    return _build_config["AIIDALAB_HOME_VERSION"]["default"]
