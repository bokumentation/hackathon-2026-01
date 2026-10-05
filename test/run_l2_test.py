import warnings
warnings.filterwarnings("ignore")

from pathlib import Path
from cocotb.runner import get_runner

ROOT = Path(__file__).parent.parent
SRC  = ROOT / "src"
TEST = ROOT / "test"

sources = [SRC / "simon32_64.v", SRC / "l2_auth.v", TEST / "tb_l2_auth.v"]

runner = get_runner("icarus")
runner.build(
    sources=sources,
    hdl_toplevel="tb_l2_auth",
    includes=[str(SRC)],
    build_dir=str(ROOT / "sim_build" / "l2"),
    always=True,
)
runner.test(
    hdl_toplevel="tb_l2_auth",
    test_module="test_l2_auth",
    test_dir=str(TEST),
    build_dir=str(ROOT / "sim_build" / "l2"),
    results_xml=str(ROOT / "sim_build" / "l2_results.xml"),
)
