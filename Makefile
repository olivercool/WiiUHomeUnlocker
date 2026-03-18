.SUFFIXES:

ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=/opt/devkitpro")
endif

TOPDIR ?= $(CURDIR)

include $(DEVKITPRO)/wut/share/wut_rules

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# DATA is a list of directories containing data files
# INCLUDES is a list of directories containing header files
#---------------------------------------------------------------------------------
TARGET   := MyAromaPlugin
BUILD    := build
SOURCES  := source
DATA     :=
INCLUDES := include

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
CFLAGS   := -g -Wall -O2 -ffunction-sections -fdata-sections $(MACHDEP)
CFLAGS   += $(INCLUDE) -D__WIIU__ -D__WUT__ -D__AROMA__

CXXFLAGS := $(CFLAGS) -fno-exceptions -fno-rtti

ASFLAGS  := -g $(ARCH)

# Use RPX specs; produce a map file for debugging
LDFLAGS  := -g $(ARCH) $(RPXSPECS) -Wl,-Map,$(notdir $*.map) -Wl,--gc-sections

#---------------------------------------------------------------------------------
# Libraries
#---------------------------------------------------------------------------------
# WUPS is expected to be provided by your dev environment. If it's not installed,
# CI will fail at compile-time (missing headers) or link-time (missing -lwups).
LIBS    := -lwups -lproc_ui

LIBDIRS := $(PORTLIBS) $(WUT_ROOT)

#---------------------------------------------------------------------------------
# no real need to edit anything past this point
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT := $(CURDIR)/$(TARGET)
export TOPDIR := $(CURDIR)

export VPATH := $(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
 $(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR := $(CURDIR)/$(BUILD)

CFILES   := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES   := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
BINFILES := $(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

ifeq ($(strip $(CPPFILES)),)
 export LD := $(CC)
else
 export LD := $(CXX)
endif

export OFILES_BIN := $(addsuffix .o,$(BINFILES))
export OFILES_SRC := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export OFILES     := $(OFILES_BIN) $(OFILES_SRC)
export HFILES_BIN := $(addsuffix .h,$(subst .,_,$(BINFILES)))

export INCLUDE := $(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
 $(foreach dir,$(LIBDIRS),-I$(dir)/include) \
 -I$(CURDIR)/$(BUILD)

export LIBPATHS := $(foreach dir,$(LIBDIRS),-L$(dir)/lib)

.PHONY: $(BUILD) clean all wps

all: $(BUILD)

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).rpx $(TARGET).elf $(TARGET).wps

# Optional: build a .wps Aroma plugin if wups-aroma-pack and plugin.yml are present
wps: all
ifneq ("$(wildcard plugin.yml)","")
	@if command -v wups-aroma-pack >/dev/null 2>&1; then \
		wups-aroma-pack plugin.yml $(OUTPUT).rpx $(CURDIR)/$(BUILD)/$(TARGET).wps; \
	else \
		echo "wups-aroma-pack not found; skipping .wps packaging."; \
	fi
else
	@echo "plugin.yml not found; skipping .wps packaging."
endif

else

.PHONY: all

DEPENDS := $(OFILES:.o=.d)

all : $(OUTPUT).rpx

$(OUTPUT).rpx : $(OUTPUT).elf
$(OUTPUT).elf : $(OFILES)

$(OFILES_SRC) : $(HFILES_BIN)

-include $(DEPENDS)

endif

