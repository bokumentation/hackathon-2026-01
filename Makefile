SHELL := /bin/bash

RTL_DIR    := src
TEST_DIR   := test
FORMAL_DIR := synth/formal
AREA_DIR   := synth/area
VENV       := venv
PYTHON     := $(VENV)/bin/python
PIP        := $(VENV)/bin/pip

TOP        := tt_um_auth_boundary
RTL_SRCS   := $(sort $(wildcard $(RTL_DIR)/*.v) $(wildcard $(RTL_DIR)/*.sv))
SBY_FILES  := $(wildcard $(FORMAL_DIR)/*.sby)

VERILATOR  := verilator
YOSYS      := yosys
SBY        := sby

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "TRI-ARGA build targets"
	@echo ""
	@echo "  make submodules   initialize and update baseline submodules"
	@echo "  make env          create the Python virtual environment"
	@echo "  make doctor       check for the required host tools"
	@echo "  make lint         lint RTL with Verilator"
	@echo "  make synth-check  check synthesizability with Yosys"
	@echo "  make area         estimate cell, FF, and Cyclone V resource usage"
	@echo "  make formal       run SymbiYosys formal properties"
	@echo "  make test         run the cocotb testbench"
	@echo "  make simon        run the SIMON-32/64 block and CBC-MAC tests"
	@echo "  make l2           run the L2 authentication and freshness tests"
	@echo "  make auth         run the integrated authentication and commit tests"
	@echo "  make crc          measure the RF CRC streaming latency (comparison)"
	@echo "  make wrapper      run the TT wrapper testbench (key separation and frame tests)"
	@echo "  make sim          run the simulation evidence suites"
	@echo "  make figures      render the proposal/appendix figures from real VCDs"
	@echo "  make docs         build the proposal into output/ (incremental)"
	@echo "  make docs-force   rebuild the proposal even if unchanged"
	@echo "  make docs-all     build the proposal, deck, and progress report into output/"
	@echo "  make progress     build the progress report into output/ (incremental)"
	@echo "  make progress-force  rebuild the progress report even if unchanged"
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

.PHONY: doctor
doctor:
	@echo "Checking repository tools"
	@for t in git make python3 verilator yosys iverilog; do \
		if command -v $$t >/dev/null 2>&1; then echo "  ok      $$t"; else echo "  MISSING $$t"; fi; \
	done
	@for t in sby node npm chromium chromium-browser google-chrome inkscape soffice; do \
		if command -v $$t >/dev/null 2>&1; then echo "  ok      $$t"; else echo "  missing $$t (optional)"; fi; \
	done
	@if [ -d $(VENV) ]; then echo "  ok      venv"; else echo "  MISSING venv (run make env)"; fi
	@if [ -d baseline/tt07-bep-decode/src ]; then echo "  ok      baseline submodules"; else echo "  MISSING baseline submodules (run make submodules)"; fi

.PHONY: lint
lint:
	$(VERILATOR) --lint-only -Wall -Wno-fatal -Wno-DECLFILENAME \
		-I$(RTL_DIR) --top-module $(TOP) $(RTL_SRCS)

.PHONY: synth-check
synth-check:
	$(YOSYS) -q -p "read_verilog -sv -I$(RTL_DIR) $(RTL_SRCS); \
		hierarchy -top $(TOP); proc; opt; check; stat"

.PHONY: area
area:
	@mkdir -p $(AREA_DIR)
	@echo "Generic synthesis (technology independent)"
	$(YOSYS) -Q -p "read_verilog -sv -I$(RTL_DIR) $(RTL_SRCS); \
		hierarchy -top $(TOP); synth; flatten; opt_clean; stat" | tee $(AREA_DIR)/generic.log
	@echo "Cyclone V ALM mapping (Intel/Altera proxy)"
	$(YOSYS) -Q -p "read_verilog -sv -I$(RTL_DIR) $(RTL_SRCS); \
		hierarchy -top $(TOP); synth_intel_alm -family cyclonev; flatten; opt_clean; stat" | tee $(AREA_DIR)/cyclonev.log
	@echo "Area reports written to $(AREA_DIR)/"

.PHONY: formal
formal:
	@if ! command -v $(SBY) >/dev/null 2>&1; then \
		echo "sby not found. Install SymbiYosys (pip install symbiyosys or use the OSS CAD Suite)."; \
		exit 1; \
	fi
	@fail=0; for f in $(SBY_FILES); do \
		echo "Running formal: $$f"; \
		$(SBY) -f $$f || fail=1; \
	done; \
	if [ $$fail -ne 0 ]; then echo "formal: one or more jobs FAILED"; exit 1; fi; \
	echo "formal: all jobs passed"

COCOTB_TARGETS := test simon l2 auth crc wrapper sim link-codec link-framing
$(COCOTB_TARGETS): export PATH := $(CURDIR)/$(VENV)/bin:$(PATH)

.PHONY: test
test:
	$(MAKE) -C $(TEST_DIR)

.PHONY: simon
simon:
	$(MAKE) -C $(TEST_DIR) -f Makefile.simon

.PHONY: l2
l2:
	$(MAKE) -C $(TEST_DIR) -f Makefile.l2

.PHONY: auth
auth:
	$(MAKE) -C $(TEST_DIR) -f Makefile.auth

.PHONY: crc
crc:
	$(MAKE) -C $(TEST_DIR) -f Makefile.crc

.PHONY: link-codec
link-codec:
	$(MAKE) -C $(TEST_DIR) -f Makefile.link_codec

.PHONY: link-framing
link-framing:
	$(MAKE) -C $(TEST_DIR) -f Makefile.link_framing

.PHONY: wrapper
wrapper:
	$(MAKE) -C $(TEST_DIR) -f Makefile.project

.PHONY: sim
sim:
	$(MAKE) -C sim baseline
	$(MAKE) -C sim boundary

.PHONY: figures
figures:
	bash sim/figures.sh

.PHONY: docs
docs:
	bash docs/proposal/build.sh

.PHONY: docs-force
docs-force:
	bash docs/proposal/build.sh --force

.PHONY: docs-all
docs-all:
	bash docs/build.sh all

.PHONY: progress
progress:
	bash docs/progress/build.sh

.PHONY: progress-force
progress-force:
	bash docs/progress/build.sh --force

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
	rm -rf sim_build obj_dir runs db output
	rm -rf fpga/de10nano/db fpga/de10nano/incremental_db fpga/de10nano/output_files
	rm -f *.vcd *.fst *.vvp fpga/de10nano/c5_pin_model_dump.txt
	$(MAKE) -C $(TEST_DIR) clean 2>/dev/null || true
	$(MAKE) -C sim clean 2>/dev/null || true
