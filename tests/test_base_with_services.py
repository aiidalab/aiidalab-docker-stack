"""Services related tests."""

import json

import pytest
from packaging.version import parse

# Tests in this file should pass for the following images
TESTED_TARGETS = ("base-with-services", "full-stack")


@pytest.fixture(autouse=True)
def skip_if_incompatible_target(target):
    if target in TESTED_TARGETS:
        yield
    else:
        pytest.skip()


def test_pgsql_version(aiidalab_exec, pgsql_version):
    cmd = "mamba list -n aiida-core-services --json --full-name postgresql"
    info = json.loads(aiidalab_exec(cmd))[0]
    assert info["name"] == "postgresql"
    assert parse(info["version"]).major == parse(pgsql_version).major


def test_rabbitmq_version(aiidalab_exec, rabbitmq_version):
    cmd = "mamba list -n aiida-core-services --json --full-name rabbitmq-server"
    info = json.loads(aiidalab_exec(cmd))[0]
    assert info["name"] == "rabbitmq-server"
    assert parse(info["version"]) == parse(rabbitmq_version)


def test_rabbitmq_config_file(aiidalab_exec):
    """Test that rabbitmq-server picks up the provided config file
    with consumer_timeout"""
    output = aiidalab_exec(
        "mamba run -n aiida-core-services rabbitmq-diagnostics status | grep -A2 'Config files' | tail -1"
    )
    assert output.rstrip().endswith("advanced.config")


def test_rabbitmq_consumer_timeout_config(aiidalab_exec):
    """Test that rabbitmq-server picks up the provided config file
    with consumer_timeout"""
    output = aiidalab_exec(
        "mamba run -n aiida-core-services rabbitmqctl environment | grep consumer_timeout"
    )
    assert "consumer_timeout,undefined" in output
