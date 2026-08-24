#!/bin/sh
# Links .agents to .claude so other agents (Cursor, Copilot) can still
# discover project skills and rules. Claude Code reads .claude/ directly.
rm -rf .agents
ln -sfn "$(pwd)/.claude" "$(pwd)/.agents"
echo ".agents linked to .claude"
