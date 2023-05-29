import pytest


def test_pw_executable_exist(aiidalab_exec, qe_version, variant):
    """Test the rabbitmq-server can start, the output should be empty if
    the command is successful."""
    if "qe" not in variant:
        pytest.skip()
    output = aiidalab_exec(f"mamba run -n quantum-espresso-{qe_version} which pw.x")

    # assert output == b""
