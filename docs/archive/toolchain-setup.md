# Toolchain Setup (archived)

> Archived 2026-10-04. Kept for reference; the counter smoke test it described has been removed from the repo.

## Step 1: Install Simulation and Synthesis Tools

```bash
sudo apt update
sudo apt install verilator yosys iverilog gtkwave python3-pip python3-venv
```

- **Verilator & Icarus Verilog (`iverilog`):** Compiles and simulates your Verilog/SystemVerilog designs.
- **GTKWave:** A waveform viewer to visually debug hardware signals and clock cycles.
- **Yosys:** Framework for RTL synthesis.

## Step 2: Set Up Python Environment for Verification (`cocotb`)

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Step 3: VS Code Extensions

- Verilog-HDL/SystemVerilog by Masahiro Hiramori
- Verible by Chip Alliance

## Historical note

The original `counter.v` / `tb_counter.v` quick test (a 4-bit up-counter with a GTKWave dump) was used only to verify the toolchain and has been deleted. The real design lives under `src/`, and verification under `test/`.
