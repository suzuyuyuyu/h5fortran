from importlib.metadata import version
import h5xdmf
from h5xdmf import sample
from h5xdmf.schemes import CURRENT_SCHEME_VERSION, get_scheme


def test_distribution_and_module_versions_match():
    assert version("h5xdmf") == h5xdmf.__version__


def test_current_scheme_matches_product_major_version():
    product_major = int(h5xdmf.__version__.split(".", maxsplit=1)[0])
    assert CURRENT_SCHEME_VERSION == product_major
    assert get_scheme(CURRENT_SCHEME_VERSION).version == product_major
    assert sample.make_snapshot(
        0.0, ncells=(1, 1, 1), nparticles=0
    ).scheme_version == product_major
