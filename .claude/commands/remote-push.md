---
name: remote-push
description: Push all local branches (submodules + top-level) to remote repositories
allowed-tools: Bash,Task
---

# Remote Push

Push all local branches to their remote repositories, including submodules and the top-level git repository.

## Execution Strategy

**Priority 1**: Use the shell script if available (faster):
```bash
./scripts/remote-push.sh [--force]
```

**Priority 2**: Fall back to sub-agent if script doesn't exist.

## Instructions

1. Check if `./scripts/remote-push.sh` exists
2. If YES → Run the script directly with Bash tool
3. If NO → Delegate to `remote-branch-push-agent` sub-agent

## Handling --force

If `$ARGUMENTS` contains `--force`:
- Script: `./scripts/remote-push.sh --force`
- Agent: Include "Force push enabled: Use --force-with-lease for all push operations."

If `$ARGUMENTS` is empty:
- Script: `./scripts/remote-push.sh`
- Agent: Include "Normal push mode: Do not use force push."

## Script Execution

```bash
# Normal push
./scripts/remote-push.sh

# Force push
./scripts/remote-push.sh --force
```

## Agent Fallback (if script not found)

```
Task tool:
  subagent_type: remote-branch-push-agent
  prompt: |
    Push all local branches to remote repositories.
    Working directory: /build/risc-v/riscv-qemu
    Tasks:
    1. Identify all submodules in this repository
    2. Push each submodule's current branch to origin
    3. Push the top-level repository's current branch to origin
    4. Report results for each repository
    [FORCE_FLAG based on --force argument]
    Provide a summary table with push results for each repository.
```

## Examples

### Normal push
```
/remote-push
```

### Force push
```
/remote-push --force
```

## Expected Output

A summary showing:
- Repository path
- Branch name
- Push status (SUCCESS/FAILED/SKIPPED)
