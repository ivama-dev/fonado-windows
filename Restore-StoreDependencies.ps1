[CmdletBinding()]
param([string]$VCLibsPath = '', [switch]$VerifyOnly)
$ErrorActionPreference = 'Stop'
$pin = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'store-frameworks.json') -Raw | ConvertFrom-Json
$cacheRoot = Join-Path $PSScriptRoot '.sdk\dependencies\x64'
$cachePath = Join-Path $cacheRoot $pin.fileName
if ($VerifyOnly) { $VCLibsPath = $cachePath }
elseif (-not $VCLibsPath) {
    $VCLibsPath = if (Test-Path -LiteralPath $cachePath) { $cachePath } else {
        Join-Path ${env:ProgramFiles(x86)} $pin.sourceRelativeToProgramFilesX86
    }
}
if (-not (Test-Path -LiteralPath $VCLibsPath -PathType Leaf)) {
    throw "The pinned Microsoft VC-Libs desktop framework is missing. Obtain it using the installed Visual Studio/Windows SDK described at $($pin.documentation), then run Restore-StoreDependencies.ps1 -VCLibsPath <retail-x64-appx>. No software or certificate is installed by this script."
}
$absolutePackage = [IO.Path]::GetFullPath($VCLibsPath)
if ((Get-FileHash -LiteralPath $absolutePackage -Algorithm SHA256).Hash -ne $pin.sha256) { throw 'Microsoft VC-Libs framework checksum mismatch.' }
$signature = Get-AuthenticodeSignature -LiteralPath $absolutePackage
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -ne $pin.publisher) { throw 'Microsoft VC-Libs framework signature did not verify as Microsoft Corporation.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($absolutePackage)
try {
    $entry = $archive.GetEntry('AppxManifest.xml')
    if (-not $entry) { throw 'Microsoft VC-Libs package manifest is missing.' }
    $reader = [IO.StreamReader]::new($entry.Open())
    try { $manifest = [xml]$reader.ReadToEnd() } finally { $reader.Dispose() }
    if ($manifest.Package.Identity.Name -ne $pin.name -or $manifest.Package.Identity.Publisher -ne $pin.publisher -or
        $manifest.Package.Identity.Version -ne $pin.minVersion -or $manifest.Package.Identity.ProcessorArchitecture -ne $pin.architecture -or
        $manifest.Package.Properties.Framework -ne 'true') { throw 'Unexpected Microsoft VC-Libs framework identity.' }
    foreach ($dll in $pin.requiredRuntimeDlls) { if (-not $archive.GetEntry($dll)) { throw "The VC-Libs framework is missing $dll." } }
} finally { $archive.Dispose() }
if (-not $VerifyOnly -and $absolutePackage -ne [IO.Path]::GetFullPath($cachePath)) {
    [IO.Directory]::CreateDirectory($cacheRoot) | Out-Null
    Copy-Item -LiteralPath $absolutePackage -Destination $cachePath
    if ((Get-FileHash -LiteralPath $cachePath -Algorithm SHA256).Hash -ne $pin.sha256) { throw 'Cached VC-Libs copy checksum mismatch.' }
}
Write-Output "PASS: Microsoft-signed $($pin.name) $($pin.minVersion), $($pin.architecture). Cached for local testing; not installed."
