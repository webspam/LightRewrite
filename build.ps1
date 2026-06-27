param(
  [Parameter(Mandatory = $false)]
  [string]$RepoRoot = $PSScriptRoot,
  [switch]$SkipWcc,
  [switch]$SkipDlc
)

$ErrorActionPreference = "Stop"

function New-Directory([string]$Path) {
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Remove-DirectoryIfExists([string]$LiteralPath) {
  if (Test-Path -LiteralPath $LiteralPath) {
    Remove-Item -Recurse -LiteralPath $LiteralPath
  }
}

function Invoke-WccLite {
  param([Parameter(Mandatory)] [string] $Arguments)

  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $script:wccLiteExe
  $psi.WorkingDirectory = Split-Path -Parent $script:wccLiteExe
  $psi.Arguments = $Arguments
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.CreateNoWindow = $true

  $p = [System.Diagnostics.Process]::new()
  $p.StartInfo = $psi
  [void]$p.Start()
  $stdout = $p.StandardOutput.ReadToEnd().Trim()
  $stderr = $p.StandardError.ReadToEnd().Trim()
  $null = $p.WaitForExit()

  if (![string]::IsNullOrWhiteSpace($stderr)) {
    throw $stderr
  }
  elseif ($stdout.EndsWith("Wcc operation failed")) {
    throw $stdout
  }

  if ($p.ExitCode -ne 0) {
    throw "wcc_lite.exe exited with code $($p.ExitCode):`n`n$stdout"
  }
}

# Configuration

$RepoRoot = (Resolve-Path -Path $RepoRoot).Path

& $RepoRoot\Import-Dotenv.ps1

$wccLiteExe = $env:WCC_LITE_PATH
if (!(Test-Path -Path $wccLiteExe)) {
  throw "wcc_lite.exe not found. Set WCC_LITE_PATH or WCC_LITE_DIR. Looked for: $wccLiteExe"
}

$buildRoot = Join-Path $RepoRoot "build"
$bundleDir = Join-Path $buildRoot "bundle"
$modsRoot = Join-Path $buildRoot "mods"
$modContentDir = Join-Path $modsRoot "modLightRewrite/content"
$scriptsDir = Join-Path $modContentDir "scripts/local/modLightRewrite"

$dlcRoot = Join-Path $buildRoot "dlc"
$dlcBundleDir = Join-Path $buildRoot "dlcBundle"
$dlcOutDir = Join-Path $dlcRoot "lightrewrite/content"
$dlcSourceDir = Join-Path $RepoRoot "dlc"

# Main execution

# Clean build dirs
if (!$SkipWcc) {
  Remove-DirectoryIfExists $bundleDir
  New-Directory $bundleDir
}
if (!$SkipDlc) {
  Remove-DirectoryIfExists $dlcRoot
  Remove-DirectoryIfExists $dlcBundleDir
  New-Directory $dlcBundleDir
  Copy-Item -Recurse -LiteralPath $dlcSourceDir -Destination $dlcBundleDir
}

Remove-DirectoryIfExists $modsRoot
New-Directory $scriptsDir

# Stage XML files into the in-bundle path
$xmlSourceDir = Join-Path $RepoRoot "data"
$xmlDestDir = Join-Path $bundleDir "gameplay/abilities"

New-Directory $xmlDestDir

# Prefix all XML files with "lightrewrite_"
Get-ChildItem -Path $xmlSourceDir -Filter "*.xml" -Recurse |
Sort-Object { ($_.FullName.Substring($xmlSourceDir.Length) -split '[\\/]').Count }, FullName |
ForEach-Object {
  $relDir = $_.Directory.FullName.Substring($xmlSourceDir.Length).Trim('\', '/')
  $dirName = ($relDir -replace '[\\/]', '_').ToLowerInvariant()
  # Top level files `_` prefix so subdirs can't clash
  $target = if (!$DirName) { "_lightrewrite_$($_.Name)" } else { "lightrewrite_${DirName}_$($_.Name)" }
  Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $xmlDestDir $target)
}

# Copy mod scripts
Copy-Item -Recurse -Path (Join-Path $RepoRoot "src/*") -Destination $scriptsDir

# Copy prebuilt localisation binaries (generated out-of-band)
New-Directory $modContentDir
Copy-Item -Path (Join-Path $RepoRoot "l10n/*.w3strings") -Destination $modContentDir

# Execute wcc_lite to pack the content into a new bundle
if ($SkipWcc) {
  Write-Host -ForegroundColor Yellow "⌛ Skipping wcc_lite (SkipWcc flag set)"
}
else {
  try {
    Invoke-WccLite -Arguments "pack -dir=`"$bundleDir`" -outdir=`"$modContentDir`""
  }
  catch {
    throw "Error packing content into a new bundle using wcc_lite:`n`n$($_.Exception.Message)"
  }

  try {
    Invoke-WccLite -Arguments "metadatastore -path=`"$modContentDir`""
  }
  catch {
    throw "Error generating metadata.store using wcc_lite:`n`n$($_.Exception.Message)"
  }
}

if (!$SkipDlc) {
  # DLC (entities)
  try {
    Invoke-WccLite -Arguments "pack -dir=`"$dlcBundleDir`" -outdir=`"$dlcOutDir`""
  }
  catch {
    throw "Error packing content into a new bundle using wcc_lite:`n`n$($_.Exception.Message)"
  }

  try {
    Invoke-WccLite -Arguments "metadatastore -path=`"$dlcOutDir`""
  }
  catch {
    throw "Error generating metadata.store using wcc_lite:`n`n$($_.Exception.Message)"
  }
}
