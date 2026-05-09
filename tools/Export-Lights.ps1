<#
.SYNOPSIS
    Converts LRDebug export log lines into a LightRewrite XML override file.

.DESCRIPTION
    After running the in-game export (press the LRDebug_ExportEdited key while the
    debug editor is active), locate the game log and run this script against it.
    It parses every LRDebug_Export channel line, groups entries by entity file and layer path,
    and writes a valid UTF-16 XML file compatible with the data/ override format.

.PARAMETER LogFile
    Path to the game log file containing [LREXPORT] lines.
    If omitted, the value of the WITCHER_SCRIPTSLOG_PATH environment variable is used.

.PARAMETER OutputFile
    Path to write the generated XML file. Default: exported_lights.xml

.PARAMETER Profile
    The profile_name attribute for the <overrides> block. Default: Default

.PARAMETER Weight
    The weight attribute for the <overrides> block (0-255). Default: 75

.PARAMETER Force
    Overwrite the output file if it already exists.

    Duplicate entries (same entity file and layer path) are written to a separate
    <overrides> block named <Profile>_Duplicates so they are visible rather than
    silently merged. Exact duplicates are always collapsed to one entry.

.EXAMPLE
    .\tools\Export-Lights.ps1 -LogFile "C:\Users\User\Documents\The Witcher 3\mods.log"

.EXAMPLE
    .\tools\Export-Lights.ps1 -LogFile game.log -OutputFile white_orchard_edits.xml -Weight 60
#>

[CmdletBinding()]
param(
    [string] $LogFile = '',

    [string] $OutputFile = (Join-Path $PSScriptRoot '..\data\exported_lights.xml'),

    [string] $Profile = 'Exported',

    [ValidateRange(0, 255)]
    [int] $Weight = 75,

    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---- Log parsing ----

function ParseExportLines {
    param([string] $Path)

    $records = [System.Collections.Generic.List[hashtable]]::new()
    $doneCount = $null

    $sr = [System.IO.StreamReader]::new([System.IO.File]::Open($Path, 'Open', 'Read', 'ReadWrite'))
    try { $lines = $sr.ReadToEnd() -split "`r?`n" } finally { $sr.Dispose() }
    foreach ($line in $lines) {
        $tag = '[LRDebug_Export]'
        if (-not $line.StartsWith($tag)) { continue }

        $fragment = $line.Substring($tag.Length).Trim()
        $pairs = [regex]::Matches($fragment, '(\w+)=(\S+)')

        if ($pairs.Count -eq 0) { continue }

        $entry = @{}
        foreach ($m in $pairs) {
            $entry[$m.Groups[1].Value] = $m.Groups[2].Value
        }

        if ($entry.ContainsKey('done')) {
            if ($entry.ContainsKey('exported')) {
                $doneCount = [int]$entry['exported']
            }
            continue
        }

        if (-not $entry.ContainsKey('entityFile')) { continue }

        $records.Add($entry)
    }

    return $records, $doneCount
}

# ---- Grouping ----

$floatFields = 'brightness', 'radius', 'attenuation', 'shadowFadeDistance', 'shadowFadeRange', 'shadowBlendFactor', 'alignOffsetZ'
$intFields = 'colorR', 'colorG', 'colorB', 'alignPointLights', 'useSpotlightColor'

function CoerceEntry {
    param([hashtable] $raw)

    $out = @{}
    foreach ($kv in $raw.GetEnumerator()) {
        $k = $kv.Key
        $v = $kv.Value
        if ($k -in $floatFields) {
            $out[$k] = [double]::Parse($v, [System.Globalization.CultureInfo]::InvariantCulture)
        }
        elseif ($k -in $intFields) {
            $out[$k] = [int]$v
        }
        else {
            $out[$k] = $v
        }
    }
    return $out
}

function EntriesIdentical {
    param([hashtable] $A, [hashtable] $B)
    foreach ($kv in $A.GetEnumerator()) {
        if ($kv.Key -in 'entityFile', 'layerPath') { continue }
        if (-not $B.ContainsKey($kv.Key) -or $B[$kv.Key] -ne $kv.Value) { return $false }
    }
    foreach ($kv in $B.GetEnumerator()) {
        if ($kv.Key -in 'entityFile', 'layerPath') { continue }
        if (-not $A.ContainsKey($kv.Key)) { return $false }
    }
    return $true
}

function GroupEntities {
    param([System.Collections.Generic.List[hashtable]] $Records)

    $primary  = [ordered]@{}
    $overflow = [ordered]@{}

    foreach ($raw in $Records) {
        $entry      = CoerceEntry $raw
        $entityFile = $entry['entityFile']
        $layerPath  = if ($entry.ContainsKey('layerPath')) { $entry['layerPath'] } else { '' }
        $key        = "$entityFile|$layerPath"

        if (-not $primary.Contains($key)) {
            $primary[$key] = $entry
        }
        elseif (-not (EntriesIdentical $primary[$key] $entry)) {
            $overflow["$key|$($overflow.Count)"] = $entry
        }
    }

    return $primary, $overflow
}

# ---- Tag name assignment ----

function Sanitize {
    param([string] $Name)
    return [regex]::Replace($Name, '[^A-Za-z0-9_]', '_')
}

function AssignTagNames {
    param(
        [System.Collections.Specialized.OrderedDictionary] $Primary,
        [System.Collections.Specialized.OrderedDictionary] $Overflow
    )

    $seenBases = @{}
    $tagNames  = @{}

    foreach ($dict in $Primary, $Overflow) {
        foreach ($key in $dict.Keys) {
            $base = 'LR_Edited_' + (Sanitize $dict[$key]['entityFile'])
            $seenBases[$base] = ($seenBases[$base] ?? 0) + 1
            $n = $seenBases[$base]
            $tagNames[$key] = if ($n -eq 1) { $base } else { "${base}_${n}" }
        }
    }

    return $tagNames
}

# ---- Float formatting ----

function FmtFloat {
    param([double] $Value)
    # 'G' removes trailing zeros; use InvariantCulture to guarantee dot as separator.
    return $Value.ToString('G', [System.Globalization.CultureInfo]::InvariantCulture)
}

# ---- XML generation ----

function BuildOverrideElement {
    param(
        [System.Xml.XmlDocument] $Doc,
        [hashtable]              $Params,
        [string]                 $TagName
    )

    $entityFile = $Params['entityFile']
    $layerPath = if ($Params.ContainsKey('layerPath')) { $Params['layerPath'] } else { '' }

    $override = $Doc.CreateElement('override')
    $override.SetAttribute('tag_name', $TagName)
    $override.SetAttribute('label', 'edited_' + (Sanitize $entityFile))

    if ($Params.ContainsKey('brightness')) { $override.SetAttribute('brightness', (FmtFloat $Params['brightness'])) }
    if ($Params.ContainsKey('radius')) { $override.SetAttribute('radius', (FmtFloat $Params['radius'])) }
    if ($Params.ContainsKey('attenuation')) { $override.SetAttribute('attenuation', (FmtFloat $Params['attenuation'])) }
    if ($Params.ContainsKey('useSpotlightColor')) {
        $val = if ($Params['useSpotlightColor'] -eq 1) { 'true' } else { 'false' }
        $override.SetAttribute('use_spotlight_color', $val)
    }

    # <match mode="exact"> for entity file stem
    $matchEntity = $Doc.CreateElement('match')
    $matchEntity.SetAttribute('mode', 'exact')
    $matchEntity.InnerText = $entityFile
    $override.AppendChild($matchEntity) | Out-Null

    # <match type="layer" mode="exact"> for layer file
    if ($layerPath -ne '') {
        $matchLayer = $Doc.CreateElement('match')
        $matchLayer.SetAttribute('type', 'layer')
        $matchLayer.SetAttribute('mode', 'exact')
        $matchLayer.InnerText = $layerPath
        $override.AppendChild($matchLayer) | Out-Null
    }

    # <shadows> — only when at least one shadow field is present
    $hasShadows = $Params.ContainsKey('shadowFadeDistance') -or
    $Params.ContainsKey('shadowFadeRange') -or
    $Params.ContainsKey('shadowBlendFactor')
    if ($hasShadows) {
        $shadows = $Doc.CreateElement('shadows')
        if ($Params.ContainsKey('shadowFadeDistance')) { $shadows.SetAttribute('fade_distance', (FmtFloat $Params['shadowFadeDistance'])) }
        if ($Params.ContainsKey('shadowFadeRange')) { $shadows.SetAttribute('fade_range', (FmtFloat $Params['shadowFadeRange'])) }
        if ($Params.ContainsKey('shadowBlendFactor')) { $shadows.SetAttribute('blend_factor', (FmtFloat $Params['shadowBlendFactor'])) }
        $override.AppendChild($shadows) | Out-Null
    }

    # <colour> — only when color fields are present
    if ($Params.ContainsKey('colorR')) {
        $colour = $Doc.CreateElement('colour')
        $colour.SetAttribute('r', [string]$Params['colorR'])
        $colour.SetAttribute('g', [string]($Params.ContainsKey('colorG') ? $Params['colorG'] : 0))
        $colour.SetAttribute('b', [string]($Params.ContainsKey('colorB') ? $Params['colorB'] : 0))
        $override.AppendChild($colour) | Out-Null
    }

    # <align_point_lights> — only when alignPointLights is present
    if ($Params.ContainsKey('alignPointLights')) {
        $align = $Doc.CreateElement('align_point_lights')
        $align.SetAttribute('x', '0')
        $align.SetAttribute('y', '0')
        $align.SetAttribute('z', (FmtFloat ($Params.ContainsKey('alignOffsetZ') ? $Params['alignOffsetZ'] : 0.0)))
        $override.AppendChild($align) | Out-Null
    }

    return $override
}

function BuildXml {
    param(
        [System.Collections.Specialized.OrderedDictionary] $Groups,
        [System.Collections.Specialized.OrderedDictionary] $Overflow,
        [hashtable] $TagNames,
        [string] $ProfileName,
        [int] $WeightValue
    )

    $doc = [System.Xml.XmlDocument]::new()
    $decl = $doc.CreateXmlDeclaration('1.0', 'UTF-16', $null)
    $doc.AppendChild($decl) | Out-Null

    $root = $doc.CreateElement('redxml')
    $root.SetAttribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance')
    $root.SetAttribute('noNamespaceSchemaLocation', 'http://www.w3.org/2001/XMLSchema-instance', 'LightRewriteDefinitions.xsd')
    $doc.AppendChild($root) | Out-Null

    $custom = $doc.CreateElement('custom')
    $root.AppendChild($custom) | Out-Null

    $lr = $doc.CreateElement('light_rewrite')
    $custom.AppendChild($lr) | Out-Null

    if ($Overflow.Count -gt 0) {
        $lr.AppendChild($doc.CreateComment(" WARNING: $($Overflow.Count) conflicting duplicate(s) were found. They are stored in the ${ProfileName}_Duplicates overrides block below. ")) | Out-Null
    }

    $overridesEl = $doc.CreateElement('overrides')
    $overridesEl.SetAttribute('profile_name', $ProfileName)
    $overridesEl.SetAttribute('weight', [string]$WeightValue)
    $lr.AppendChild($overridesEl) | Out-Null

    foreach ($key in $Groups.Keys) {
        $el = BuildOverrideElement $doc $Groups[$key] $TagNames[$key]
        $overridesEl.AppendChild($el) | Out-Null
    }

    if ($Overflow.Count -gt 0) {
        $lr.AppendChild($doc.CreateComment(" Duplicates: these entries share an entity file and layer path with an entry above but had conflicting field values. Review and merge manually. ")) | Out-Null

        $dupEl = $doc.CreateElement('overrides')
        $dupEl.SetAttribute('profile_name', "${ProfileName}_Duplicates")
        $dupEl.SetAttribute('weight', [string]$WeightValue)
        $lr.AppendChild($dupEl) | Out-Null

        foreach ($key in $Overflow.Keys) {
            $el = BuildOverrideElement $doc $Overflow[$key] $TagNames[$key]
            $dupEl.AppendChild($el) | Out-Null
        }
    }

    return $doc
}

function WriteUtf16Xml {
    param(
        [System.Xml.XmlDocument] $Doc,
        [string] $Path
    )

    $settings = [System.Xml.XmlWriterSettings]::new()
    $settings.Encoding = [System.Text.Encoding]::Unicode
    $settings.Indent = $true

    $writer = [System.Xml.XmlWriter]::Create($Path, $settings)
    try {
        $Doc.WriteTo($writer)
    }
    finally {
        $writer.Close()
    }
}

# ---- Entry point ----

if ($LogFile -eq '') {
    if ($env:WITCHER_SCRIPTSLOG_PATH) {
        $LogFile = $env:WITCHER_SCRIPTSLOG_PATH
    } else {
        Write-Error 'No log file specified. Provide -LogFile or set WITCHER_SCRIPTSLOG_PATH.'
        exit 1
    }
}

if (-not (Test-Path $LogFile)) {
    Write-Error "Log file not found: $LogFile"
    exit 1
}

if ((Test-Path $OutputFile) -and -not $Force) {
    Write-Error "Output file already exists: $OutputFile (use -Force to overwrite)"
    exit 1
}

$records, $doneCount = ParseExportLines $LogFile

if ($records.Count -eq 0) {
    Write-Host 'No [LREXPORT] entity lines found in the log.'
    exit 0
}

Write-Host "Parsed $($records.Count) export record(s)."
if ($null -ne $doneCount) {
    Write-Host "Game reported $doneCount exported light(s)."
}

$primary, $overflow = GroupEntities $records
Write-Host "Grouped into $($primary.Count) unique override(s)."
if ($overflow.Count -gt 0) {
    Write-Host "$($overflow.Count) conflicting duplicate(s) written to '${Profile}_Duplicates' overrides block."
}

$tagNames = AssignTagNames $primary $overflow
$doc = BuildXml $primary $overflow $tagNames $Profile $Weight
WriteUtf16Xml $doc $OutputFile

Write-Host "Written to: $OutputFile"
