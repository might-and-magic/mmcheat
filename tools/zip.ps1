# Zips the *contents* of -Source into -Destination.
#
# Used on Windows by build.ps1 and as a fallback by tools/lib.sh. Entry names
# are written with forward slashes: [ZipFile]::CreateFromDirectory would use
# backslashes on Windows, which violates the ZIP spec and trips up other tools.
param(
	[Parameter(Mandatory = $true)][string]$Source,
	[Parameter(Mandatory = $true)][string]$Destination
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

$src = (Resolve-Path -LiteralPath $Source).Path.TrimEnd('\', '/')

$destDir = Split-Path -Parent $Destination
if ($destDir -and -not (Test-Path -LiteralPath $destDir)) {
	New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}
if (Test-Path -LiteralPath $Destination) {
	Remove-Item -LiteralPath $Destination -Force
}
# Resolve to an absolute path: ZipFile::Open uses the process working directory
$dest = [System.IO.Path]::GetFullPath(
	[System.IO.Path]::Combine((Get-Location).Path, $Destination))

$archive = [System.IO.Compression.ZipFile]::Open($dest, 'Create')
try {
	Get-ChildItem -LiteralPath $src -Recurse -File | Sort-Object FullName | ForEach-Object {
		$rel = $_.FullName.Substring($src.Length).TrimStart('\', '/').Replace('\', '/')
		[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
			$archive, $_.FullName, $rel, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
	}
}
finally {
	$archive.Dispose()
}
