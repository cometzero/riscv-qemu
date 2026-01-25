---
name: aspice-swe2-driver
description: Generate/update an AUTOSAR ASPICE 4.0 SWE.2 doc (Markdown + Mermaid) for an arbitrary Linux device driver with explicit pre-brief + confirmation
allowed-tools: ["Task", "AskUserQuestion", "Read", "Grep", "Glob", "TodoWrite", "ApplyPatch", "Bash"]
---

# ASPICE SWE.2 Generator (Generic Linux Device Driver)

Generate or update an AUTOSAR ASPICE 4.0 SWE.2 (Software Architectural Design) document in Markdown with Mermaid diagrams.

This command is generic: it supports hwspinlock drivers and other Linux device drivers.

## Usage

Minimal (freeform):
- `/aspice-swe2-driver <component> <freeform request...>`

Examples:
- `/aspice-swe2-driver omap_hwspinlock Write SWE.2 for this driver. Linux + Zephyr AMP.`
- `/aspice-swe2-driver stmmac SWE.2 doc. Focus on init/runtime/shutdown and DMA rings.`

Examples:
- `/aspice-swe2-driver omap_hwspinlock --swe1 "REQ-LOCK: ...; REQ-UNLOCK: ..." --mermaid-compat vscode`
- `/aspice-swe2-driver omap_hwspinlock --out docs/aspice-swe2-omap_hwspinlock.md`

Supported arguments (parse from `$ARGUMENTS`):
- `<component>` (required): logical component name, usually matches driver name
- `<freeform request...>` (optional but recommended): anything after the component name is treated as the request prompt.
- `--request <text>` (optional): explicit request override (takes precedence over freeform)
- `--env <text>` (optional): explicit environment override (takes precedence over inferred env)
- `--swe1 <text>`: SWE.1 requirements list (semicolon-separated) to trace (optional; if omitted, ask)
- `--out <path>`: output file (default: `docs/aspice-swe2-<component>.md`)
- `--lang ko|en`: explanation language (default: `ko`; identifiers remain English)
- `--mermaid-compat vscode|standard`: default `vscode`

Inference rules:
- If `--request` is not provided, infer the request from the remaining freeform text.
- If `--env` is not provided, infer environment from the request text (e.g., AMP, RTOS, suspend/resume, safety constraints). If unclear, ask.

## Execution Contract (Non-Negotiable)

This command runs as a 2-phase workflow.

### Phase A: Brief and Confirm (NO file changes)

Before making any changes, you MUST:

1) Explore the codebase to locate the component and its interfaces:
- Find driver implementation files in `sources/linux`.
- Identify external components/frameworks it depends on.
- Identify typical consumers/users (other kernel code paths) where relevant.

2) Produce a brief to the user that includes:
- What you understood from arguments (component, request, env)
- Files you plan to create/modify (exact paths)
- SWE.2 sections you will include
- Mermaid diagram list (types + purpose)
- Evidence plan: which source files will be used as anchors
- Explicit assumptions

3) If anything is ambiguous or missing (e.g., dynamic scenarios, OS/RTOS context, SWE.1 items), ask targeted questions.

4) Ask for user confirmation BEFORE proceeding:

Use AskUserQuestion with choices:
- "Proceed" (recommended if no open questions)
- "Revise plan"
- "Cancel"

If user does not confirm, STOP.

### Phase B: Execute (after explicit confirmation)

After confirmation, you MUST execute the work in **ULTRAWORK mode**.

Implementation trigger:
- Start the execution prompt with the literal keyword `ultrawork`.
- Provide the consolidated prompt content (component, request, inferred env, SWE.1, output path, mermaid compatibility, and decisions from briefing).

Example execution prompt template:

```text
ultrawork

TASK: Create/update AUTOSAR ASPICE 4.0 SWE.2 (Software Architectural Design) in Markdown + Mermaid.

Component: <component>
Output: <out path>
Mermaid compatibility: <vscode|standard>

Request (freeform):
<request text>

Environment (explicit or inferred):
<env>

SWE.1 requirements to trace:
<REQ-1...; REQ-2...>

Non-negotiables:
- Documentation only (do not modify `sources/linux`)
- Evidence-based claims (kernel file path/symbol or public URL)
- VS Code mermaid mode: use only `graph` and `sequenceDiagram`; avoid `flowchart`, `classDiagram`, and `opt/alt/par`
- Ensure Mermaid fenced blocks are always closed
- Update output file in-place if it already exists
```

## Mermaid Compatibility Rules

If `--mermaid-compat vscode` (default):
- Use only `graph` and `sequenceDiagram`.
- Avoid `flowchart`, `classDiagram`, and advanced blocks like `opt/alt/par`.
- Keep node labels conservative (quoted labels; avoid inline newlines).

## MUST NOT DO

- Do not modify kernel source code. Output is documentation only.
- Do not proceed without explicit user confirmation.
- Do not leave Mermaid fenced blocks unclosed.
