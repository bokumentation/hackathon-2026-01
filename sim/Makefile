SIM           ?= icarus
TOPLEVEL_LANG ?= verilog

REPO     := $(CURDIR)/..
BASELINE := $(REPO)/baseline/tt07-bep-decode/src
RTL      := $(REPO)/src

VERILOG_SOURCES += $(BASELINE)/serial_decode.v
VERILOG_SOURCES += $(RTL)/sync2.v
VERILOG_SOURCES += $(RTL)/l1_framing_validator.v
VERILOG_SOURCES += $(RTL)/l3_commit_gatekeeper.v
VERILOG_SOURCES += $(CURDIR)/tb_serial_baseline.v
VERILOG_SOURCES += $(CURDIR)/tb_boundary.v

COMPILE_ARGS += -I$(BASELINE)
COMPILE_ARGS += -I$(RTL)

TOPLEVEL ?= tb_serial_baseline
MODULE   ?= test_baseline_vuln

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: baseline boundary
baseline:
	$(MAKE) clean
	$(MAKE) TOPLEVEL=tb_serial_baseline MODULE=test_baseline_vuln
boundary:
	$(MAKE) clean
	$(MAKE) TOPLEVEL=tb_boundary MODULE=test_salaras_boundary

.PHONY: clean
clean::
	rm -rf sim_build results.xml out/*.vcd
