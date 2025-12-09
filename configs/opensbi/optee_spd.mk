# OpenSBI configuration for OP-TEE SPD support
# Based on RISE project dev-optee-mpxy-v5 branch

# Platform settings
PLATFORM = generic
CROSS_COMPILE = riscv64-linux-gnu-

# OP-TEE as payload
FW_PAYLOAD = y
# FW_PAYLOAD_PATH will be set at build time to point to OP-TEE tee.bin

# Enable domain support for TEE/REE isolation
PLATFORM_HAS_DOMAIN = y

# Enable MPXY extension
PLATFORM_HAS_MPXY = y

# Memory layout for QEMU virt
# OpenSBI: 0x8010_0000 - 0x8015_FFFF
# OP-TEE will be loaded at 0xF100_0000
