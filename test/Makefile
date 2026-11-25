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

Benches := tb_ram32x1d tb_dsp48e1 tb_ramb18e1 tb_eq tb_eq_io tb_eq_ff tb_iobuf tb_eq_ram tb_eq_simprim tb_eq_bufg tb_eq_ddr tb_eq_dsp tb_eq_dsp48 tb_eq_bram tb_eq_serdes

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
EQ_BUF_PRIMS := BUFCE_LEAF BUFGCE BUFGCE_DIV BUFGCTRL BUFG_GT BUFG_GT_SYNC \
	BUFG_PS BUFIO BUFMR BUFMRCE BUFR INV
VREF_BUF_SRCS := $(addprefix $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/,$(addsuffix .v,$(EQ_BUF_PRIMS)))
EQ_DDR_PRIMS := IDDR IDDR_2CLK IDDRE1 ODDR ODDRE1
VREF_DDR_SRCS := $(addprefix $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/,$(addsuffix .v,$(EQ_DDR_PRIMS)))
EQ_DSP_PRIMS := DSP_A_B_DATA DSP_ALU DSP_C_DATA DSP_M_DATA DSP_MULTIPLIER \
	DSP_OUTPUT DSP_PREADD DSP_PREADD_DATA
VREF_DSP_SRCS := $(addprefix $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/,$(addsuffix .v,$(EQ_DSP_PRIMS)))

.PHONY: all clean $(Benches)

all: $(Benches)

$(filter-out tb_eq tb_eq_io tb_eq_ff tb_eq_ram tb_eq_simprim tb_eq_bufg tb_eq_ddr tb_eq_dsp tb_eq_dsp48 tb_eq_bram tb_eq_serdes,$(Benches)):
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/$@.vhd \
	  -e $@ unisim.GLBL -r

tb_eq:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(VREF_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq.vhd \
	  -e tb_eq unisim.GLBL -r

tb_eq_io:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(VREF_IO_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_io.vhd \
	  -e tb_eq_io unisim.GLBL -r

tb_eq_ff:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(VREF_FF_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_ff.vhd \
	  -e tb_eq_ff unisim.GLBL -r

tb_eq_ram:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(VREF_RAM_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_ram.vhd \
	  -e tb_eq_ram unisim.GLBL -r

tb_eq_simprim:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a -D XIL_TIMING $(VREF_SIM_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_simprim.vhd \
	  -e tb_eq_simprim unisim.GLBL -r

tb_eq_bufg:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(VREF_BUF_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a -D XIL_TIMING $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/BUFCE_ROW.v
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/BUFHCE.v
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_bufg.vhd \
	  -e tb_eq_bufg unisim.GLBL -r

tb_eq_ddr:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(VREF_DDR_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_ddr.vhd \
	  -e tb_eq_ddr unisim.GLBL -r

tb_eq_dsp:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a -D XIL_TIMING $(VREF_DSP_SRCS)
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_dsp.vhd \
	  -e tb_eq_dsp unisim.GLBL -r

# DSP48E1 and DSP48E2 are analysed with XIL_TIMING. Delay nets are
# zero-delay copies, so the behavioural paths stay driven.
tb_eq_dsp48:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a -D XIL_TIMING \
	    $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/DSP48E1.v \
	    $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/DSP48E2.v
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_dsp48.vhd \
	  -e tb_eq_dsp48 unisim.GLBL -r

# RAMB* elaborate with XIL_TIMING undefined. The specify paths are 100 ps
# and collision checking is off (SIM_COLLISION_CHECK NONE), so the bench
# does not define XIL_TIMING.
tb_eq_bram:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/RAMB18E1.v \
	    $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/RAMB18E2.v \
	    $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/RAMB36E1.v \
	    $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/RAMB36E2.v
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_bram.vhd \
	  -e tb_eq_bram unisim.GLBL -r

# ISERDES, ISERDES_NODELAY, ISERDESE1 and OSERDES elaborate with
# XIL_TIMING undefined. The ISERDES flop delays are 300 ps and the
# OSERDES paths are 100 ps. One ISERDESE1 memory Q2 sample is U in
# the Verilog and 0 in the VHDL; the bench reports that mismatch.
tb_eq_serdes:
	$(NVC) --std=2008 --work=work:$(WORK) -M $(NVC_M) \
	  -a $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/ISERDES.v \
	    $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/ISERDES_NODELAY.v \
	    $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/ISERDESE1.v \
	    $(ROOT)/XilinxUnisimLibrary/verilog/src/unisims/OSERDES.v
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/tb_eq_serdes.vhd \
	  -e tb_eq_serdes unisim.GLBL -r

clean:
	rm -rf work
