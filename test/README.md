# test/

cocotb verification suites for TRI-ARGA.

## Running with make (Linux / CI)

```bash
source venv/bin/activate
make simon         # SIMON-32/64 cipher and CBC-MAC (2 tests, 49 vectors)
make l2            # L2 authentication and freshness (4 tests, 128 bit-flip checks)
make auth          # Integrated auth + commit (6 tests, TOCTOU regression)
make crc           # RF CRC streaming latency (1 test, comparison)
make wrapper       # Tiny Tapeout wrapper (6 tests)
make link-codec    # 8b/10b encoder/decoder (6 tests)
make link-framing  # comma, word lock, and timeout (2 tests)
make link-top      # serial link loopback through the boundary (5 tests)
```

Or run everything from the repository root:

```bash
make test
```

`make test` runs the archived RF appendix suite. The committed link is exercised by the `simon`, `l2`, `auth`, `wrapper`, and `link-*` targets.

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
| `run_project_test.py` / `make wrapper` | 6 | Key-load vs frame-load, key-lock, frame-before-key ignored |
| `make link-codec` | 6 | 8b/10b encode/decode, running disparity, code and disparity errors |
| `make link-framing` | 2 | K28.5 comma detect, word lock, timeout fault |
| `make link-top` | 5 | Loopback clean commit, forgery, replay, line-error, and 128/128 bit-flip rejection |
| `make crc` | 1 | RF CRC-24 streaming latency (integration comparison) |

## Contents

| File | Purpose |
| --- | --- |
| `test_simon.py` | SIMON-32/64 block cipher correctness |
| `test_l2_auth.py` | L2 CBC-MAC authentication and freshness |
| `test_auth_top.py` | Integrated `boundary_top` (L2 + L3 commit) |
| `test_project.py` | `tt_um_auth_boundary` wrapper |
| `test_link_codec.py` | 8b/10b encoder and decoder |
| `test_link_framing.py` | Link comma, word lock, and timeout |
| `test_link_top.py` | Serial link loopback through the boundary |
| `test_crc_latency.py` | RF CRC-24 streaming latency (integration comparison) |
| `simon_ref.py` | Pure-Python SIMON-32/64 reference implementation |
| `tb_simon.v`, `tb_l2_auth.v`, `tb_auth_top.v`, `tb_project.v`, `tb_crc.v` | Icarus Verilog testbenches for the core suites |
| `tb_link_codec.v`, `tb_link_framing.v`, `tb_link_top.v` | Icarus Verilog testbenches for the link suites |
| `run_simon_test.py`, `run_l2_test.py`, `run_auth_test.py`, `run_project_test.py` | Windows runners for the core suites |
| `vectors/` | Golden frame-level test vectors |

## Baselines

Expected results from `sim/RESULTS.md`:

| Suite | Pass | Latency |
| --- | --- | --- |
| simon | 2/2 | 33 cycles/block |
| l2 | 4/4 | 107 cycles (MAC + freshness) |
| auth | 6/6 | 108 cycles end-to-end |
| wrapper | 6/6 | - |
| link-codec | 6/6 | - |
| link-framing | 2/2 | - |
| link-top | 5/5 | 288 cycles end to end |
| crc | 1/1 | 73 cycles (CRC-24 streaming) |
