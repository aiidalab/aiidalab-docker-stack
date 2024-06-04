"""Simple workflow example"""

from aiida import orm
from aiida.engine import Process, calcfunction, submit, workfunction
from aiida.plugins import CalculationFactory, DataFactory, DbImporterFactory

# Load the calculation class 'PwCalculation' using its entry point 'quantumespresso.pw'
PwCalculation = CalculationFactory("quantumespresso.pw")
KpointsData = DataFactory("array.kpoints")


def generate_scf_input_params(structure, code, pseudo_family):
    """Construct a builder for the `PwCalculation` class and populate its inputs.

    :return: `ProcessBuilder` instance for `PwCalculation` with preset inputs
    """
    parameters = {
        "CONTROL": {
            "calculation": "scf",
            "tstress": True,  # Important that this stays to get stress
            "tprnfor": True,
        },
        "SYSTEM": {
            "ecutwfc": 30.0,
            "ecutrho": 200.0,
        },
        "ELECTRONS": {
            "conv_thr": 1.0e-6,
        },
    }

    kpoints = KpointsData()
    kpoints.set_kpoints_mesh([2, 2, 2])

    builder = PwCalculation.get_builder()
    builder.code = code
    builder.structure = structure
    builder.kpoints = kpoints
    builder.parameters = orm.Dict(dict=parameters)
    builder.pseudos = pseudo_family.get_pseudos(structure=structure)
    builder.metadata.options.resources = {"memory_mb": 1200, "num_cpus": 1}
    builder.metadata.options.max_wallclock_seconds = 30 * 60

    return builder


@calcfunction
def rescale(structure, scale):
    """Calculation function to rescale a structure

    :param structure: An AiiDA `StructureData` to rescale
    :param scale: The scale factor (for the lattice constant)
    :return: The rescaled structure
    """
    from aiida.orm import StructureData

    ase_structure = structure.get_ase()
    scale_value = scale.value

    new_cell = ase_structure.get_cell() * scale_value
    ase_structure.set_cell(new_cell, scale_atoms=True)

    return StructureData(ase=ase_structure)


@calcfunction
def create_eos_dictionary(**kwargs):
    """Create a single `Dict` node from the `Dict` output parameters of completed `PwCalculations`.

    The dictionary will contain a list of tuples, where each tuple contains the volume, total energy and its units
    of the results of a calculation.

    :return: `Dict` node with the equation of state results
    """
    eos = [
        (result.dict.volume, result.dict.energy, result.dict.energy_units)
        for label, result in kwargs.items()
    ]
    return orm.Dict(dict={"eos": eos})


@workfunction
def run_eos_wf(code, pseudo_family_label, structure):
    """Run an equation of state of a bulk crystal structure for the given element."""

    # This will print the pk of the work function
    print(f"Running run_eos_wf<{Process.current().pid}>")

    scale_factors = (0.94, 0.96, 0.98, 1.0, 1.02, 1.04, 1.06)
    labels = ["c1", "c2", "c3", "c4", "c5", "c6", "c7"]
    pseudo_family = orm.load_group(pseudo_family_label.value)

    calculations = {}

    # Loop over the label and scale_factor pairs
    for label, factor in list(zip(labels, scale_factors)):
        # Generated the scaled structure from the initial structure
        rescaled_structure = rescale(structure, orm.Float(factor))

        # Generate the inputs for the `PwCalculation`
        inputs = generate_scf_input_params(rescaled_structure, code, pseudo_family)

        # Launch a `PwCalculation` for each scaled structure
        print(f"Running a scf for {structure.get_formula()} with scale factor {factor}")
        calculations[label] = submit(PwCalculation, **inputs)

    ## Bundle the individual results from each `PwCalculation` in a single dictionary node.
    ## Note: since we are 'creating' new data from existing data, we *have* to go through a `calcfunction`, otherwise
    ## the provenance would be lost!
    # inputs = {
    #    label: result["output_parameters"] for label, result in calculations.items()
    # }
    # eos = create_eos_dictionary(**inputs)

    ## Finally, return the eos Dict node
    # return eos


# load structure from COD
CodDbImporter = DbImporterFactory("cod")
cod = CodDbImporter()
structure = cod.query(id="1526655")[0].get_aiida_structure()

# If it is a cif file can import in CLI as
# verdi data core.structure import ase /opt/examples/Si.cif

# Code
code = orm.load_code("pw-7.2@localhost-hq")

# Pseudo
pseudo_family_label = orm.Str("SSSP/1.3/PBE/precision")

# Launch the workflow
# result = run_eos_wf(code, pseudo_family_label, structure)
# print(result)
run_eos_wf(code, pseudo_family_label, structure)
