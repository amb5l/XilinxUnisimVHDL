# Build the unisim library and run the self-checking testbenches.
#
#   make              analyse Verilog + vcomponents into $(BUILD)/unisim
#   make vcomponents  regenerate generated/unisim_vcomponents.vhd
#   make test         elaborate and run test/tb
#   make check        check config/primitives.txt and its unit tests
#   make clean
#
# BUILD   directory that receives the analysed library (default: build)
# PREFIX  optional root. When set, the library is written under
#         $(PREFIX)/$(BUILD) instead of $(BUILD).
# NVC     simulator binary (default: nvc)
# NVC_M   design-unit heap limit passed to nvc -M (default: 1g)

BUILD ?= build
PREFIX ?=
NVC ?= nvc
NVC_M ?= 1g

include mk/nvc.mk
