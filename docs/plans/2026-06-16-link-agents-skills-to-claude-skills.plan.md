# Plan: Auto-link `.agents/skills` to `.claude/skills` on workspace open

## Context

This repo uses `.agents/skills/` as the single source of truth for all AI agent skills
(Cursor, Antigravity, GitHub Copilot, and others). Claude Code, however, expects skills
at `.claude/skills/`. Without a link between these two locations, Claude Code cannot
discover the 49 skills already defined in `.agents/skills/`.

The solution creates platform-appropriate links (symlink on Mac/Linux, junction on
Windows) via scripts, and uses a VS Code `tasks.json` with `runOn: folderOpen`
to run the appropriate script automatically whenever a developer opens the workspace.
`.claude/skills` is gitignored so the generated link is never committed.

Developers on all platforms (Mac, Linux, Windows) get Claude Code skill access without
manual setup after the first workspace open prompt.

---

## Files to Create

### 1. `scripts/setup-claude.sh` (Mac / Linux)

```sh
#!/bin/sh
# Links .agents/skills into .claude/skills so Claude Code can discover project skills.
mkdir -p .claude
ln -sfn "$(pwd)/.agents/skills" "$(pwd)/.claude/skills"
echo "Claude Code: .claude/skills linked to .agents/skills"
```

### 2. `scripts/setup-claude.ps1` (Windows)

```powershell
# Links .agents/skills into .claude/skills so Claude Code can discover project skills.
New-Item -Force -ItemType Directory -Path .claude | Out-Null
if (Test-Path .claude\skills) { Remove-Item -Recurse -Force .claude\skills }
New-Item -ItemType Junction -Path .claude\skills -Target (Resolve-Path .agents\skills)
Write-Host "Claude Code: .claude\skills linked to .agents\skills"
```

### 3. `.vscode/tasks.json`

Place alongside the existing `launch.json` and `settings.json`. Uses
`runOn: folderOpen` so Cursor/VS Code runs the script on every workspace load
(user is prompted to Allow once per workspace, then it runs silently).

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Setup Claude Skills Link",
      "type": "shell",
      "command": "sh scripts/setup-claude.sh",
      "windows": {
        "command": "pwsh scripts/setup-claude.ps1"
      },
      "runOptions": {
        "runOn": "folderOpen"
      },
      "presentation": {
        "reveal": "silent",
        "panel": "shared"
      }
    }
  ]
}
```

---

## Files to Modify

### 4. `.gitignore`

Add one line to prevent the generated link from being committed:

```text
.claude/skills
```

Add it near the `.agents/brain/` entry (line ~20) for logical grouping with other
generated/transient AI agent paths.

### 5. `README.md`

Add a short section under the existing **AI Agent support** paragraph explaining
that `.claude/skills` is auto-created on workspace open and that Claude Code users
get skills from `.agents/skills` automatically. No manual setup needed.

### 6. `docs/plans/2026-06-16-link-agents-skills-to-claude-skills.plan.md`

Copy this plan file verbatim into `docs/plans/` following the existing naming
convention (`YYYY-MM-DD-description.plan.md`).

---

## Existing Patterns to Follow

- `scripts/publish.ps1` — precedent for PowerShell scripts in `scripts/`
- `docs/plans/` — 15+ existing plans confirm this is the right home for the plan copy
- `.agents/brain/` in `.gitignore` — precedent for ignoring generated AI-agent paths

---

## Verification

1. **Mac/Linux**: Run `sh scripts/setup-claude.sh` from repo root → confirm
   `.claude/skills` is a symlink pointing at `.agents/skills/` (`ls -la .claude/`).
2. **Windows**: Run `pwsh scripts/setup-claude.ps1` → confirm `.claude\skills` is a
   junction (`Get-Item .claude\skills | Select-Object LinkType, Target`).
3. **Cursor/VS Code**: Close and reopen the workspace → confirm the "Setup Claude
   Skills Link" task runs (check Terminal > Tasks output panel).
4. **Claude Code**: After the link is created, open Claude Code in this repo and verify
   `/` shows the project skills (e.g., `adaptive-cards-testing`, `code-review`, etc.).
5. **Git**: Confirm `git status` shows no changes to `.claude/skills` after the link
   is created.
