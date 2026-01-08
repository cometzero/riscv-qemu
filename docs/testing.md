# Testing Guide

## Running Tests

### Boot Test

```bash
python3 test/run_boot_test.py
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All milestones found, boot successful |
| 1 | Missing milestones or error detected |
| 2 | Timeout (3 minutes exceeded) |
| 3 | QEMU failed to start |

## Milestones

The test verifies these patterns in the boot log:

1. `U-Boot SPL` - SPL started
2. `SBI specification v` - OpenSBI/SBI running (detected via Linux kernel log)
3. `U-Boot 20` - U-Boot proper running
4. `Linux version` - Kernel booting
5. `Welcome to.*Buildroot` or `buildroot login:` - Userspace ready

## Error Detection

The test also detects:

- `Kernel panic` - Boot failure
- Repeated boot messages - Boot loop
- Timeout - System hang

## Test Logs

Logs are saved to `./build/test-logs/`:

- `boot-test-<timestamp>.log` - Full console output
- `boot-test-<timestamp>.result` - Pass/fail summary
