[CmdletBinding()]
param(
  [string]$Prefix = (Join-Path $HOME '.local\bin')
)

$ErrorActionPreference = 'Stop'
$targetDirectory = [System.IO.Path]::GetFullPath($Prefix)
$removed = $false

foreach ($file in @('git-sync-all', 'git-sync-all.cmd')) {
  $path = Join-Path $targetDirectory $file
  if (Test-Path -LiteralPath $path) {
    Remove-Item -LiteralPath $path -Force
    Write-Output "Removed $path"
    $removed = $true
  }
}

if (-not $removed) {
  Write-Output "git-sync-all is not installed at $targetDirectory"
}
