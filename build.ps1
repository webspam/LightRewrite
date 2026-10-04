param(
  [Parameter(Mandatory = $false)]
  [string]$RepoRoot = $PSScriptRoot,
  [switch]$SkipWcc,
  [switch]$SkipDlc,
  [switch]$DebugEditor,
  [switch]$NextGen,
  [switch]$Compile
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
  $psi.Arguments = "$Arguments -agreetoterms"
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

function Copy-XmlAsUtf16Le([string]$Source, [string]$Destination) {
  $xml = [System.IO.File]::ReadAllText($Source) -replace '^(\s*<\?xml[^>]*encoding=["''])UTF-8(["''])', '${1}UTF-16${2}'
  [System.IO.File]::WriteAllText($Destination, $xml, [System.Text.Encoding]::Unicode)
}

function Find-ProfileInheritanceProblem {
  param(
    [Parameter(Mandatory)] [string] $ProfileName,
    [Parameter(Mandatory)] [hashtable] $ProfileBases,
    [System.Collections.Generic.List[string]] $Seen = [System.Collections.Generic.List[string]]::new(),
    [string[]] $Path = @()
  )

  if ($Path -contains $ProfileName) {
    return "circular inheritance: $(($Path + $ProfileName) -join ' -> ')"
  }
  # Reject diamond inheritance in base profiles
  if ($Seen -contains $ProfileName) {
    return "diamond inheritance: '$ProfileName' was already seen"
  }
  $Seen.Add($ProfileName)

  foreach ($base in $ProfileBases[$ProfileName]) {
    if (!$ProfileBases.ContainsKey($base)) {
      Write-Warning "Profile '$ProfileName' inherits from unknown base '$base'"
    }
    $problem = Find-ProfileInheritanceProblem -ProfileName $base -ProfileBases $ProfileBases -Seen $Seen -Path ($Path + $ProfileName)
    if ($problem) { return $problem }
  }

  return $null
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

$compiledScriptsDir = Join-Path $buildRoot "compiledScripts"

if ($Compile) {
  $gameContent0Dir = $env:WITCHER_CONTENT0_PATH
  if (!$gameContent0Dir -or !(Test-Path -LiteralPath $gameContent0Dir)) {
    throw "Witcher 3 content0 directory not found. Set WITCHER_CONTENT0_PATH. Looked for: $gameContent0Dir"
  }
}

$dlcRoot = Join-Path $buildRoot "dlc"
$dlcBundleDir = Join-Path $buildRoot "dlcBundle"
$dlcOutDir = Join-Path $dlcRoot "dlclightrewrite/content"
$dlcSourceDir = Join-Path $RepoRoot "dlc"

# Main execution

$xmlSourceDir = Join-Path $RepoRoot "data"

# Reject diamond or circular profile inheritance before touching the build dirs
$profileBases = @{}
$inheritsDeclaredIn = @{}
Get-ChildItem -Path $xmlSourceDir -Filter "*.xml" -Recurse | ForEach-Object {
  $doc = [xml][System.IO.File]::ReadAllText($_.FullName)
  foreach ($overrides in $doc.SelectNodes('//overrides')) {
    $profileName = $overrides.GetAttribute('profile_name')
    if (!$profileName) { continue }
    if (!$profileBases.ContainsKey($profileName)) { $profileBases[$profileName] = @() }
    foreach ($inherits in $overrides.SelectNodes('inherits')) {
      if ($inheritsDeclaredIn.ContainsKey($profileName)) {
        throw "Profile '$profileName' declares <inherits> more than once: in $($inheritsDeclaredIn[$profileName]) and $($_.Name)"
      }
      $inheritsDeclaredIn[$profileName] = $_.Name
      foreach ($base in $inherits.InnerText -split ',') {
        $base = $base.Trim()
        if ($base -and $profileBases[$profileName] -notcontains $base) {
          $profileBases[$profileName] += $base
        }
      }
    }
  }
}

foreach ($profileName in @($profileBases.Keys)) {
  $problem = Find-ProfileInheritanceProblem -ProfileName $profileName -ProfileBases $profileBases
  if ($problem) {
    throw "Profile '$profileName' has $problem"
  }
}

# Clean build dirs
if (!$SkipWcc) {
  Remove-DirectoryIfExists $bundleDir
  New-Directory $bundleDir

  if ($DebugEditor) {
    $iconColoursFile = Join-Path $RepoRoot "tools/icon-colours.txt"
    $bundleIconsDir = Join-Path $bundleDir "gameplay/gui_new/icons"

    $iconColours = Get-Content -Raw -LiteralPath $iconColoursFile
    & "$RepoRoot/tools/New-DebugIconColours.ps1" -Colours $iconColours -OutputDirectory $bundleIconsDir
  }
}
if (!$SkipDlc) {
  Remove-DirectoryIfExists $dlcRoot
  Remove-DirectoryIfExists $dlcBundleDir
  New-Directory $dlcBundleDir
  Copy-Item -Recurse -LiteralPath $dlcSourceDir -Destination $dlcBundleDir
}

Remove-DirectoryIfExists $modsRoot

# Stage XML files into the in-bundle path
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
  $destination = Join-Path $xmlDestDir $target
  if ($NextGen) {
    Copy-XmlAsUtf16Le -Source $_.FullName -Destination $destination
  }
  else {
    Copy-Item -LiteralPath $_.FullName -Destination $destination
  }
}

# Copy mod scripts
Copy-Item -Recurse -Filter "*.ws" -Path (Join-Path $RepoRoot "src") -Destination $scriptsDir

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

if ($Compile) {
  Remove-DirectoryIfExists $compiledScriptsDir
  New-Directory $compiledScriptsDir

  $patchDir = Join-Path $RepoRoot "src"
  try {
    Invoke-WccLite -Arguments "compilescripts `"$gameContent0Dir`" -out=`"$compiledScriptsDir`" -patch=`"$patchDir`""
  }
  catch {
    throw "Error compiling scripts using wcc_lite:`n`n$($_.Exception.Message)"
  }

  Move-Item -LiteralPath (Join-Path $compiledScriptsDir "blob.rsblob") -Destination (Join-Path $modContentDir "precompiled.rsblob")
  Remove-DirectoryIfExists $compiledScriptsDir
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
