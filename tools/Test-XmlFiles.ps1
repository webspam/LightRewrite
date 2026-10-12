[CmdletBinding()]
param([string[]] $Path = "$PSScriptRoot/../data")

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$xsd = (Resolve-Path "$PSScriptRoot/../data/LightRewriteDefinitions.xsd").Path
$total = 0
$failed = 0

foreach ($file in Get-ChildItem $Path -Recurse -Filter *.xml) {
    $total++
    $xml = [xml]::new()
    $xml.Schemas.Add($null, $xsd) | Out-Null
    try {
        $xml.Load($file.FullName)
        $xml.Validate($null)
        if ($VerbosePreference -ne 'SilentlyContinue') {
            Write-Host -ForegroundColor Green -NoNewline 'PASS  '
            Write-Host $file.FullName
        }
    }
    catch {
        $failed++
        Write-Host -ForegroundColor Red "FAIL  $($file.FullName)`n      $($_.Exception.Message)"
    }
}

Write-Host "$total file(s) checked, $failed invalid."
if ($failed) { exit 1 }
