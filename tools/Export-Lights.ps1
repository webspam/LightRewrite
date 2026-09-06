#Requires -Version 7.0

<#
.SYNOPSIS
    Converts LRDebug export log lines into a LightRewrite XML override file.

.DESCRIPTION
    After running the in-game export (press the LRDebug_ExportEdited key while the
    debug editor is active), locate the game log and run this script against it.
    It parses every LRDebug_Export channel line, groups entries by entity file and layer path,
    and writes a valid UTF-16 XML file compatible with the data/ override format.

    Automatically checks for auto-exported lines if there are no manually exported log lines.

.PARAMETER LogFile
    Path to the game log file containing [LRDebug_Export] lines.
    If omitted, the value of the WITCHER_SCRIPTSLOG_PATH environment variable is used.

.PARAMETER OutputFile
    Path to write the generated XML file. Default: exported_lights.xml

.PARAMETER Profile
    The profile_name attribute for the <overrides> block. Default: Exported

.PARAMETER Weight
    The weight attribute for the <overrides> block (0-255). Default: 75

.PARAMETER AutoExports
    Only export the automatic (on exit) lines.

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

    [switch] $AutoExports,

    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---- Log parsing ----

function ParseExportLines {
    param([string] $Path, [string] $Tag)

    $records = [System.Collections.Generic.List[hashtable]]::new()
    $doneCount = $null

    $sr = [System.IO.StreamReader]::new([System.IO.File]::Open($Path, 'Open', 'Read', 'ReadWrite'))
    try { $lines = $sr.ReadToEnd() -split "`r?`n" } finally { $sr.Dispose() }
    foreach ($line in $lines) {
        if (-not $line.StartsWith($Tag)) { continue }

        $fragment = $line.Substring($Tag.Length).Trim()
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

# Canonical base field names; pN_/sN_ prefixed variants are stripped before lookup
$floatFields = 'brightness', 'radius', 'attenuation', 'shadowFadeDistance', 'shadowFadeRange', 'shadowBlendFactor', `
    'innerAngle', 'outerAngle', 'softness', 'offsetX', 'offsetY', 'offsetZ', 'alignOffsetZ'
$intFields = 'colorR', 'colorG', 'colorB', 'alignPointLights', 'useSpotlightColor'

# Structural metadata only used for bookkeeping; skipped during entry comparison and attribute output.
$metaFields = 'entityFile', 'layerPath', 'pointLightCount', 'spotLightCount'

function CoerceEntry {
    param([hashtable] $raw)

    $out = @{}
    foreach ($kv in $raw.GetEnumerator()) {
        $k = $kv.Key
        $v = $kv.Value
        $base = $k
        if ($k -match '^(?:p\d+_|s\d+_)(\w+)$') { $base = $Matches[1] }
        $isFloat = $base -in $floatFields
        $isInt = $base -in $intFields
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
        if ($kv.Key -in $metaFields) { continue }
        if (-not $B.ContainsKey($kv.Key) -or $B[$kv.Key] -ne $kv.Value) { return $false }
    }
    foreach ($kv in $B.GetEnumerator()) {
        if ($kv.Key -in $metaFields) { continue }
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
    return $Value.ToString('0.######', [System.Globalization.CultureInfo]::InvariantCulture)
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
    $Params.ContainsKey("${Prefix}shadowBlendFactor") -or
    $Params.ContainsKey("${Prefix}castingMode")
    if (-not $hasShadows) { return }

    $shadows = $Doc.CreateElement('shadows')
    if ($Params.ContainsKey("${Prefix}castingMode")) { $shadows.SetAttribute('casting_mode', [string]$Params["${Prefix}castingMode"]) }
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

# Builds a <spotlight> element from per-component prefixed params ('sN_')
# Scalars are attributes; shadows/colour/offset are child elements, matching spotlightOverrideType in the XSD
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

# Distinct 0-based indices of prefixed component keys (e.g. 'p' -> 0,1 from p0_/p1_)
function ComponentIndices {
    param([hashtable] $Params, [string] $Letter)
    $indices = @($Params.Keys | ForEach-Object { if ($_ -match "^$Letter(\d+)_") { [int]$Matches[1] } } | Sort-Object -Unique)
    return , $indices
}

# For a lone point light (single component), rewrite its p0_ keys to entity-wide so it
# emits as plain <override> attributes instead of a redundant <light index="0"> child.
function CollapseSinglePointLight {
    param([hashtable] $Params)

    if ([int]$Params['pointLightCount'] -ne 1) { return }

    $indices = ComponentIndices $Params 'p'
    if ($indices.Count -ne 1 -or $indices[0] -ne 0) { return }

    foreach ($k in @($Params.Keys)) {
        if ($k -match '^p0_(\w+)$') {
            $Params[$Matches[1]] = $Params[$k]
            $Params.Remove($k)
        }
    }
}

# True when a lone spotlight makes index="N" redundant (single component, index 0)
function SpotlightIndexRedundant {
    param([hashtable] $Params, [int] $Index, [int] $Count)
    return $Index -eq 0 -and $Count -eq 1 -and [int]$Params['spotLightCount'] -eq 1
}

# <match type="layer" mode="exact"> for a layer path
function BuildLayerMatch {
    param(
        [System.Xml.XmlDocument] $Doc,
        [string]                 $Layer
    )

    $match = $Doc.CreateElement('match')
    $match.SetAttribute('type', 'layer')
    $match.SetAttribute('mode', 'exact')
    $match.InnerText = $Layer
    return $match
}

function BuildOverrideElement {
    param(
        [System.Xml.XmlDocument] $Doc,
        [hashtable]              $Params,
        [string]                 $TagName,
        [string]                 $LayerPath = ''
    )

    CollapseSinglePointLight $Params

    $entityFile = $Params['entityFile']

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

    # Inline layer match for a lone override
    if ($LayerPath -ne '') {
        $override.AppendChild((BuildLayerMatch $Doc $LayerPath)) | Out-Null
    }

    AddShadowsChild $Doc $override $Params ''
    AddColourChild $Doc $override $Params ''
    AddOffsetChild $Doc $override $Params ''

    # <fire_fx_offset> - only when alignPointLights is present
    if ($Params.ContainsKey('alignPointLights')) {
        $align = $Doc.CreateElement('fire_fx_offset')
        $align.SetAttribute('x', '0')
        $align.SetAttribute('y', '0')
        $align.SetAttribute('z', (FmtFloat ($Params.ContainsKey('alignOffsetZ') ? $Params['alignOffsetZ'] : 0.0)))
        $override.AppendChild($align) | Out-Null
    }

    foreach ($idx in (ComponentIndices $Params 'p')) {
        $override.AppendChild((BuildLightElement $Doc $Params $idx)) | Out-Null
    }

    $spotIndices = ComponentIndices $Params 's'
    foreach ($idx in $spotIndices) {
        $spotEl = BuildSpotlightElement $Doc $Params "s${idx}_"
        if (!(SpotlightIndexRedundant $Params $idx $spotIndices.Count)) {
            $spotEl.SetAttribute('index', [string]$idx)
        }
        $override.AppendChild($spotEl) | Out-Null
    }

    return $override
}

# Emits one <overrides> block per distinct layer path
function AppendGroupedOverrides {
    param(
        [System.Xml.XmlDocument] $Doc,
        [System.Xml.XmlElement]  $Parent,
        [System.Collections.Specialized.OrderedDictionary] $Entries,
        [hashtable]              $TagNames,
        [string]                 $ProfileName,
        [int]                    $WeightValue
    )

    $byLayer = [ordered]@{}
    foreach ($key in $Entries.Keys) {
        $entry = $Entries[$key]
        $layer = if ($entry.ContainsKey('layerPath')) { $entry['layerPath'] } else { '' }
        if (-not $byLayer.Contains($layer)) {
            $byLayer[$layer] = [System.Collections.Generic.List[string]]::new()
        }
        $byLayer[$layer].Add($key)
    }

    foreach ($layer in $byLayer.Keys) {
        $keys = $byLayer[$layer]
        $soleOverride = $keys.Count -eq 1

        $overridesEl = $Doc.CreateElement('overrides')
        $overridesEl.SetAttribute('profile_name', $ProfileName)
        $overridesEl.SetAttribute('weight', [string]$WeightValue)
        $Parent.AppendChild($overridesEl) | Out-Null

        # Shared <matches> with the exact layer filter, ANDed into every override in the block
        if ($layer -ne '' -and -not $soleOverride) {
            $matchesEl = $Doc.CreateElement('matches')
            $matchesEl.AppendChild((BuildLayerMatch $Doc $layer)) | Out-Null
            $overridesEl.AppendChild($matchesEl) | Out-Null
        }

        foreach ($key in $keys) {
            $inlineLayer = if ($soleOverride) { $layer } else { '' }
            $el = BuildOverrideElement $Doc $Entries[$key] $TagNames[$key] $inlineLayer
            $overridesEl.AppendChild($el) | Out-Null
        }
    }
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
        $lr.AppendChild($doc.CreateComment(" WARNING: $($Overflow.Count) conflicting duplicate(s) were found. All duplicates are in ${ProfileName}_Duplicates overrides block(s) below. ")) | Out-Null
    }

    AppendGroupedOverrides $doc $lr $Groups $TagNames $ProfileName $WeightValue

    if ($Overflow.Count -gt 0) {
        $lr.AppendChild($doc.CreateComment(" Duplicates: these entries share an entity file and layer path with an entry above, but had conflicting field values. Review and merge manually. ")) | Out-Null

        AppendGroupedOverrides $doc $lr $Overflow $TagNames "${ProfileName}_Duplicates" $WeightValue
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

$manualTag = '[LRDebug_Export]'
$autoTag = '[LRDebug_AutoExport]'

if ($AutoExports) {
    $activeTag = $autoTag
    $records, $doneCount = ParseExportLines $LogFile $autoTag
}
else {
    $activeTag = $manualTag
    $records, $doneCount = ParseExportLines $LogFile $manualTag
    if ($records.Count -eq 0) {
        Write-Host "No $manualTag entity lines found; falling back to $autoTag (quit-to-menu backup)."
        $activeTag = $autoTag
        $records, $doneCount = ParseExportLines $LogFile $autoTag
    }
}

if ($records.Count -eq 0) {
    Write-Host "No $activeTag entity lines found in the log."
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
