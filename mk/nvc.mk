# Analyse glbl.v and verilog/src/unisims into library unisim, then the
# generated vcomponents package and any hand-written sources in src/vhdl.
#
# XIL_TIMING and XIL_DR are left undefined. Do not pass -D for either
# macro: the models' `ifdef branches and the generated component ports
# both assume those macros are unset. config/exclude.txt drops sources
# the file list must not contain.

NVC_MK_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ROOT := $(abspath $(NVC_MK_DIR)/..)

ifeq ($(PREFIX),)
LIBDIR := $(BUILD)
else
LIBDIR := $(PREFIX)/$(BUILD)
endif

NVC ?= nvc
NVC_M ?= 1g
PYTHON ?= python3

FILELIST := $(LIBDIR)/unisim.f
LIBSTAMP := $(LIBDIR)/unisim.stamp
GEN_PKG := $(ROOT)/generated/unisim_vcomponents.vhd
VHDL_SRCS := $(wildcard $(ROOT)/src/vhdl/*.vhd)
VERILOG_SRCS := $(wildcard $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/*.v) \
	$(ROOT)/XilinxUnisimLibrary/verilog/src/glbl.v

.PHONY: all vcomponents test compare clean

all: $(LIBSTAMP)

vcomponents: $(GEN_PKG)

$(GEN_PKG): $(ROOT)/scripts/gen_vcomponents.py $(ROOT)/scripts/unisim_sources.py \
		$(ROOT)/config/type_map.yaml $(ROOT)/config/exclude.txt $(VERILOG_SRCS)
	python3 $(ROOT)/scripts/gen_vcomponents.py -o $@

$(FILELIST): $(ROOT)/scripts/filelist.py $(ROOT)/scripts/unisim_sources.py \
		$(ROOT)/config/exclude.txt $(VERILOG_SRCS)
	@mkdir -p $(LIBDIR)
	python3 $(ROOT)/scripts/filelist.py > $@

$(LIBSTAMP): $(FILELIST) $(GEN_PKG) $(VHDL_SRCS)
	@mkdir -p $(LIBDIR)
	@n=$$(wc -l < $(FILELIST)); \
	  echo "Analysing $$n Verilog files into library unisim ($(LIBDIR)/unisim)"
	$(NVC) --std=2008 --work=unisim:$(abspath $(LIBDIR))/unisim -M $(NVC_M) \
	  -a -f $(FILELIST)
	$(NVC) --std=2008 --work=unisim:$(abspath $(LIBDIR))/unisim \
	  -a $(GEN_PKG) $(VHDL_SRCS)
	@touch $@

test: $(LIBSTAMP)
	$(MAKE) -C $(ROOT)/test NVC=$(NVC) NVC_M=$(NVC_M) BUILD=$(abspath $(LIBDIR))

# Reads XILINX_VIVADO, or VIVADO_VCOMP, unless VIVADO= is passed.
# Does not build the library and does not copy Vivado sources.
compare:
	@mkdir -p $(LIBDIR)
	$(PYTHON) $(ROOT)/scripts/compare_vcomponents.py \
	  --report $(abspath $(LIBDIR))/compare_report.txt \
	  --json $(abspath $(LIBDIR))/compare_report.json \
	  $(if $(VIVADO),--vivado "$(VIVADO)",) \
	  $(if $(VCOMP),--vcomp-name "$(VCOMP)",) \
	  $(if $(STRICT),--strict,)

clean:
	rm -rf $(LIBDIR)
	$(MAKE) -C $(ROOT)/test clean
