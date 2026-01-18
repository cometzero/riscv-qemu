---
name: remote-push
description: Push all local branches (submodules + top-level) to remote repositories
---

# Remote Push

Push all local branches to their remote repositories, including submodules and the top-level git repository.

## Your Task

Delegate the push operation to the `remote-branch-push-agent` sub-agent using the Task tool.

## Execution

Invoke the Task tool with the following parameters:

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

    $FORCE_FLAG

    Provide a summary table with push results for each repository.
```

## Arguments

This command accepts an optional argument:

- `$ARGUMENTS` - Optional: `--force` to enable force push

### Handling --force

If `$ARGUMENTS` contains `--force`:
- Set `$FORCE_FLAG` to: `Force push enabled: Use --force-with-lease for all push operations.`

If `$ARGUMENTS` is empty or doesn't contain `--force`:
- Set `$FORCE_FLAG` to: `Normal push mode: Do not use force push.`

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

A summary table showing:
- Repository path
- Branch name
- Remote name
- Push status (SUCCESS/FAILED)
- Error message if failed
