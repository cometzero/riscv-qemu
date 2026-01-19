---
description: Create a git commit following project conventions (Conventional Commits, Signed-off-by)
allowed-tools: Bash,Read
---

# Project Commit Command

Create a git commit following the project's Git conventions defined in CLAUDE.md.

## Git Rules (from CLAUDE.md)

1. **Conventional Commits Format**: `<type>(<scope>): <subject>`
   - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
2. **Subject Line**: Maximum 50 characters
3. **Body**: Wrap at 72 characters
4. **Signed-off-by**: Required (use `git commit -s`)
5. **Atomic Commits**: Each commit = single logical change

## Instructions

1. Run `git status` and `git diff --staged` (or `git diff` if nothing staged) to understand changes
2. Analyze the changes and determine:
   - Appropriate **type** (feat, fix, build, docs, etc.)
   - Appropriate **scope** (component affected)
   - Concise **subject** (≤50 chars, imperative mood)
3. If changes span multiple logical units, warn the user and suggest splitting
4. Stage changes if needed: `git add <files>`
5. Create the commit using HEREDOC format with `-s` flag:

```bash
git commit -s -m "$(cat <<'EOF'
<type>(<scope>): <subject>

<body wrapped at 72 chars if needed>

Signed-off-by: <name> <email>
EOF
)"
```

## Type Reference

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code restructure, no behavior change |
| `perf` | Performance improvement |
| `test` | Adding/fixing tests |
| `build` | Build system, dependencies, submodules |
| `ci` | CI configuration |
| `chore` | Maintenance tasks |
| `revert` | Reverting previous commit |

## Examples

**Submodule update:**
```
build(submodules): update u-boot to latest
```

**New feature:**
```
feat(boot): add custom device tree for QEMU

Add qemu_rv64_craft.dts with memory and peripheral
configurations for the custom boot flow.
```

**Bug fix:**
```
fix(opensbi): correct hart mask in platform config

The previous hart mask incorrectly excluded hart 0,
causing boot failures on single-core configurations.
```

## Now Execute

Analyze the current changes and create an appropriate commit.
