#!/bin/sh
# Links .agents/skills into .claude/skills so Claude Code can discover project skills.
mkdir -p .claude
ln -sfn "$(pwd)/.agents/skills" "$(pwd)/.claude/skills"
echo "Claude Code: .claude/skills linked to .agents/skills"
