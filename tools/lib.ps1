# Shared helpers for MMCheat's PowerShell entry points (the counterpart of
# tools/lib.sh). Dot-source it: . "$PSScriptRoot\lib.ps1"

function Find-Bash {
	<#
	.SYNOPSIS
	Path of a bash to run the shell scripts with, or throws.
	#>
	$cmd = Get-Command bash.exe -ErrorAction SilentlyContinue
	if ($cmd) { return $cmd.Source }

	# bash.exe sits next to git.exe in Git for Windows (git\cmd\git.exe -> git\bin\bash.exe)
	$git = Get-Command git.exe -ErrorAction SilentlyContinue
	if ($git) {
		$candidate = Join-Path (Split-Path -Parent (Split-Path -Parent $git.Source)) 'bin\bash.exe'
		if (Test-Path -LiteralPath $candidate) { return $candidate }
	}

	foreach ($p in @("$env:ProgramFiles\Git\bin\bash.exe", "${env:ProgramFiles(x86)}\Git\bin\bash.exe")) {
		if (Test-Path -LiteralPath $p) { return $p }
	}

	throw 'bash was not found. Install Git for Windows, which ships it.'
}

function Invoke-ShellScript {
	<#
	.SYNOPSIS
	Runs one of the repository's shell scripts from the repository root and
	exits with its exit code.
	#>
	param(
		[Parameter(Mandatory = $true)][string]$Script,
		[string[]]$ScriptArgs = @()
	)

	$bash = Find-Bash
	Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

	# The scripts write progress to stderr, which Windows PowerShell decorates
	# as a NativeCommandError - noise that looks like a failure. Unwrap those
	# records back into plain stderr lines and leave stdout untouched, so that
	# the output can still be captured. The exit code says whether it worked.
	$ErrorActionPreference = 'Continue'
	& $bash $Script @ScriptArgs 2>&1 | ForEach-Object {
		if ($_ -is [System.Management.Automation.ErrorRecord]) {
			[Console]::Error.WriteLine($_.Exception.Message)
		}
		else {
			$_
		}
	}
	exit $LASTEXITCODE
}
