TARGET        := MyAromaPlugin
BUILD         := build
SOURCES       := source
INCLUDES      := include

# Wii U Toolchain (wut)
DEVKITPRO     ?= $(HOME)/devkitPro
WUT_ROOT      ?= $(DEVKITPRO)/wut

PREFIX        ?= powerpc-eabi-
CC            := $(PREFIX)gcc
CXX           := $(PREFIX)g++
AR            := $(PREFIX)ar
OBJCOPY       := $(PREFIX)objcopy

include $(WUT_ROOT)/share/wut_rules

CPPFLAGS      += -D__WIIU__ -D__AROMA__
CFLAGS        += -O2 -ffunction-sections -fdata-sections
CXXFLAGS      += -O2 -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti
# Note: wut's rules may invoke the linker directly in some environments (CI),
# so prefer linker-native flags here (not compiler-driver -Wl, flags).
LDFLAGS       += --gc-sections

# Link against WUPS and ProcUI
LDLIBS        += -lwups -lproc_ui

all: $(BUILD)/$(TARGET).rpx

# Optional: build a .wps Aroma plugin if wups-aroma-pack and plugin.yml are present
wps: $(BUILD)/$(TARGET).rpx
ifneq ("$(wildcard plugin.yml)","")
	wups-aroma-pack plugin.yml $(BUILD)/$(TARGET).rpx $(BUILD)/$(TARGET).wps
else
	@echo "plugin.yml not found; skipping .wps packaging."
endif

clean:
	@echo "Cleaning..."
	rm -rf $(BUILD)

.PHONY: all clean wps

