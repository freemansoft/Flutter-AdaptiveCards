---
doc_type: how-to
---

# Install & update vendored AI skills

Commands to install and update the vendored agent skills for this repo. For what the skills are,
where they come from, and how agents load them, see [`AI-Agent-Support.md`](AI-Agent-Support.md).

## Installation

All vendored skills are installed with the [`skills` CLI](https://www.npmjs.com/package/skills) (`npx skills`). The `--agent universal` flag installs into `.agents/skills/`, which Cursor, Antigravity, and other agents recognize.

Run these commands from the **repository root**.

### Dart team skills

```bash
npx skills add dart-lang/skills --skill '*' --agent universal --yes
```

Source: [github.com/dart-lang/skills](https://github.com/dart-lang/skills)

### Flutter team skills

```bash
npx skills add flutter/skills --skill '*' --agent universal --yes
```

Source: [github.com/flutter/skills](https://github.com/flutter/skills)

### Superpowers (Claude Code — plugin, not vendored)

Superpowers is **not** installed with `npx skills` and is **not** in `skills-lock.json`. It ships as a Claude Code plugin that this repo enables at **project scope** in [`.claude/settings.json`](../.claude/settings.json), so Claude Code offers to install it when you trust the repo folder.

If it did not install automatically:

```bash
claude plugin install superpowers@claude-plugins-official --scope project
```

Then `/reload-plugins` (or restart). Verify with `/plugin` → **Installed**. Skills are namespaced — `superpowers:brainstorming`, not `brainstorming`.

Source: [github.com/obra/superpowers](https://github.com/obra/superpowers)

### Superpowers (everyone but Claude — user-level)

For skills available in **all** projects when using Cursor:

```bash
npx skills add obra/superpowers --skill '*' --agent cursor --global --yes
```

Skills are copied to `~/.agents/skills/`.

#### Optional: Cursor plugin (hooks and commands)

Cursor **\* support will eventually be removed with the purchase of xAI **

For automatic skill activation via Cursor hooks (recommended when using Cursor Agent):

1. Open **Agent** chat (`Cmd+L` / `Ctrl+L`).
2. Run:

   ```text
   /add-plugin superpowers
   ```

3. Start a new Agent session and verify with: `Do you have superpowers?`

Update or remove the plugin:

```text
/plugin-update superpowers
/plugin-remove superpowers
```

- See [Superpowers — Install on Cursor](https://obra-superpowers.mintlify.app/installation/cursor).
- See [Superpowers - Install for Claude Code](https://obra-superpowers.mintlify.app/installation/claude-code).

## Updating vendored skills

From the repository root:

```bash
npx skills update
```

Or update a single upstream repo:

```bash
npx skills update dart-add-unit-test flutter-add-widget-test
```

Review diffs under `.agents/skills/` after updating. Reconcile project-specific overrides (for example `adaptive-cards-dart-flutter-fvm` wrapping bare `flutter` commands from upstream skills).

Restore from lock file after a fresh clone:

```bash
npx skills experimental_install
```
