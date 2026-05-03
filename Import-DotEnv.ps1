$Path = ".env"
if (!(Test-Path $Path)) { return }

Get-Content $Path | ForEach-Object {
    $line = $_.Trim()

    if ($line -eq "" -or $line.StartsWith("#")) { return }
    if ($line -notmatch "^\s*([^=]+?)\s*=\s*(.*)\s*$") { return }

    $name = $matches[1].Trim()
    $value = $matches[2].Trim()

    # Strip quotes
    if (
        ($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))
    ) {
        $value = $value.Substring(1, $value.Length - 2)
    }

    Set-Item -Path "Env:$name" -Value $value
}
