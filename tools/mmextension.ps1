# Windows entry point for tools/mmextension.sh.
#
#   .\tools\mmextension.ps1 check
#   .\tools\mmextension.ps1 fetch [--commit SHA] [--update-env]
#
# A wrapper rather than a port: the packaging rules (which files of the
# MMExtension repository go into the snapshot) must exist only once, or the two
# versions would drift apart. The shell script needs git anyway, and every
# Windows machine that has git also has the bash that ships with it.
param(
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$ScriptArgs
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib.ps1"

Invoke-ShellScript -Script 'tools/mmextension.sh' -ScriptArgs $ScriptArgs
