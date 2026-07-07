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

### Superpowers (project — shared with the repo)

```bash
npx skills add obra/superpowers --skill '*' --agent universal --yes
```

Source: [github.com/obra/superpowers](https://github.com/obra/superpowers)

This installs 14 skills (brainstorming, writing-plans, test-driven-development, systematic-debugging, …) into `.agents/skills/` and updates `skills-lock.json`.

### Superpowers (everyone but Claude — user-level)

For skills available in **all** projects when using Cursor:

```bash
npx skills add obra/superpowers --skill '*' --agent cursor --global --yes
```

Skills are copied to `~/.agents/skills/`.

#### Optional: Cursor plugin (hooks and commands)

Cursor *** support will eventually be removed with the purchase of xAI **

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
npx skills update dart-add-unit-test flutter-add-widget-test brainstorming
```

Review diffs under `.agents/skills/` after updating. Reconcile project-specific overrides (for example `adaptive-cards-dart-flutter-fvm` wrapping bare `flutter` commands from upstream skills).

Restore from lock file after a fresh clone:

```bash
npx skills experimental_install
```
