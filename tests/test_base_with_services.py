"""Services related tests."""

import json
import pytest
from packaging.version import parse

# Tests in this file should pass for the following images
SUPPORTED_TARGETS = ("base-with-services", "full-stack")


@pytest.fixture(autouse=True)
def skip_if_no_password(target):
    if target in SUPPORTED_TARGETS:
        yield
    else:
        pytest.skip("Unsupported image")


def test_correct_pgsql_version_installed(aiidalab_exec, pgsql_version):
    cmd = "mamba list -n aiida-core-services --json --full-name postgresql"
    info = json.loads(aiidalab_exec(cmd))[0]
    assert info["name"] == "postgresql"
    assert parse(info["version"]).major == parse(pgsql_version).major


def test_rabbitmq_can_start(aiidalab_exec):
    """Test the rabbitmq-server can start, the output should be empty if
    the command is successful."""
    output = aiidalab_exec("mamba run -n aiida-core-services rabbitmq-server -detached")
    assert output == ""
