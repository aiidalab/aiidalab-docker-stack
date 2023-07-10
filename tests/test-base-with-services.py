"""Services related tests."""
import json
from packaging.version import parse


def test_correct_pgsql_version_installed(aiidalab_exec, pgsql_version):
    info = json.loads(
        aiidalab_exec(
            "mamba list -n aiida-core-services --json --full-name postgresql"
        ).decode()
    )[0]
    assert info["name"] == "postgresql"
    assert parse(info["version"]).major == parse(pgsql_version).major


def test_rabbitmq_can_start(aiidalab_exec):
    """Test the rabbitmq-server can start, the output should be empty if
    the command is successful."""
    output = aiidalab_exec("mamba run -n aiida-core-services rabbitmq-server -detached")

    assert output == b""
