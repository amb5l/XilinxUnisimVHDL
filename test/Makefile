# Elaborate each self-checking testbench next to unisim.GLBL.
#
# GSR is high for the first 100 ns inside glbl; the benches wait past that
# before driving stimulus. Invocation shape:
#
#   nvc -e tb_x unisim.GLBL -r

ROOT := $(abspath ..)
NVC ?= nvc
NVC_M ?= 1g
BUILD ?= $(ROOT)/build
WORK := $(abspath work)

Benches := tb_ram32x1d tb_dsp48e1 tb_ramb18e1 tb_eq

# Verilog reference for the primitives that now have a VHDL model.
# Analysed into work, not unisim: unisim already has the VHDL entity.
# A component of the same name in this bench binds to that Verilog module.
EQ_PRIMS := AND2B1L BUF BUFG CARRY4 FDCE FDPE FDRE FDSE GND IBUF INV \
	LUT1 LUT2 LUT3 LUT4 LUT5 LUT6 MUXF7 MUXF8 OBUF OBUFT OR2L VCC XORCY
VREF_SRCS := $(addprefix $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/,$(addsuffix .v,$(EQ_PRIMS)))

.PHONY: all clean $(Benches)

all: $(Benches)

$(filter-out tb_eq,$(Benches)):
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/$@.vhd \
	  -e $@ unisim.GLBL -r

tb_eq:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(ROOT)/XilinxUnisimLibrary/verilog/src/glbl.v $(VREF_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq.vhd \
	  -e tb_eq GLBL -r

clean:
	rm -rf work
