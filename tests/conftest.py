import json
from pathlib import Path

import pytest
import requests

from requests.exceptions import ConnectionError


def is_responsive(url):
    try:
        response = requests.get(url)
        if response.status_code == 200:
            return True
    except ConnectionError:
        return False


@pytest.fixture(scope="session", params=["lab", "base-with-services"])
def variant(request):
    return request.param


@pytest.fixture(scope="session")
def docker_compose_file(pytestconfig, variant):
    return f"docker-compose.{variant}.yml"


@pytest.fixture(scope="session")
def notebook_service(docker_ip, docker_services):
    """Ensure that HTTP service is up and responsive."""
    port = docker_services.port_for("aiidalab", 8888)
    url = f"http://{docker_ip}:{port}"
    docker_services.wait_until_responsive(
        timeout=30.0, pause=0.1, check=lambda: is_responsive(url)
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
        return docker_compose.execute(command, **kwargs)

    return execute


@pytest.fixture
def nb_user(aiidalab_exec):
    return aiidalab_exec("bash -c 'echo \"${NB_USER}\"'").decode().strip()


@pytest.fixture(scope="session")
def _build_config():
    return json.loads(Path("build.json").read_text())["variable"]


@pytest.fixture(scope="session")
def aiida_version(_build_config):
    return _build_config["AIIDA_VERSION"]["default"]


@pytest.fixture(scope="session")
def aiidalab_version(_build_config):
    return _build_config["AIIDALAB_VERSION"]["default"]
