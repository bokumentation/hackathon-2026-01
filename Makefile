SHELL := /bin/bash

RTL_DIR    := src
TEST_DIR   := test
FORMAL_DIR := synth/formal
VENV       := venv
PYTHON     := $(VENV)/bin/python
PIP        := $(VENV)/bin/pip

TOP        := tt_um_bokumentation_salaras_rx
RTL_SRCS   := $(sort $(wildcard $(RTL_DIR)/*.v) $(wildcard $(RTL_DIR)/*.sv))
SBY_FILES  := $(wildcard $(FORMAL_DIR)/*.sby)

VERILATOR  := verilator
YOSYS      := yosys
SBY        := sby

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "SALARAS-RX build targets"
	@echo ""
	@echo "  make submodules   initialize and update baseline submodules"
	@echo "  make env          create the Python virtual environment"
	@echo "  make lint         lint RTL with Verilator"
	@echo "  make synth-check  check synthesizability with Yosys"
	@echo "  make formal       run SymbiYosys formal properties"
	@echo "  make test         run the cocotb testbench"
	@echo "  make gds          instructions for ASIC hardening"
	@echo "  make fpga         instructions for the DE10-Nano build"
	@echo "  make clean        remove build outputs"

.PHONY: submodules
submodules:
	git submodule update --init --recursive

.PHONY: env
env:
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

.PHONY: lint
lint:
	$(VERILATOR) --lint-only -Wall -Wno-fatal -Wno-DECLFILENAME \
		-I$(RTL_DIR) --top-module $(TOP) $(RTL_SRCS)

.PHONY: synth-check
synth-check:
	$(YOSYS) -q -p "read_verilog -sv -I$(RTL_DIR) $(RTL_SRCS); \
		hierarchy -top $(TOP); proc; opt; check; stat"

.PHONY: formal
formal:
	@if ! command -v $(SBY) >/dev/null 2>&1; then \
		echo "sby not found. Install SymbiYosys (pip install symbiyosys or use the OSS CAD Suite)."; \
		exit 1; \
	fi
	@for f in $(SBY_FILES); do \
		echo "Running formal: $$f"; \
		$(SBY) -f $$f || exit 1; \
	done

.PHONY: test
test:
	$(MAKE) -C $(TEST_DIR)

.PHONY: gds
gds:
	@echo "ASIC hardening runs through the Tiny Tapeout GDS GitHub Action."
	@echo "Trigger .github/workflows/gds.yaml via workflow_dispatch or a release tag."
	@echo "The configuration lives in src/config.tcl, src/user_config.tcl and info.yaml."

.PHONY: fpga
fpga:
	@echo "FPGA build is manual. See fpga/de10nano/README.md for the Quartus flow."

.PHONY: clean
clean:
	rm -rf sim_build obj_dir runs db
	rm -f *.vcd *.fst *.vvp
	$(MAKE) -C $(TEST_DIR) clean 2>/dev/null || true
