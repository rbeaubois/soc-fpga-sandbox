TARGET_EXEC ?= bench_dma_aer.out

BUILD_DIR ?= ./build
DEBUG_DIR ?= $(BUILD_DIR)/debug
RELEASE_DIR ?= $(BUILD_DIR)/release
SRC_DIRS ?= ./src

MAKEFLAGS := --jobs=8

SRCS := $(shell find $(SRC_DIRS) -name *.cpp -or -name *.c -or -name *.s)
DEBUG_OBJS := $(SRCS:%=$(DEBUG_DIR)/%.o)
RELEASE_OBJS := $(SRCS:%=$(RELEASE_DIR)/%.o)
DEPS := $(DEBUG_OBJS:.o=.d) $(RELEASE_OBJS:.o=.d)

# Makefile arguments
ARCH ?= all
CROSS_COMPILE ?= false

INC_DIRS := $(shell find $(SRC_DIRS) -type d)
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

CPPFLAGS ?= -MMD -MP -O3 -pthread -lzmq $(ARCH_FLAGS)

# Debug
DEBUG_TARGET_EXEC := $(TARGET_EXEC)
DEBUG_CPPFLAGS ?= $(CPPFLAGS) -DDEBUG

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
debug: CPPFLAGS := $(DEBUG_CPPFLAGS)
debug: $(DEBUG_DIR)/$(DEBUG_TARGET_EXEC)

$(DEBUG_DIR)/$(DEBUG_TARGET_EXEC): $(DEBUG_OBJS)
	$(CXX) $(DEBUG_OBJS) -o $@ $(LDFLAGS)

# Release target
release: $(RELEASE_DIR)/$(TARGET_EXEC)

.PHONY: clean debug release

clean:
	$(RM) -r $(BUILD_DIR)

-include $(DEPS)

MKDIR_P ?= mkdir -p