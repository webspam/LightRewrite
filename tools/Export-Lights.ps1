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

$floatFields = 'brightness', 'radius', 'attenuation', 'shadowFadeDistance', 'shadowFadeRange', 'shadowBlendFactor', 'alignOffsetZ', `
    'pointLightOffsetX', 'pointLightOffsetY', 'pointLightOffsetZ', `
    'spot_brightness', 'spot_radius', 'spot_attenuation', 'spot_shadowFadeDistance', 'spot_shadowFadeRange', 'spot_shadowBlendFactor', `
    'spot_innerAngle', 'spot_outerAngle', 'spot_softness', 'spot_offsetX', 'spot_offsetY', 'spot_offsetZ'
$intFields = 'colorR', 'colorG', 'colorB', 'alignPointLights', 'useSpotlightColor', 'spot_colorR', 'spot_colorG', 'spot_colorB'

# Per-light fields arrive as pN_/sN_ prefixed variants of the base names
$perLightFloatFields = 'brightness', 'radius', 'attenuation', 'shadowFadeDistance', 'shadowFadeRange', 'shadowBlendFactor', `
    'innerAngle', 'outerAngle', 'softness', 'offsetX', 'offsetY', 'offsetZ'
$perLightIntFields = 'colorR', 'colorG', 'colorB'

function CoerceEntry {
    param([hashtable] $raw)

    $out = @{}
    foreach ($kv in $raw.GetEnumerator()) {
        $k = $kv.Key
        $v = $kv.Value
        $isFloat = $k -in $floatFields
        $isInt = $k -in $intFields
        if ($k -match '^(?:p|s)\d+_(\w+)$') {
            $isFloat = $Matches[1] -in $perLightFloatFields
            $isInt = $Matches[1] -in $perLightIntFields
        }
        if ($isFloat) {
            $out[$k] = [double]::Parse($v, [System.Globalization.CultureInfo]::InvariantCulture)
        }
        elseif ($isInt) {
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

    $primary = [ordered]@{}
    $overflow = [ordered]@{}

    foreach ($raw in $Records) {
        $entry = CoerceEntry $raw
        $entityFile = $entry['entityFile']
        $layerPath = if ($entry.ContainsKey('layerPath')) { $entry['layerPath'] } else { '' }
        $key = "$entityFile|$layerPath"

        if (-not $primary.Contains($key)) {
            $primary[$key] = $entry
        }
        elseif (-not (EntriesIdentical $primary[$key] $entry)) {
            $alreadySeen = $false
            foreach ($existing in $overflow.Values) {
                $existingLayer = if ($existing.ContainsKey('layerPath')) { $existing['layerPath'] } else { '' }
                if ($existing['entityFile'] -eq $entityFile -and $existingLayer -eq $layerPath -and (EntriesIdentical $existing $entry)) {
                    $alreadySeen = $true
                    break
                }
            }
            if (!$alreadySeen) {
                $overflow["$key|$($overflow.Count)"] = $entry
            }
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
    $tagNames = @{}

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
    if ([math]::Abs($Value) -lt 1e-4) { return '0' }
    # 'G' removes trailing zeros; use InvariantCulture to guarantee dot as separator.
    return $Value.ToString('G', [System.Globalization.CultureInfo]::InvariantCulture)
}

# ---- XML generation ----

# Appends a <shadows> child when any prefixed shadow field is present
function AddShadowsChild {
    param(
        [System.Xml.XmlDocument] $Doc,
        [System.Xml.XmlElement]  $Parent,
        [hashtable]              $Params,
        [string]                 $Prefix
    )

    $hasShadows = $Params.ContainsKey("${Prefix}shadowFadeDistance") -or
    $Params.ContainsKey("${Prefix}shadowFadeRange") -or
    $Params.ContainsKey("${Prefix}shadowBlendFactor")
    if (-not $hasShadows) { return }

    $shadows = $Doc.CreateElement('shadows')
    if ($Params.ContainsKey("${Prefix}shadowFadeDistance")) { $shadows.SetAttribute('fade_distance', (FmtFloat $Params["${Prefix}shadowFadeDistance"])) }
    if ($Params.ContainsKey("${Prefix}shadowFadeRange")) { $shadows.SetAttribute('fade_range', (FmtFloat $Params["${Prefix}shadowFadeRange"])) }
    if ($Params.ContainsKey("${Prefix}shadowBlendFactor")) { $shadows.SetAttribute('blend_factor', (FmtFloat $Params["${Prefix}shadowBlendFactor"])) }
    $Parent.AppendChild($shadows) | Out-Null
}

# Appends a <colour> child when the prefixed colour fields are present
function AddColourChild {
    param(
        [System.Xml.XmlDocument] $Doc,
        [System.Xml.XmlElement]  $Parent,
        [hashtable]              $Params,
        [string]                 $Prefix
    )

    if (-not $Params.ContainsKey("${Prefix}colorR")) { return }

    $colour = $Doc.CreateElement('colour')
    $colour.SetAttribute('r', [string]$Params["${Prefix}colorR"])
    $colour.SetAttribute('g', [string]($Params.ContainsKey("${Prefix}colorG") ? $Params["${Prefix}colorG"] : 0))
    $colour.SetAttribute('b', [string]($Params.ContainsKey("${Prefix}colorB") ? $Params["${Prefix}colorB"] : 0))
    $Parent.AppendChild($colour) | Out-Null
}

# Appends an <offset> child when any prefixed offset field is present
function AddOffsetChild {
    param(
        [System.Xml.XmlDocument] $Doc,
        [System.Xml.XmlElement]  $Parent,
        [hashtable]              $Params,
        [string]                 $Prefix
    )

    if (-not ($Params.ContainsKey("${Prefix}offsetX") -or $Params.ContainsKey("${Prefix}offsetY") -or $Params.ContainsKey("${Prefix}offsetZ"))) { return }

    $off = $Doc.CreateElement('offset')
    $off.SetAttribute('x', (FmtFloat ($Params.ContainsKey("${Prefix}offsetX") ? $Params["${Prefix}offsetX"] : 0.0)))
    $off.SetAttribute('y', (FmtFloat ($Params.ContainsKey("${Prefix}offsetY") ? $Params["${Prefix}offsetY"] : 0.0)))
    $off.SetAttribute('z', (FmtFloat ($Params.ContainsKey("${Prefix}offsetZ") ? $Params["${Prefix}offsetZ"] : 0.0)))
    $Parent.AppendChild($off) | Out-Null
}

# Builds a <spotlight> element from prefixed params ('spot_' entity-wide, 'sN_' per-component).
# Scalars are attributes; shadows/colour/offset are child elements, matching spotlightOverrideType in the XSD.
function BuildSpotlightElement {
    param(
        [System.Xml.XmlDocument] $Doc,
        [hashtable]              $Params,
        [string]                 $Prefix
    )

    $spot = $Doc.CreateElement('spotlight')
    if ($Params.ContainsKey("${Prefix}brightness")) { $spot.SetAttribute('brightness', (FmtFloat $Params["${Prefix}brightness"])) }
    if ($Params.ContainsKey("${Prefix}radius")) { $spot.SetAttribute('radius', (FmtFloat $Params["${Prefix}radius"])) }
    if ($Params.ContainsKey("${Prefix}attenuation")) { $spot.SetAttribute('attenuation', (FmtFloat $Params["${Prefix}attenuation"])) }
    if ($Params.ContainsKey("${Prefix}innerAngle")) { $spot.SetAttribute('innerAngle', (FmtFloat $Params["${Prefix}innerAngle"])) }
    if ($Params.ContainsKey("${Prefix}outerAngle")) { $spot.SetAttribute('outerAngle', (FmtFloat $Params["${Prefix}outerAngle"])) }
    if ($Params.ContainsKey("${Prefix}softness")) { $spot.SetAttribute('softness', (FmtFloat $Params["${Prefix}softness"])) }

    AddShadowsChild $Doc $spot $Params $Prefix
    AddColourChild $Doc $spot $Params $Prefix
    AddOffsetChild $Doc $spot $Params $Prefix

    return $spot
}

# Builds a <light index="N"> element from pN_-prefixed params
function BuildLightElement {
    param(
        [System.Xml.XmlDocument] $Doc,
        [hashtable]              $Params,
        [int]                    $Index
    )

    $prefix = "p${Index}_"
    $light = $Doc.CreateElement('light')
    $light.SetAttribute('index', [string]$Index)
    if ($Params.ContainsKey("${prefix}brightness")) { $light.SetAttribute('brightness', (FmtFloat $Params["${prefix}brightness"])) }
    if ($Params.ContainsKey("${prefix}radius")) { $light.SetAttribute('radius', (FmtFloat $Params["${prefix}radius"])) }
    if ($Params.ContainsKey("${prefix}attenuation")) { $light.SetAttribute('attenuation', (FmtFloat $Params["${prefix}attenuation"])) }

    AddShadowsChild $Doc $light $Params $prefix
    AddColourChild $Doc $light $Params $prefix
    AddOffsetChild $Doc $light $Params $prefix

    return $light
}

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
        $override.SetAttribute('use_spotlight_colour', $val)
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

    AddShadowsChild $Doc $override $Params ''
    AddColourChild $Doc $override $Params ''

    # <fire_fx_offset> - only when alignPointLights is present
    if ($Params.ContainsKey('alignPointLights')) {
        $align = $Doc.CreateElement('fire_fx_offset')
        $align.SetAttribute('x', '0')
        $align.SetAttribute('y', '0')
        $align.SetAttribute('z', (FmtFloat ($Params.ContainsKey('alignOffsetZ') ? $Params['alignOffsetZ'] : 0.0)))
        $override.AppendChild($align) | Out-Null
    }

    # <offset> - only when pointLightOffset is present
    if ($Params.ContainsKey('pointLightOffset')) {
        $off = $Doc.CreateElement('offset')
        $off.SetAttribute('x', (FmtFloat ($Params.ContainsKey('pointLightOffsetX') ? $Params['pointLightOffsetX'] : 0.0)))
        $off.SetAttribute('y', (FmtFloat ($Params.ContainsKey('pointLightOffsetY') ? $Params['pointLightOffsetY'] : 0.0)))
        $off.SetAttribute('z', (FmtFloat ($Params.ContainsKey('pointLightOffsetZ') ? $Params['pointLightOffsetZ'] : 0.0)))
        $override.AppendChild($off) | Out-Null
    }

    # <spotlight> - only when at least one spot_ field is present
    $hasSpot = @($Params.Keys | Where-Object { $_ -like 'spot_*' }).Count -gt 0
    if ($hasSpot) {
        $override.AppendChild((BuildSpotlightElement $Doc $Params 'spot_')) | Out-Null
    }

    $pointIndices = @($Params.Keys | ForEach-Object { if ($_ -match '^p(\d+)_') { [int]$Matches[1] } }) | Sort-Object -Unique
    foreach ($idx in $pointIndices) {
        $override.AppendChild((BuildLightElement $Doc $Params $idx)) | Out-Null
    }

    $spotIndices = @($Params.Keys | ForEach-Object { if ($_ -match '^s(\d+)_') { [int]$Matches[1] } }) | Sort-Object -Unique
    foreach ($idx in $spotIndices) {
        $spotEl = BuildSpotlightElement $Doc $Params "s${idx}_"
        $spotEl.SetAttribute('index', [string]$idx)
        $override.AppendChild($spotEl) | Out-Null
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

    $schemaLocation = 'LightRewriteDefinitions.xsd'
    $parent = Split-Path $OutputFile -Parent
    if (
        !(Test-Path (Join-Path $parent 'LightRewriteDefinitions.xsd')) -and
        (Test-Path (Join-Path $parent '..' 'LightRewriteDefinitions.xsd'))
    ) {
        $schemaLocation = "../$schemaLocation"
    }

    $root = $doc.CreateElement('redxml')
    $root.SetAttribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance')
    $root.SetAttribute('noNamespaceSchemaLocation', 'http://www.w3.org/2001/XMLSchema-instance', $schemaLocation) | Out-Null
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
    }
    else {
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
