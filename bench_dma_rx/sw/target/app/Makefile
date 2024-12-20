TARGET_EXEC ?= bench_dma_rx.out

BUILD_DIR ?= ./build
DEBUG_DIR ?= $(BUILD_DIR)/debug
RELEASE_DIR ?= $(BUILD_DIR)/release
SRC_DIRS ?= ./src

MAKEFLAGS := --jobs=8
# MAKEFLAGS += --output-sync=target # avoid intermixed lines but no colors :x

SRCS := $(shell find $(SRC_DIRS) -name *.cpp -or -name *.c -or -name *.s)
DEBUG_OBJS := $(SRCS:%=$(DEBUG_DIR)/%.o)
RELEASE_OBJS := $(SRCS:%=$(RELEASE_DIR)/%.o)
DEPS := $(DEBUG_OBJS:.o=.d) $(RELEASE_OBJS:.o=.d)

# Makefile arguments
ARCH ?= all
CROSS_COMPILE ?= false

INC_DIRS := $(shell find $(SRC_DIRS) -type d)
# INC_FLAGS := $(addprefix -I,$(INC_DIRS)) # (slower but allow to include everything as if in same)
LDFLAGS := -pthread -lzmq
CPPFLAGS ?= -MMD -MP -O3 -pthread -lzmq $(ARCH_FLAGS)

# Debug
DEBUG_CPPFLAGS ?= $(CPPFLAGS) -DDEBUG
# DEBUG_CPPFLAGS += -DBG_PROBE_TWSYN_EXPORT # example debug probe

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

$(RELEASE_DIR)/$(TARGET_EXEC): $(RELEASE_OBJS)
	$(CXX) $(RELEASE_OBJS) -o $@ $(LDFLAGS)

$(DEBUG_DIR)/$(TARGET_EXEC): $(DEBUG_OBJS)
	$(CXX) $(DEBUG_OBJS) -o $@ $(LDFLAGS)

# Assembly
$(DEBUG_DIR)/%.s.o: %.s
	$(MKDIR_P) $(dir $@)
	$(AS) $(ASFLAGS) -c $< -o $@

$(RELEASE_DIR)/%.s.o: %.s
	$(MKDIR_P) $(dir $@)
	$(AS) $(ASFLAGS) -c $< -o $@

# C source
$(DEBUG_DIR)/%.c.o: %.c
	$(MKDIR_P) $(dir $@)
	$(CC) $(DEBUG_CPPFLAGS) $(CFLAGS) -c $< -o $@

$(RELEASE_DIR)/%.c.o: %.c
	$(MKDIR_P) $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# C++ source
$(DEBUG_DIR)/%.cpp.o: %.cpp
	$(MKDIR_P) $(dir $@)
	$(CXX) $(DEBUG_CPPFLAGS) $(CXXFLAGS) -c $< -o $@

$(RELEASE_DIR)/%.cpp.o: %.cpp
	$(MKDIR_P) $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# Debug target
debug: $(DEBUG_DIR)/$(TARGET_EXEC)

# Release target
release: $(RELEASE_DIR)/$(TARGET_EXEC)

.PHONY: clean debug release

clean:
	$(RM) -r $(BUILD_DIR)

-include $(DEPS)

MKDIR_P ?= mkdir -p