import json
from pathlib import Path
import os

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


@pytest.fixture(scope="session", params=["full-stack", "lab", "qe"])
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
    token = os.environ["JUPYTER_TOKEN"]
    docker_services.wait_until_responsive(
        timeout=60.0, pause=0.1, check=lambda: is_responsive(url)
    )
    return url, token


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


@pytest.fixture(scope="session")
def qe_version(_build_config):
    return _build_config["QE_VERSION"]["default"]


@pytest.fixture(scope="function")
def generate_aiidalab_install_output(aiidalab_exec, nb_user):
    def _generate_aiidalab_install_output(package_name):
        output = (
            aiidalab_exec(f"aiidalab install --yes {package_name}", user=nb_user)
            .decode()
            .strip()
        )

        output += aiidalab_exec(f"pip check", user=nb_user).decode().strip()

        # Uninstall the package to make sure the test is repeatable
        app_name = package_name.split("@")[0]
        aiidalab_exec(f"aiidalab uninstall --yes --force {app_name}", user=nb_user)

        return output

    return _generate_aiidalab_install_output
