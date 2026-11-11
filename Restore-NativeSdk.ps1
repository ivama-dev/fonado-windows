[CmdletBinding()]
param([string]$ArchivePath = '', [switch]$VerifyOnly)
$ErrorActionPreference = 'Stop'
$pin = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'native-sdk.json') -Raw | ConvertFrom-Json
$sdkRoot = Join-Path $PSScriptRoot ('.sdk\linphone-' + $pin.version)
$inventoryPath = Join-Path $sdkRoot 'sdk-files.json'
if (-not $VerifyOnly -and -not $ArchivePath -and (Test-Path -LiteralPath $inventoryPath)) {
    & $PSCommandPath -VerifyOnly
    return
}
if ($VerifyOnly) {
    if (-not (Test-Path -LiteralPath $inventoryPath)) { throw 'Native SDK is missing. Run Restore-NativeSdk.ps1 first.' }
    $inventory = Get-Content -LiteralPath $inventoryPath -Raw | ConvertFrom-Json
    if ($inventory.archiveSha256 -ne $pin.sha256) { throw 'Native SDK pin mismatch.' }
    $expectedPaths = @($inventory.files | ForEach-Object { $_.path })
    foreach ($required in @('bin/CsWrapper.dll','bin/liblinphone.dll','bin/mediastreamer2.dll','lib/mediastreamer/plugins/libmswasapi.dll','lib/mediastreamer/plugins/libmswebrtc.dll','share/belr/grammars/sip_grammar.belr','share/linphone/rootca.pem')) {
        if ($required -notin $expectedPaths) { throw "SDK inventory omits required content: $required" }
    }
    $actualPaths = @(
        Get-ChildItem -LiteralPath (Join-Path $sdkRoot 'bin') -File -Filter '*.dll'
        Get-Item -LiteralPath (Join-Path $sdkRoot 'lib/mediastreamer/plugins/libmswasapi.dll'),(Join-Path $sdkRoot 'lib/mediastreamer/plugins/libmswebrtc.dll'),(Join-Path $sdkRoot 'share/linphone/rootca.pem')
        Get-ChildItem -LiteralPath (Join-Path $sdkRoot 'share/belr'),(Join-Path $sdkRoot 'share/sounds') -Recurse -File
    ) | ForEach-Object { [IO.Path]::GetRelativePath($sdkRoot,$_.FullName).Replace('\','/') }
    if (@(Compare-Object $expectedPaths @($actualPaths)).Count) { throw 'Native SDK cache contains missing or unlisted runtime/resource files. Restore it from the pinned official archive before building.' }
    foreach ($file in $inventory.files) {
        $path = [IO.Path]::GetFullPath((Join-Path $sdkRoot $file.path))
        if (-not $path.StartsWith($sdkRoot + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid SDK inventory path.' }
        if (-not (Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $file.sha256) { throw "Native SDK file mismatch: $($file.path)" }
    }
    Write-Output "PASS: pinned native SDK $($pin.version), $($inventory.files.Count) original runtime/resource files."
    return
}
if (-not $ArchivePath) {
    $ArchivePath = Join-Path $PSScriptRoot ('.sdk\downloads\linphone-sdk-win64-' + $pin.version + '.zip')
    if (-not (Test-Path -LiteralPath $ArchivePath)) {
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($ArchivePath)) | Out-Null
        Invoke-WebRequest -Uri $pin.url -OutFile $ArchivePath
    }
}
if ((Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash -ne $pin.sha256) { throw 'Official SDK archive checksum mismatch; nothing extracted.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
$files = @()
try {
    foreach ($entry in $zip.Entries) {
        if (-not $entry.FullName.StartsWith('linphone-sdk/win64/')) { continue }
        $relative = $entry.FullName.Substring('linphone-sdk/win64/'.Length)
        if ($relative -notmatch '^bin/[^/]+\.dll$|^lib/mediastreamer/plugins/(libmswasapi|libmswebrtc)\.dll$|^share/(belr/grammars/[^/]+|linphone/rootca\.pem|sounds/.+)$') { continue }
        if ($entry.FullName.EndsWith('/') -or $relative -match '(?i)tester[^/]*\.dll$') { continue }
        if ($relative.Contains(':') -or (($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000) { throw 'Unsupported SDK archive entry.' }
        $target = [IO.Path]::GetFullPath((Join-Path $sdkRoot $relative))
        if (-not $target.StartsWith($sdkRoot + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'SDK archive path escaped destination.' }
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
        $inputStream = $entry.Open(); $outputStream = [IO.File]::Create($target)
        try { $inputStream.CopyTo($outputStream) } finally { $outputStream.Dispose(); $inputStream.Dispose() }
        $files += [ordered]@{path=$relative;bytes=$entry.Length;sha256=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash}
    }
} finally { $zip.Dispose() }
foreach ($required in @('bin/CsWrapper.dll','bin/liblinphone.dll','bin/mediastreamer2.dll','lib/mediastreamer/plugins/libmswasapi.dll','lib/mediastreamer/plugins/libmswebrtc.dll','share/belr/grammars/sip_grammar.belr','share/linphone/rootca.pem')) {
    if ($required -notin @($files | ForEach-Object { $_.path })) { throw "Official SDK is missing required content: $required" }
}
[ordered]@{version=$pin.version;variant=$pin.variant;archiveSha256=$pin.sha256;files=$files} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $inventoryPath -Encoding UTF8
& $PSCommandPath -VerifyOnly
