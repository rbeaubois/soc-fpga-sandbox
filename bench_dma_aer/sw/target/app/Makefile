TARGET_EXEC ?= bench_dma_aer.out

BUILD_DIR ?= ./build
SRC_DIRS ?= ./src

MAKEFLAGS := --jobs=8
# MAKEFLAGS += --output-sync=target # avoid intermixed lines but no colors :x

SRCS := $(shell find $(SRC_DIRS) -name *.cpp -or -name *.c -or -name *.s)
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)
DEPS := $(OBJS:.o=.d)

# Makefile arguments
ARCH ?= all
CROSS_COMPILE ?= false

INC_DIRS := $(shell find $(SRC_DIRS) -type d)
# INC_FLAGS := $(addprefix -I,$(INC_DIRS))
LDFLAGS := -pthread -lzmq

ifeq ($(ARCH), zynqmp)
	ARCH_FLAGS := -DHW_FPGA_ARCH_ZYNQMP
	ifeq ($(CROSS_COMPILE), true)
		CXX = aarch64-linux-gnu-g++
		CC = aarch64-linux-gnu-gcc
	endif
else ifeq ($(ARCH), versal)
	ARCH_FLAGS := -DHW_FPGA_ARCH_VERSAL
	ifeq ($(CROSS_COMPILE), true)
		CXX = aarch64-linux-gnu-g++
		CC = aarch64-linux-gnu-gcc
	endif
else
	ARCH_FLAGS := ""
	@echo "Invalid architecture specified. Use 'zynqmp' or 'versal'."
	exit 1
endif

CPPFLAGS ?= $(INC_FLAGS) -MMD -MP -O3 -pthread -lzmq $(ARCH_FLAGS)

# Debug
DEBUG_TARGET_EXEC := debug_$(TARGET_EXEC)
DEBUG_CPPFLAGS ?= $(CPPFLAGS) -DDEBUG
# DEBUG_CPPFLAGS += -DBG_PROBE_TWSYN_EXPORT # to export URAM file for HDL sim

$(BUILD_DIR)/$(TARGET_EXEC): $(OBJS)
	$(CXX) $(OBJS) -o $@ $(LDFLAGS)

# assembly
$(BUILD_DIR)/%.s.o: %.s
	$(MKDIR_P) $(dir $@)
	$(AS) $(ASFLAGS) -c $< -o $@

# c source
$(BUILD_DIR)/%.c.o: %.c
	$(MKDIR_P) $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# c++ source
$(BUILD_DIR)/%.cpp.o: %.cpp
	$(MKDIR_P) $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# debug target
debug: CPPFLAGS := $(DEBUG_CPPFLAGS)
debug: $(BUILD_DIR)/$(DEBUG_TARGET_EXEC)

$(BUILD_DIR)/$(DEBUG_TARGET_EXEC): $(OBJS)
	$(CXX) $(OBJS) -o $@ $(LDFLAGS)

.PHONY: clean debug

clean:
	$(RM) -r $(BUILD_DIR)

-include $(DEPS)

MKDIR_P ?= mkdir -p
