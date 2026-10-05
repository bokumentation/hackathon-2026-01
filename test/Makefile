SIM           ?= icarus
TOPLEVEL_LANG ?= verilog
SRC_DIR        = $(CURDIR)/../src

RTL_SOURCES = sync2.v manchester_rx.v frame_capture.v l1_framing_validator.v \
              l2_integrity_verify.v l3_commit_gatekeeper.v salaras_rx_top.v project.v

VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(RTL_SOURCES))
COMPILE_ARGS    += -I$(SRC_DIR)
VERILOG_SOURCES += $(CURDIR)/tb.v

TOPLEVEL = tb
MODULE   = test_salaras_rx

include $(shell cocotb-config --makefiles)/Makefile.sim
