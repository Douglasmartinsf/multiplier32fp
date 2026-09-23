param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$files = Get-Content -LiteralPath (Join-Path $root 'config/public-files.txt')
$build = Join-Path $root 'build'
New-Item -ItemType Directory -Force -Path $build | Out-Null
$output = Join-Path $build ('multiplier32fp-source-' + [guid]::NewGuid().ToString('N') + '.zip')
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::Open($output, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $files) {
        if ([string]::IsNullOrWhiteSpace($file)) { continue }
        $source = [IO.Path]::GetFullPath((Join-Path $root $file))
        if (!$source.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Manifest entry must remain inside the project.'
        }
        if (!(Test-Path -LiteralPath $source -PathType Leaf)) { throw "Missing public file: $file" }
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $source, $file.Replace('\','/')) | Out-Null
    }
} finally { $archive.Dispose() }
Write-Output $output
