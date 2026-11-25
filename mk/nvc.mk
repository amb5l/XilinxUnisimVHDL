# Analyse glbl.v and the vlog rows of config/primitives.txt into library
# unisim, then the generated vcomponents package, then unisim_sim and
# any vhdl rows (src/vhdl/<NAME>.vhd instead of that primitive's Verilog).
#
# XIL_TIMING and XIL_DR are left undefined. Do not pass -D for either
# macro: the models' `ifdef branches and the generated component ports
# both assume those macros are unset. skip rows are not analysed. The
# component generator still emits them when the Verilog header parses.

NVC_MK_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ROOT := $(abspath $(NVC_MK_DIR)/..)

ifeq ($(PREFIX),)
LIBDIR := $(BUILD)
else
LIBDIR := $(PREFIX)/$(BUILD)
endif

NVC ?= nvc
NVC_M ?= 1g

FILELIST := $(LIBDIR)/unisim.f
LIBSTAMP := $(LIBDIR)/unisim.stamp
GEN_PKG := $(ROOT)/generated/unisim_vcomponents.vhd
PRIMITIVES := $(ROOT)/config/primitives.txt
# scripts/primitives.py is the reader. These lists are the same rows.
VERILOG_SRCS := $(addprefix $(ROOT)/,$(shell python3 $(ROOT)/scripts/primitives.py --filelist))
VHDL_SRCS := $(addprefix $(ROOT)/,$(shell python3 $(ROOT)/scripts/primitives.py --vhdl))
# Package of roc/toc and gate helpers. Not a primitive, so it is not an index row.
VHDL_SUPPORT := $(ROOT)/src/vhdl/unisim_sim.vhd

.PHONY: all vcomponents test check clean

all: $(LIBSTAMP)

vcomponents: $(GEN_PKG)

check:
	python3 $(ROOT)/scripts/primitives.py --check
	python3 $(ROOT)/scripts/test_primitives.py

$(GEN_PKG): $(ROOT)/scripts/gen_vcomponents.py $(ROOT)/scripts/unisim_sources.py \
		$(ROOT)/scripts/primitives.py \
		$(ROOT)/config/type_map.yaml $(PRIMITIVES) $(VERILOG_SRCS)
	python3 $(ROOT)/scripts/gen_vcomponents.py -o $@

$(FILELIST): $(ROOT)/scripts/filelist.py $(ROOT)/scripts/unisim_sources.py \
		$(ROOT)/scripts/primitives.py $(PRIMITIVES) $(VERILOG_SRCS)
	@mkdir -p $(LIBDIR)
	python3 $(ROOT)/scripts/filelist.py > $@

$(LIBSTAMP): $(FILELIST) $(GEN_PKG) $(VHDL_SUPPORT) $(VHDL_SRCS)
	@mkdir -p $(LIBDIR)
	@n=$$(wc -l < $(FILELIST)); \
	  echo "Analysing $$n Verilog files into library unisim ($(LIBDIR)/unisim)"
	$(NVC) --std=2008 --work=unisim:$(abspath $(LIBDIR))/unisim -M $(NVC_M) \
	  -a -f $(FILELIST)
	$(NVC) --std=2008 --work=unisim:$(abspath $(LIBDIR))/unisim \
	  -a $(GEN_PKG) $(VHDL_SUPPORT) $(VHDL_SRCS)
	@touch $@

test: $(LIBSTAMP)
	$(MAKE) -C $(ROOT)/test NVC=$(NVC) NVC_M=$(NVC_M) BUILD=$(abspath $(LIBDIR))

clean:
	rm -rf $(LIBDIR)
	$(MAKE) -C $(ROOT)/test clean
