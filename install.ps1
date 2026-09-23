[CmdletBinding()]
param(
  [string]$Prefix = (Join-Path $HOME '.local\bin'),
  [switch]$NoPath
)

$ErrorActionPreference = 'Stop'

function Find-GitBash {
  $bash = Get-Command bash -ErrorAction SilentlyContinue
  if ($bash) {
    return $bash.Source
  }

  $git = Get-Command git -ErrorAction SilentlyContinue
  if ($git) {
    $gitDirectory = Split-Path -Parent $git.Source
    $gitRoot = Split-Path -Parent $gitDirectory
    foreach ($candidate in @(
        (Join-Path $gitRoot 'bin\bash.exe'),
        (Join-Path $gitRoot 'usr\bin\bash.exe')
      )) {
      if (Test-Path -LiteralPath $candidate) {
        return $candidate
      }
    }
  }

  throw 'Git Bash was not found. Install Git for Windows, then run this installer again.'
}

$sourceDirectory = Split-Path -Parent $PSCommandPath
$targetDirectory = [System.IO.Path]::GetFullPath($Prefix)
$bashPath = Find-GitBash

New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null
Copy-Item -LiteralPath (Join-Path $sourceDirectory 'bin\git-sync-all') `
  -Destination (Join-Path $targetDirectory 'git-sync-all') -Force

$wrapperPath = Join-Path $targetDirectory 'git-sync-all.cmd'
@"
@echo off
"$bashPath" "%~dp0git-sync-all" %*
"@ | Set-Content -LiteralPath $wrapperPath -Encoding ascii

if (-not $NoPath) {
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  $pathEntries = @($userPath -split ';' | Where-Object { $_ })
  if ($pathEntries -notcontains $targetDirectory) {
    $newPath = (@($pathEntries) + $targetDirectory) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
  }
}

Write-Output "Installed git-sync-all to $targetDirectory"
if ($NoPath) {
  Write-Output "Add $targetDirectory to PATH, then run: git sync-all --help"
} else {
  Write-Output 'Open a new terminal, then run: git sync-all --help'
}
