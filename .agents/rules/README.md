---
trigger: always_on
---

# AI Rules Organization

The project's AI instructions are organized into two layers to ensure context efficiency:

1. **Root `AGENTS.md`**: Contains the "Always-On" project guardrails (FVM, Riverpod, Monorepo hygiene, Analysis).
2. **`.agents/skills/`**: Contains modular, task-specific "Playbooks" (Spec compliance, UI best practices, Code review).

## Governance

- **State Management**: The project uses **Riverpod**.
- **Linting**: Rules follow the Very Good Ventures (VGV) `very_good_analysis` guidelines.
- **Commands**: All commands must be run via `fvm`.
- **Semantic Label Keys** Apply semantic labelings and use widget key standards
