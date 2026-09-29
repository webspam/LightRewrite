[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
    [string[]] $Colours,

    [Parameter(Mandatory)]
    [string] $OutputDirectory,

    [ValidateRange(1, 4096)]
    [int] $Size = 64
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    Add-Type -AssemblyName System.Drawing

    $hexPattern = '^#?(?<hex>[0-9a-fA-F]{6}|[0-9a-fA-F]{3})$'
    $tokens = [System.Collections.Generic.List[string]]::new()

    function ParseColour {
        param([string] $Token)

        if ($Token -notmatch $hexPattern) {
            throw "Invalid hex colour: '$Token'"
        }

        $hex = $Matches['hex'].ToLowerInvariant()
        if ($hex.Length -eq 3) {
            $hex = -join ($hex.ToCharArray() | ForEach-Object { "$_$_" })
        }

        return $hex
    }

    function WriteSwatch {
        param([string] $Hex, [string] $Path)

        $colour = [System.Drawing.Color]::FromArgb(
            255,
            [Convert]::ToInt32($Hex.Substring(0, 2), 16),
            [Convert]::ToInt32($Hex.Substring(2, 2), 16),
            [Convert]::ToInt32($Hex.Substring(4, 2), 16))

        $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try { $graphics.Clear($colour) } finally { $graphics.Dispose() }
            $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $bitmap.Dispose()
        }
    }
}

process {
    foreach ($entry in $Colours) {
        foreach ($token in ($entry -split '[\s,]+')) {
            if ($token -ne '') { $tokens.Add($token) }
        }
    }
}

end {
    $hexes = @($tokens | ForEach-Object { ParseColour $_ } | Select-Object -Unique)

    if ($hexes.Count -eq 0) {
        throw 'No colours supplied.'
    }

    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $directory = (Resolve-Path $OutputDirectory).Path

    foreach ($hex in $hexes) {
        $path = Join-Path $directory "$hex.png"
        WriteSwatch $hex $path
        Write-Verbose "Written: $path"
    }
}
