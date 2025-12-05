# Makefile for RISC-V WorldGuard Bare-metal Test
#
# Usage:
#   make          - Build test.elf
#   make run      - Run test in QEMU
#   make clean    - Clean build artifacts

# Cross-compiler
CROSS_COMPILE ?= riscv64-linux-gnu-

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

# Project root (for finding QEMU)
PROJECT_ROOT := $(shell cd ../.. && pwd)
QEMU := $(PROJECT_ROOT)/build/qemu/qemu-system-riscv64

# Compiler flags
CFLAGS = -march=rv64imac_zicsr -mabi=lp64 -mcmodel=medany
CFLAGS += -nostdlib -nostartfiles -ffreestanding
CFLAGS += -O2 -g -Wall -Wextra
CFLAGS += -I.

# Assembler flags
ASFLAGS = -march=rv64imac_zicsr -mabi=lp64

# Linker flags
LDFLAGS = -T linker.ld -nostdlib

# Source files
SRCS_C = main.c
SRCS_S = boot.S
OBJS = $(SRCS_C:.c=.o) $(SRCS_S:.S=.o)

# Output
TARGET = test.elf
TARGET_BIN = test.bin

.PHONY: all clean run disasm

all: $(TARGET) $(TARGET_BIN)

$(TARGET): $(OBJS) linker.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS)
	@echo "Built: $@"

$(TARGET_BIN): $(TARGET)
	$(OBJCOPY) -O binary $< $@
	@echo "Built: $@"

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET) $(TARGET_BIN) test.dump

# Disassembly for debugging
disasm: $(TARGET)
	$(OBJDUMP) -d $< > test.dump
	@echo "Disassembly: test.dump"

# Run test in QEMU with WorldGuard enabled
run: $(TARGET)
	@if [ ! -x "$(QEMU)" ]; then \
		echo "Error: QEMU not found at $(QEMU)"; \
		echo "Please build QEMU first with: $(PROJECT_ROOT)/scripts/build-qemu.sh"; \
		exit 1; \
	fi
	$(QEMU) \
		-M virt,wg=on,wg-nworlds=4,wg-trustedwid=3,wg-hwbypass=off \
		-m 2G \
		-smp 1 \
		-nographic \
		-bios $(TARGET)

# Run with hwbypass=on for comparison
run-bypass: $(TARGET)
	$(QEMU) \
		-M virt,wg=on,wg-nworlds=4,wg-trustedwid=3,wg-hwbypass=on \
		-m 256M \
		-smp 1 \
		-nographic \
		-bios $(TARGET)

# Run with trace output
run-trace: $(TARGET)
	$(QEMU) \
		-M virt,wg=on,wg-nworlds=4,wg-trustedwid=3,wg-hwbypass=off \
		-m 256M \
		-smp 1 \
		-nographic \
		-d trace:riscv_wgchecker* \
		-bios $(TARGET)

# Debug with GDB
debug: $(TARGET)
	$(QEMU) \
		-M virt,wg=on,wg-nworlds=4,wg-trustedwid=3,wg-hwbypass=off \
		-m 256M \
		-smp 1 \
		-nographic \
		-s -S \
		-bios $(TARGET)

help:
	@echo "WorldGuard Bare-metal Test"
	@echo ""
	@echo "Targets:"
	@echo "  all        - Build test.elf and test.bin"
	@echo "  run        - Run test with hwbypass=off"
	@echo "  run-bypass - Run test with hwbypass=on"
	@echo "  run-trace  - Run with wgChecker trace output"
	@echo "  debug      - Run with GDB server (port 1234)"
	@echo "  disasm     - Generate disassembly"
	@echo "  clean      - Clean build artifacts"
