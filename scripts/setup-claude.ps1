# Links .agents to .claude so other agents (Cursor, Antigravity, Copilot) can still
# discover project skills and rules. Claude Code reads .claude/ directly.
if (Test-Path .agents) { Remove-Item -Recurse -Force .agents }
New-Item -ItemType Junction -Path .agents -Target (Resolve-Path .claude)
Write-Host ".agents linked to .claude"
