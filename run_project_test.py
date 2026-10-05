import warnings
warnings.filterwarnings("ignore")

import sys
import os
from pathlib import Path

from cocotb.runner import get_runner

ROOT = Path(__file__).parent
SRC  = ROOT / "src"
TEST = ROOT / "test"

sources = [
    SRC / "simon32_64.v",
    SRC / "l2_auth.v",
    SRC / "l3_commit_gatekeeper.v",
    SRC / "salaras_auth_top.v",
    SRC / "project.v",
    TEST / "tb_project.v",
]

runner = get_runner("icarus")
runner.build(
    sources=sources,
    hdl_toplevel="tb_project",
    includes=[str(SRC)],
    build_dir=str(ROOT / "sim_build" / "project"),
    always=True,
)
runner.test(
    hdl_toplevel="tb_project",
    test_module="test_project",
    test_dir=str(TEST),
    build_dir=str(ROOT / "sim_build" / "project"),
    results_xml=str(ROOT / "sim_build" / "project_results.xml"),
)
