import email
import json
import re

import pytest
import requests
from packaging.version import parse

# Tests in this file should pass for the following images
TESTED_TARGETS = ("lab", "full-stack")


@pytest.fixture(autouse=True)
def skip_if_incompatible_target(target):
    if target in TESTED_TARGETS:
        yield
    else:
        pytest.skip()


def test_correct_aiidalab_version_installed(package_info, aiidalab_version):
    info = package_info("aiidalab")
    assert parse(info["version"]) == parse(aiidalab_version)


def test_correct_aiidalab_home_version_installed(package_info, aiidalab_home_tag):
    info = package_info("aiidalab_home")
    # For debugging, aiidalab_home_tag can point to a branch or a commit,
    # in which case we cannot easily compare the versions.
    # We only try the comparison if the version starts with "v[0-9][0-9]",
    # at which point it's likely we're dealing with a version git tag.
    if re.match("v[0-9][0-9]", aiidalab_home_tag):
        assert parse(info["version"]) == parse(aiidalab_home_tag.removeprefix("v"))


def test_appmode_installed(aiidalab_exec):
    """Test that appmode pip package is installed in correct location"""
    output = aiidalab_exec("pip show appmode")

    # `pip show` output is in the RFC-compliant email header format
    msg = email.message_from_string(output)
    assert msg.get("Location").startswith("/opt/conda/lib/python")


def test_appmode_nbextension_enabled(aiidalab_exec):
    """Test that appmode frontend extension is enabled, otherwise apps hang on load"""
    output = aiidalab_exec("jupyter nbclassic-extension list")
    # Strip ANSI color codes
    output = re.sub(r"\x1b\[[0-9;]*m", "", output)
    assert re.search(r"appmode/main\s+enabled", output)


def test_classic_file_browser_and_terminal(notebook_service, aiidalab_exec):
    """Notebook 7 must not take over the classic terminal's URL."""
    server = json.loads(
        aiidalab_exec(
            'python -c "import json; '
            "from jupyter_server.serverapp import list_running_servers; "
            'print(json.dumps(next(list_running_servers())))"'
        )
    )
    with requests.Session() as session:
        if server["token"]:
            session.headers["Authorization"] = f"token {server['token']}"
        base_url = notebook_service + server["base_url"].rstrip("/")
        response = session.get(f"{base_url}/nbclassic/tree/", timeout=30)
        response.raise_for_status()
        assert 'id="notebook_list"' in response.text

        response = session.post(f"{base_url}/api/terminals", timeout=30)
        response.raise_for_status()
        name = response.json()["name"]
        try:
            response = session.get(f"{base_url}/terminals/{name}", timeout=30)
            response.raise_for_status()
            assert 'id="terminado-container"' in response.text
            assert "terminal/js/main.min.js" in response.text
        finally:
            response = session.delete(f"{base_url}/api/terminals/{name}", timeout=30)
            response.raise_for_status()


@pytest.mark.parametrize(
    "incompatible_package", ["aiidalab==22.7.1", "ipywidgets==7.7.4"]
)
@pytest.mark.parametrize("package_manager", ["pip", "mamba"])
def test_prevent_install_of_incompatible_packages(
    aiidalab_exec,
    nb_user,
    package_manager,
    incompatible_package,
):
    with pytest.raises(Exception):  # noqa: B017
        aiidalab_exec(f"{package_manager} install {incompatible_package}", user=nb_user)
