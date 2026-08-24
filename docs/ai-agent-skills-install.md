---
doc_type: how-to
---

# Install & update AI agent skills

Commands to install and update the agent skills this repo relies on. For what the skills are, where
they come from, and how agents load them, see [`AI-Agent-Support.md`](AI-Agent-Support.md).

Run everything below from the **repository root**.

## What installs itself

Nothing needs a manual step on a fresh clone. Two mechanisms cover it:

- **Project-authored skills** (`adaptive-cards-*`) are committed under `.claude/skills/`. `.agents` is a generated symlink to `.claude` (recreated by `scripts/setup-claude.sh`/`.ps1`, or the `folderOpen` task in `.vscode/tasks.json`), so Cursor and Copilot find the same files at `.agents/skills/`.
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

## Dart and Flutter skills for non-Claude agents

Cursor and Copilot do not read Claude Code plugins, so they see the project-authored
`adaptive-cards-*` skills only. To get the Dart and Flutter skills in one of those agents, install
them at **user level** with the [`skills` CLI](https://www.npmjs.com/package/skills):

```bash
npx skills add dart-lang/skills --skill '*' --agent universal --global --yes
npx skills add flutter/agent-plugins --skill '*' --agent universal --global --yes
```

`--global` writes to `~/.agents/skills/`. Install them at project scope instead and Claude Code
loads a second copy alongside the plugin, paying for both every session — which is what removing the
vendored copies fixed.

> `flutter/skills` was renamed to `flutter/agent-plugins`; GitHub redirects the old URL.

### Superpowers at user level

For Superpowers in **all** projects when using Cursor:

```bash
npx skills add obra/superpowers --skill '*' --agent cursor --global --yes
```

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
