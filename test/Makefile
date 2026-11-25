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

Benches := tb_ram32x1d tb_dsp48e1 tb_ramb18e1

.PHONY: all clean $(Benches)

all: $(Benches)

$(Benches):
	$(NVC) --std=2008 --work=work:$(WORK) -L $(BUILD) -M $(NVC_M) \
	  -a $(CURDIR)/tb/$@.vhd \
	  -e $@ unisim.GLBL -r

clean:
	rm -rf work
