def test_pw_executable_exist(aiidalab_exec, qe_version):
    """Test that pw.x executable exists in the conda environment"""
    output = (
        aiidalab_exec(f"mamba run -n quantum-espresso-{qe_version} which pw.x")
        .decode()
        .strip()
    )

    assert output == f"/home/jovyan/.conda/envs/quantum-espresso-{qe_version}/bin/pw.x"
