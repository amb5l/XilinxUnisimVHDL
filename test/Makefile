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

Benches := tb_ram32x1d tb_dsp48e1 tb_ramb18e1 tb_eq tb_eq_io tb_eq_ff tb_iobuf tb_eq_ram tb_eq_simprim

# Verilog reference for the primitives that now have a VHDL model.
# Analysed into work, not unisim: unisim already has the VHDL entity.
# A component of the same name in this bench binds to that Verilog module.
EQ_PRIMS := AND2B1L BUF BUFG CARRY4 CARRY8 FDCE FDPE FDRE FDSE GND IBUF INV \
	LUT1 LUT2 LUT3 LUT4 LUT5 LUT6 MUXCY MUXF7 MUXF8 MUXF9 OBUF OBUFT OR2L VCC XORCY
EQ_IO_PRIMS := AUTOBUF BUFGP BUFH IBUF_ANALOG IBUF_IBUFDISABLE \
	IBUF_INTERMDISABLE IBUFDS IBUFDS_DIFF_OUT IBUFDS_DIFF_OUT_IBUFDISABLE \
	IBUFDS_DIFF_OUT_INTERMDISABLE IBUFDS_IBUFDISABLE IBUFDS_IBUFDISABLE_INT \
	IBUFDS_INTERMDISABLE IBUFDS_INTERMDISABLE_INT LUT6_2 OBUFDS OBUFDS_GTE3 \
	OBUFDS_GTE4 OBUFTDS OBUFTDS_DCIEN OBUFT_DCIEN
EQ_FF_PRIMS := CFGLUT5 LDCE LDPE
EQ_RAM_PRIMS := RAM128X1D RAM128X1S RAM256X1D RAM256X1S RAM32M RAM32M16 \
	RAM32X16DR8 RAM32X1D RAM32X1S RAM512X1S RAM64M RAM64M8 RAM64X1D RAM64X1S \
	RAM64X8SW SRL16E SRLC16E SRLC32E
VREF_SRCS := $(addprefix $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/,$(addsuffix .v,$(EQ_PRIMS)))
VREF_IO_SRCS := $(addprefix $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/,$(addsuffix .v,$(EQ_IO_PRIMS)))
VREF_FF_SRCS := $(addprefix $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/,$(addsuffix .v,$(EQ_FF_PRIMS)))
VREF_RAM_SRCS := $(addprefix $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/,$(addsuffix .v,$(EQ_RAM_PRIMS)))
EQ_SIM_PRIMS := DIFFINBUF DPHY_DIFFINBUF IBUFCTRL INBUF RAMD32 RAMD32M64 \
	RAMD64E RAMS32 RAMS64E RAMS64E1
VREF_SIM_SRCS := $(addprefix $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/,$(addsuffix .v,$(EQ_SIM_PRIMS)))

.PHONY: all clean $(Benches)

all: $(Benches)

$(filter-out tb_eq tb_eq_io tb_eq_ff tb_eq_ram tb_eq_simprim,$(Benches)):
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

tb_eq_ram:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(ROOT)/XilinxUnisimLibrary/verilog/src/glbl.v $(VREF_RAM_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_ram.vhd \
	  -e tb_eq_ram GLBL -r

tb_eq_simprim:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a -D XIL_TIMING $(ROOT)/XilinxUnisimLibrary/verilog/src/glbl.v $(VREF_SIM_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_simprim.vhd \
	  -e tb_eq_simprim GLBL -r

clean:
	rm -rf work
