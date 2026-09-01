# Windows entry point for build.sh.
#
#   .\build.ps1                    build\ and dist\MMCheat-<version>.zip
#   .\build.ps1 --no-zip           only the build\ folder
#   .\build.ps1 --version          print the version from about.lua
#   .\build.ps1 --fetch-binaries   (re-)download the bundled binaries
#
# A wrapper rather than a port: what goes into the package must be listed in
# one place only, or this file and build.sh would drift apart. bash comes with
# Git for Windows, which any clone of this repository implies. Zipping still
# happens natively through tools/zip.ps1, which build.sh picks when neither
# zip nor 7z is installed.
param(
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$ScriptArgs
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\tools\lib.ps1"

Invoke-ShellScript -Script 'build.sh' -ScriptArgs $ScriptArgs
