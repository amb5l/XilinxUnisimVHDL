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

Benches := tb_ram32x1d tb_dsp48e1 tb_ramb18e1 tb_eq tb_eq_io tb_eq_ff

# Verilog reference for the primitives that now have a VHDL model.
# Analysed into work, not unisim: unisim already has the VHDL entity.
# A component of the same name in this bench binds to that Verilog module.
EQ_PRIMS := AND2B1L BUF BUFG CARRY4 FDCE FDPE FDRE FDSE GND IBUF INV \
	LUT1 LUT2 LUT3 LUT4 LUT5 LUT6 MUXF7 MUXF8 OBUF OBUFT OR2L VCC XORCY
EQ_IO_PRIMS := AUTOBUF BUFGP BUFH IBUF_ANALOG IBUF_IBUFDISABLE \
	IBUF_INTERMDISABLE IBUFDS IBUFDS_DIFF_OUT IBUFDS_DIFF_OUT_IBUFDISABLE \
	IBUFDS_DIFF_OUT_INTERMDISABLE IBUFDS_IBUFDISABLE IBUFDS_IBUFDISABLE_INT \
	IBUFDS_INTERMDISABLE IBUFDS_INTERMDISABLE_INT LUT6_2 OBUFDS OBUFDS_GTE3 \
	OBUFDS_GTE4 OBUFTDS OBUFTDS_DCIEN OBUFT_DCIEN
EQ_FF_PRIMS := CFGLUT5 LDCE LDPE
VREF_SRCS := $(addprefix $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/,$(addsuffix .v,$(EQ_PRIMS)))
VREF_IO_SRCS := $(addprefix $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/,$(addsuffix .v,$(EQ_IO_PRIMS)))
VREF_FF_SRCS := $(addprefix $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/,$(addsuffix .v,$(EQ_FF_PRIMS)))

.PHONY: all clean $(Benches)

all: $(Benches)

$(filter-out tb_eq tb_eq_io tb_eq_ff,$(Benches)):
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/$@.vhd \
	  -e $@ unisim.GLBL -r

tb_eq:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(ROOT)/XilinxUnisimLibrary/verilog/src/glbl.v $(VREF_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq.vhd \
	  -e tb_eq GLBL -r

tb_eq_io:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(ROOT)/XilinxUnisimLibrary/verilog/src/glbl.v $(VREF_IO_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_io.vhd \
	  -e tb_eq_io GLBL -r

tb_eq_ff:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(ROOT)/XilinxUnisimLibrary/verilog/src/glbl.v $(VREF_FF_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_ff.vhd \
	  -e tb_eq_ff GLBL -r

clean:
	rm -rf work
