import warnings
warnings.filterwarnings("ignore")

from pathlib import Path
from cocotb.runner import get_runner

ROOT = Path(__file__).parent
SRC  = ROOT / "src"
TEST = ROOT / "test"

sources = [SRC / "simon32_64.v", TEST / "tb_simon.v"]

runner = get_runner("icarus")
runner.build(
    sources=sources,
    hdl_toplevel="tb_simon",
    includes=[str(SRC)],
    build_dir=str(ROOT / "sim_build" / "simon"),
    always=True,
)
runner.test(
    hdl_toplevel="tb_simon",
    test_module="test_simon",
    test_dir=str(TEST),
    build_dir=str(ROOT / "sim_build" / "simon"),
    results_xml=str(ROOT / "sim_build" / "simon_results.xml"),
)
