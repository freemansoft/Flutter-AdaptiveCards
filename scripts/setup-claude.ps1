# Links .agents/skills into .claude/skills so Claude Code can discover project skills.
New-Item -Force -ItemType Directory -Path .claude | Out-Null
if (Test-Path .claude\skills) { Remove-Item -Recurse -Force .claude\skills }
New-Item -ItemType Junction -Path .claude\skills -Target (Resolve-Path .agents\skills)
Write-Host "Claude Code: .claude\skills linked to .agents\skills"
