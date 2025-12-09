# OP-TEE OS Build Configuration for RISC-V QEMU virt platform
# Based on RISE project dev-optee-mpxy-v5 branch

# Platform settings
PLATFORM = virt
ARCH = riscv
CROSS_COMPILE = riscv64-linux-gnu-

# Debug settings
CFG_TEE_CORE_LOG_LEVEL = 3
CFG_TEE_CORE_DEBUG = y

# Memory configuration (from RISE project)
# OP-TEE Core: 0xF100_0000 - 0xF1FF_FFFF (16 MiB)
# Shared memory: 0xF200_0000 - 0xF21F_FFFF (2 MiB)
CFG_TZDRAM_START = 0xF1000000
CFG_TZDRAM_SIZE = 0x01000000
CFG_SHMEM_START = 0xF2000000
CFG_SHMEM_SIZE = 0x00200000

# RISC-V specific settings
CFG_RISCV_PLIC = n

# Enable MPXY extension for domain communication
CFG_RISCV_MPXY = y

# Crypto settings
CFG_CRYPTO_WITH_CE = n

# TA settings
CFG_TA_FLOAT_REGS = y
