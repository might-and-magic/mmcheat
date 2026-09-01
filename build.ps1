# Build the MMCheat release package (Windows).
#
#   .\build.ps1                  build\ and dist\MMCheat-<version>.zip
#   .\build.ps1 -NoZip           only the build\ folder
#   .\build.ps1 -ShowVersion     print the version from about.lua and exit
#   .\build.ps1 -FetchBinaries   (re-)download the bundled binaries and exit
#
# Equivalent to ./build.sh, which is what CI uses. The two bundled binaries
# (ExeMods\iup.dll and vcruntime140.dll) are not kept in this repository; they
# are downloaded from the "binaries" release when missing. See DEVELOPMENT.md.
param(
	[switch]$NoZip,
	[switch]$ShowVersion,
	[switch]$FetchBinaries
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # a visible progress bar makes downloads much slower

Set-Location -LiteralPath $PSScriptRoot

$About = 'Scripts\Modules\MMCheat\about.lua'
$BuildDir = 'build'
$DistDir = 'dist'
$BinariesTag = if ($env:MMCHEAT_BINARIES_TAG) { $env:MMCHEAT_BINARIES_TAG } else { 'binaries' }
$BinariesUrl = if ($env:MMCHEAT_BINARIES_URL) { $env:MMCHEAT_BINARIES_URL } `
	else { "https://github.com/might-and-magic/mmcheat/releases/download/$BinariesTag" }

# Files that MMCheat generates at runtime and that must not be packaged
$RuntimeFiles = @('conf.ini', 'coords.txt')

function Get-McVersion {
	$line = Select-String -LiteralPath $About -Pattern '^\s*version\s*=\s*"([^"]*)"' | Select-Object -First 1
	if (-not $line) { throw "cannot read the version from $About" }
	return $line.Matches[0].Groups[1].Value
}

function Get-Binary([string]$Path, [string]$Asset) {
	$dir = Split-Path -Parent $Path
	if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
	Write-Host "downloading $Asset from the $BinariesTag release..."
	Invoke-WebRequest -Uri "$BinariesUrl/$Asset" -OutFile $Path -UseBasicParsing
}

function Confirm-Binaries([switch]$Force) {
	if ($Force -or -not (Test-Path -LiteralPath 'ExeMods\iup.dll')) {
		Get-Binary 'ExeMods\iup.dll' 'iup.dll'
	}
	if ($Force -or -not (Test-Path -LiteralPath 'vcruntime140.dll')) {
		Get-Binary 'vcruntime140.dll' 'vcruntime140.dll'
	}
}

if ($ShowVersion) { Get-McVersion; exit 0 }

if ($FetchBinaries) {
	Confirm-Binaries -Force
	Write-Host 'binaries are in place'
	exit 0
}

$version = Get-McVersion
Confirm-Binaries

Write-Host "building MMCheat $version"

if (Test-Path -LiteralPath $BuildDir) { Remove-Item -LiteralPath $BuildDir -Recurse -Force }
New-Item -ItemType Directory -Path "$BuildDir\ExeMods" -Force | Out-Null
New-Item -ItemType Directory -Path "$BuildDir\Scripts\General" -Force | Out-Null
New-Item -ItemType Directory -Path "$BuildDir\Scripts\Modules" -Force | Out-Null

Copy-Item 'ExeMods\iup.dll' "$BuildDir\ExeMods\"
Copy-Item 'vcruntime140.dll' "$BuildDir\"
Copy-Item 'Scripts\General\MMCheat.lua' "$BuildDir\Scripts\General\"
Copy-Item 'Scripts\Modules\iup.lua' "$BuildDir\Scripts\Modules\"
Copy-Item 'Scripts\Modules\MMCheat' "$BuildDir\Scripts\Modules\" -Recurse

foreach ($f in $RuntimeFiles) {
	$p = "$BuildDir\Scripts\Modules\MMCheat\$f"
	if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force }
}

$count = (Get-ChildItem -LiteralPath $BuildDir -Recurse -File).Count
Write-Host "$BuildDir\ ready ($count files)"

if (-not $NoZip) {
	$zip = "$DistDir\MMCheat-$version.zip"
	& "$PSScriptRoot\tools\zip.ps1" -Source $BuildDir -Destination $zip
	Write-Host $zip
	Write-Output $zip
}
