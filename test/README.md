# test/

cocotb verification suites for TRI-ARGA.

## Running with make (Linux / CI)

```bash
source venv/bin/activate
make simon    # SIMON-32/64 cipher and CBC-MAC (2 tests, 49 vectors)
make l2       # L2 authentication and freshness (4 tests, 128 bit-flip checks)
make auth     # Integrated auth + commit (6 tests, TOCTOU regression)
make wrapper  # Tiny Tapeout wrapper (5 tests)
```

Or run everything from the repository root:

```bash
make test
```

## Running on Windows (no make)

```bash
source venv/Scripts/activate      # or venv\Scripts\activate.bat
python test/run_simon_test.py
python test/run_l2_test.py
python test/run_auth_test.py
python test/run_project_test.py
```

Each script uses the `cocotb.runner` API with Icarus Verilog directly.

## Suites

| Script / target | Tests | Key coverage |
| --- | --- | --- |
| `run_simon_test.py` / `make simon` | 2 | 49 vectors (1 published + 48 random), CBC-MAC |
| `run_l2_test.py` / `make l2` | 4 | 128/128 single-bit flips rejected, 20 clean frames, replay, wrong key |
| `run_auth_test.py` / `make auth` | 6 | 108-cycle end-to-end latency, TOCTOU regression, sticky fault |
| `run_project_test.py` / `make wrapper` | 5 | Key-load vs frame-load, key-lock, frame-before-key ignored |

## Contents

| File | Purpose |
| --- | --- |
| `test_simon.py` | SIMON-32/64 block cipher correctness |
| `test_l2_auth.py` | L2 CBC-MAC authentication and freshness |
| `test_auth_top.py` | Integrated `boundary_top` (L2 + L3 commit) |
| `test_project.py` | `tt_um_auth_boundary` wrapper |
| `simon_ref.py` | Pure-Python SIMON-32/64 reference implementation |
| `tb_simon.v` | Icarus Verilog testbench for SIMON |
| `tb_l2_auth.v` | Icarus Verilog testbench for L2 |
| `tb_auth_top.v` | Icarus Verilog testbench for auth top |
| `tb_project.v` | Icarus Verilog testbench for TT wrapper |
| `run_simon_test.py` | Windows runner for SIMON suite |
| `run_l2_test.py` | Windows runner for L2 suite |
| `run_auth_test.py` | Windows runner for auth suite |
| `run_project_test.py` | Windows runner for wrapper suite |
| `vectors/` | Golden frame-level test vectors |

## Baselines

Expected results from `sim/RESULTS.md`:

| Suite | Pass | Latency |
| --- | --- | --- |
| simon | 2/2 | 33 cycles/block |
| l2 | 4/4 | 107 cycles (MAC + freshness) |
| auth | 6/6 | 108 cycles end-to-end |
| wrapper | 5/5 | - |
