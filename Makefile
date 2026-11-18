# ---------------------------------------------------------------------------
# Vivado non-project batch flow
#
# Usage:
#   make            # synth -> impl -> bitstream
#   make synth      # synthesis only
#   make impl       # place & route
#   make bit        # write bitstream
#   make program    # program the first connected FPGA
#   make gui        # open the latest checkpoint in the Vivado GUI
#   make clean      # remove build outputs
#
# Override anything on the command line, e.g.:
#   make TOP=my_top PART=xc7z020clg400-1 JOBS=8
# ---------------------------------------------------------------------------

# ---- Project settings (edit these) ----------------------------------------
PROJECT  ?= my_design
TOP      ?= top
PART     ?= xc7a35tcpg236-1
JOBS     ?= 4

SRC_DIR  ?= src
XDC_DIR  ?= constraints
BUILD_DIR?= build
SCRIPTS  ?= scripts

VIVADO   ?= vivado

# ---- Source discovery -----------------------------------------------------
RTL_SRCS := $(shell find $(SRC_DIR) -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vhd' -o -name '*.vhdl' \) 2>/dev/null)
XDC_SRCS := $(wildcard $(XDC_DIR)/*.xdc)

# ---- Outputs --------------------------------------------------------------
SYNTH_DCP := $(BUILD_DIR)/post_synth.dcp
ROUTE_DCP := $(BUILD_DIR)/post_route.dcp
BITFILE   := $(BUILD_DIR)/$(PROJECT).bit

# Pass settings to the Tcl scripts through the environment
export PROJECT TOP PART JOBS BUILD_DIR RTL_SRCS XDC_SRCS

# $(call run_vivado,<script>,<stage>)
run_vivado = $(VIVADO) -mode batch -nojournal -notrace \
             -log $(BUILD_DIR)/$(2).log \
             -source $(SCRIPTS)/$(1) -tclargs $(2)

# ---- Targets --------------------------------------------------------------
.PHONY: all synth impl bit program gui clean help
.DEFAULT_GOAL := all

all: bit

synth: $(SYNTH_DCP)
impl:  $(ROUTE_DCP)
bit:   $(BITFILE)

$(BUILD_DIR):
	mkdir -p $@

$(SYNTH_DCP): $(RTL_SRCS) $(XDC_SRCS) $(SCRIPTS)/build.tcl | $(BUILD_DIR)
	$(call run_vivado,build.tcl,synth)

$(ROUTE_DCP): $(SYNTH_DCP) $(SCRIPTS)/build.tcl
	$(call run_vivado,build.tcl,impl)

$(BITFILE): $(ROUTE_DCP) $(SCRIPTS)/build.tcl
	$(call run_vivado,build.tcl,bit)

program: $(BITFILE)
	BITFILE=$(BITFILE) $(VIVADO) -mode batch -nojournal -notrace \
	    -log $(BUILD_DIR)/program.log -source $(SCRIPTS)/program.tcl

gui:
	@if   [ -f $(ROUTE_DCP) ]; then $(VIVADO) $(ROUTE_DCP) & \
	 elif [ -f $(SYNTH_DCP) ]; then $(VIVADO) $(SYNTH_DCP) & \
	 else echo "No checkpoint found. Run 'make synth' first."; fi

clean:
	rm -rf $(BUILD_DIR) .Xil *.jou *.log *.str vivado*.backup.*

help:
	@sed -n '2,15p' $(lastword $(MAKEFILE_LIST)) | sed 's/^# \{0,1\}//'
