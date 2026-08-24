---
doc_type: how-to
---

# Install & update AI agent skills

Commands to install and update the agent skills this repo relies on. For what the skills are, where
they come from, and how agents load them, see [`AI-Agent-Support.md`](AI-Agent-Support.md).

Run everything below from the **repository root**.

## What installs itself

Nothing needs a manual step on a fresh clone. Two mechanisms cover it:

- **Project-authored skills** (`adaptive-cards-*`) are committed under `.claude/skills/`, which Claude Code reads directly. Nothing generates or links them.
- **Claude Code plugins** are declared at project scope in [`.claude/settings.json`](../.claude/settings.json), and `SessionStart` hooks in that same file run the marketplace-add and install commands each session. Claude Code prompts you to trust the repository folder the first time; plugins can execute arbitrary code, so the install is never silent.

The manual equivalents are below, for when a hook fails or you want to install outside this repo.

## Claude Code plugins

### Dart and Flutter team skills

The official plugin from the Dart and Flutter teams. Marketplace and plugin are both named
`dart-flutter`. It carries 12 `dart-*` skills, 10 `flutter-*` skills, and an MCP server entry for
`dart mcp-server`.

```bash
claude plugin marketplace add flutter/agent-plugins
claude plugin install dart-flutter@dart-flutter
```

Source: [github.com/flutter/agent-plugins](https://github.com/flutter/agent-plugins) ·
Docs: [Get started developing with AI](https://docs.flutter.dev/ai/get-started)

> The plugin's MCP entry launches a bare `dart`, which may not be the FVM-pinned SDK. Run the
> authoritative build, test, and analyze commands yourself with an `fvm` prefix.

### Superpowers and skill-creator

Both come from the official Anthropic marketplace:

```bash
claude plugin install superpowers@claude-plugins-official --scope project
claude plugin install skill-creator@claude-plugins-official --scope project
```

Then `/reload-plugins` (or restart). Verify with `/plugin` → **Installed**. Skills from plugins are
namespaced — `superpowers:brainstorming`, not `brainstorming`.

Source: [github.com/obra/superpowers](https://github.com/obra/superpowers)

## Using these skills outside this repo

Claude Code is the only agent this repo is set up for, and the plugins above are scoped to it. If you
want the Dart and Flutter skills in a different tool, or in Claude Code across all your projects,
install them at **user level** with the [`skills` CLI](https://www.npmjs.com/package/skills):

```bash
npx skills add dart-lang/skills --skill '*' --agent universal --global --yes
npx skills add flutter/agent-plugins --skill '*' --agent universal --global --yes
```

`--global` writes to `~/.agents/skills/`. Do not install them at project scope — Claude Code would
load a second copy alongside the plugin and pay for both every session, which is what removing the
vendored copies fixed.

> `flutter/skills` was renamed to `flutter/agent-plugins`; GitHub redirects the old URL.

## Updating

Plugins update from their marketplaces:

```bash
claude plugin marketplace update dart-flutter
claude plugin update dart-flutter@dart-flutter
```

List what is installed and where it came from:

```bash
claude plugin list
claude plugin marketplace list
```

User-level skills installed through the `skills` CLI update with `npx skills update`.

Project-authored `adaptive-cards-*` skills have no upstream — edit them directly under
`.claude/skills/`.
