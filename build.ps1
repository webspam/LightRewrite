param(
  [Parameter(Mandatory = $false)]
  [string]$RepoRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"

function New-Directory([string]$Path) {
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Remove-DirectoryIfExists([string]$LiteralPath) {
  if (Test-Path -LiteralPath $LiteralPath) {
    Remove-Item -Recurse -Force -LiteralPath $LiteralPath
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

  if (-not [string]::IsNullOrWhiteSpace($stderr)) {
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
if (-not (Test-Path -Path $wccLiteExe)) {
  throw "wcc_lite.exe not found. Set WCC_LITE_PATH or WCC_LITE_DIR. Looked for: $wccLiteExe"
}

$buildDir = Join-Path $RepoRoot "build/bundle"
$modsRoot = Join-Path $RepoRoot "mods"
$modContentDir = Join-Path $modsRoot "modLightRewrite/content"
$scriptsDir = Join-Path $modContentDir "scripts/local/modLightRewrite"

# Main execution

# Clean build dirs
Remove-DirectoryIfExists $buildDir
Remove-DirectoryIfExists $modsRoot

New-Directory $buildDir
New-Directory $scriptsDir

# Stage XML files into the in-bundle path
$xmlSource = Join-Path $RepoRoot "data/*.xml"
$xmlDestDir = Join-Path $buildDir "gameplay/abilities"

New-Directory $xmlDestDir
Copy-Item -Force -Path $xmlSource -Destination $xmlDestDir

# Prefix all XML files with "lightrewrite_"
Get-ChildItem -Path $defaultsDestDir -Filter "*.xml" | ForEach-Object {
  Rename-Item -Path $_.FullName -NewName "lightrewrite_$($_.Name)"
}

# Copy mod scripts
Copy-Item -Force -Recurse -Path (Join-Path $RepoRoot "src/*") -Destination $scriptsDir

# Copy prebuilt localisation binaries (generated out-of-band)
New-Directory $modContentDir
Copy-Item -Force -Path (Join-Path $RepoRoot "l10n/*.w3strings") -Destination $modContentDir

# Execute wcc_lite to pack the content into a new bundle
try {
  Invoke-WccLite -Arguments "pack -dir=`"$buildDir`" -outdir=`"$modContentDir`""
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