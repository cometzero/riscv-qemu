---
description: Upgrade all open source submodules to upstream, compile, and validate QEMU boot
allowed-tools: ["Task", "Bash", "Read", "Grep", "Glob", "TodoWrite"]
---

# OSS Upgrade - Full Stack Upstream Sync

Upgrade all open source sub-projects (OpenSBI, U-Boot, Linux, Buildroot) from their upstream remotes, compile each component in dependency order, and validate the complete boot flow in QEMU.

## Your Task

You MUST delegate this workflow to the `oss-upgrade-orchestrator` agent using the Task tool.

**CRITICAL**: Do NOT attempt to perform the upgrade steps yourself. The orchestrator agent is specifically designed to coordinate the complex multi-phase workflow with specialized sub-agents.

## Execution

Invoke the Task tool with the following parameters:

```
Task tool:
  subagent_type: oss-upgrade-orchestrator
  prompt: |
    Execute full OSS upgrade workflow:

    1. REBASE PHASE: Rebase all submodules onto their upstream remotes
       - OpenSBI, U-Boot, Linux, Buildroot
       - Use git-upstream-rebase sub-agent for each

    2. COMPILE PHASE: Build in dependency order
       - OpenSBI first (produces fw_dynamic.bin)
       - U-Boot second (needs OpenSBI artifacts)
       - Linux kernel (use linux-kernel-config-expert for config migration)
       - Buildroot if needed

    3. VALIDATE PHASE: Run QEMU boot test
       - Use riscv-qemu-boot-validator sub-agent
       - Verify all boot milestones (SPL → OpenSBI → U-Boot → Linux)

    Report final status with:
    - Rebase results (previous/new HEAD for each component)
    - Build results (success/failure per component)
    - Boot validation result
```

## Arguments

This command accepts optional arguments:

- `$ARGUMENTS` - Optional: Specific components to upgrade (e.g., "linux only", "u-boot and opensbi")

If arguments are provided, pass them to the orchestrator:

```
prompt: |
  Execute OSS upgrade workflow with scope: $ARGUMENTS
  ...
```

## Expected Outcomes

### Success
- All submodules rebased to latest upstream
- All components compile successfully
- QEMU boot test passes all milestones
- Ready for commit and push

### Failure
- Detailed failure report with:
  - Which phase/component failed
  - Root cause analysis
  - Resolution attempts made
  - Recommended manual actions
- System rolled back to safe state

## Safety

The orchestrator enforces these safety rules:
- Never force-push submodules
- Never skip boot validation
- Maximum 3 retry attempts per failure
- Automatic rollback on unrecoverable failure
