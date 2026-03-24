import email
import json

import pytest
from packaging.version import parse

# Tests in this file should pass for the following images
TESTED_TARGETS = ("lab", "full-stack")


@pytest.fixture(autouse=True)
def skip_if_incompatible_target(target):
    if target in TESTED_TARGETS:
        yield
    else:
        pytest.skip()


def test_correct_aiidalab_version_installed(aiidalab_exec, aiidalab_version):
    cmd = "mamba list --json --full-name aiidalab"
    info = json.loads(aiidalab_exec(cmd))[0]
    assert info["name"] == "aiidalab"
    assert parse(info["version"]) == parse(aiidalab_version)


def test_correct_aiidalab_home_version_installed(aiidalab_exec, aiidalab_home_version):
    cmd = "mamba list --json --full-name aiidalab-home"
    info = json.loads(aiidalab_exec(cmd))[0]
    assert info["name"] == "aiidalab-home"
    # For debugging, aiidalab_home_version can point to a branch or a commit,
    # in which case we cannot easily compare the versions.
    # We only try the comparison if the version starts with "v",
    # (obviously, this is not super-robust heuristic,
    # since it cannot distinguish from branch names starting with "v",
    # but let's not over-engineer this for now.
    if aiidalab_home_version.startswith("v"):
        assert parse(info["version"]) == parse(aiidalab_home_version.removeprefix("v"))


def test_appmode_installed(aiidalab_exec):
    """Test that appmode pip package is installed in correct location"""
    output = aiidalab_exec("pip show appmode")

    # `pip show` output is in the RFC-compliant email header format
    msg = email.message_from_string(output)
    assert msg.get("Location").startswith("/opt/conda/lib/python")


@pytest.mark.parametrize(
    "incompatible_package", ["aiidalab==22.7.1", "ipywidgets==8.0.0"]
)
@pytest.mark.parametrize("package_manager", ["pip", "mamba"])
def test_prevent_install_of_incompatible_packages(
    aiidalab_exec,
    nb_user,
    package_manager,
    incompatible_package,
):
    with pytest.raises(Exception):
        aiidalab_exec(f"{package_manager} install {incompatible_package}", user=nb_user)
