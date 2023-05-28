import pytest


def test_pw_executable_exist(aiidalab_exec, variant):
    """Test the rabbitmq-server can start, the output should be empty if
    the command is successful."""
    if "qe" not in variant:
        pytest.skip()
    output = aiidalab_exec("mamba run -n quantum-espresso-7.0 which pw.x")

    # assert output == b""
