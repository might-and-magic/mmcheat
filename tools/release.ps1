# Windows entry point for tools/release.sh.
#
#   .\tools\release.ps1 1.2.0
#   .\tools\release.ps1 1.2.0 --dry-run
#
# A wrapper rather than a port, like the other .ps1 entry points here.
param(
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$ScriptArgs
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib.ps1"

Invoke-ShellScript -Script 'tools/release.sh' -ScriptArgs $ScriptArgs
