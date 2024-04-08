import pytest
import json
from packaging.version import parse


def test_correct_aiidalab_version_installed(aiidalab_exec, aiidalab_version):
    cmd = "mamba list --json --full-name aiidalab"
    info = json.loads(aiidalab_exec(cmd))[0]
    assert info["name"] == "aiidalab"
    assert parse(info["version"]) == parse(aiidalab_version)


def test_correct_aiidalab_home_version_installed(aiidalab_exec, aiidalab_home_version):
    cmd = "mamba list --json --full-name aiidalab-home"
    info = json.loads(aiidalab_exec(cmd))[0]
    assert info["name"] == "aiidalab-home"
    assert parse(info["version"]) == parse(aiidalab_home_version)


def test_appmode_installed(aiidalab_exec):
    """Test that appmode pip package is installed in correct location"""
    import email

    output = aiidalab_exec("pip show appmode")

    # `pip show` output is in the RFC-compliant email header format
    msg = email.message_from_string(output)
    assert msg.get("Location").startswith("/opt/conda/lib/python")


@pytest.mark.parametrize("incompatible_version", ["22.7.1"])
def test_prevent_pip_install_of_incompatible_aiidalab_version(
    aiidalab_exec,
    nb_user,
    incompatible_version,
):
    package_manager = "pip"
    with pytest.raises(Exception):
        aiidalab_exec(
            f"{package_manager} install aiidalab=={incompatible_version}", user=nb_user
        )
