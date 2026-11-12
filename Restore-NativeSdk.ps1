#Requires -Version 7.2
[CmdletBinding()]
param([string]$ArchivePath = '', [string]$NoticesDirectory = '', [switch]$VerifyOnly)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'NativeSdk.Common.ps1')
$pin = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'native-sdk.json') -Raw | ConvertFrom-Json
Assert-NativePinReady $pin
$sdkRoot = Get-NativeCacheRoot $pin
$inventoryPath = Join-Path $sdkRoot 'sdk-files.json'
$noticeInventoryPath = Join-Path $sdkRoot 'native-notices.json'
if (-not $VerifyOnly -and -not $ArchivePath -and -not $NoticesDirectory -and (Test-Path -LiteralPath $inventoryPath)) {
    & $PSCommandPath -VerifyOnly
    return
}
if ($VerifyOnly) {
    if (-not (Test-Path -LiteralPath $inventoryPath) -or (Get-NativeSha256 $inventoryPath) -ine $pin.deliveryManifestSha256 -or
        -not (Test-Path -LiteralPath $noticeInventoryPath) -or (Get-NativeSha256 $noticeInventoryPath) -ine $pin.noticeInventorySha256) {
        throw 'Pinned self-built SDK/notice inventory missing or changed. Restore the pinned own delivery.'
    }
    $inventory = Get-Content -LiteralPath $inventoryPath -Raw | ConvertFrom-Json
    $noticeInventory = Get-Content -LiteralPath $noticeInventoryPath -Raw | ConvertFrom-Json
    if ($inventory.sourceKind -ne 'selfbuilt-modified' -or $inventory.buildId -ne $pin.buildId -or
        $noticeInventory.buildId -ne $pin.buildId -or $inventory.sourceCommit -ne $pin.sourceCommit) { throw 'Self-built cache provenance mismatch.' }
    $expected = @($inventory.files | ForEach-Object path)
    $actual = @(foreach ($folder in @('bin','lib','share')) {
        $dir = Join-Path $sdkRoot $folder
        if (Test-Path -LiteralPath $dir) { Get-ChildItem -LiteralPath $dir -Recurse -File | ForEach-Object { [IO.Path]::GetRelativePath($sdkRoot,$_.FullName).Replace('\','/') } }
    })
    if (@(Compare-Object $expected $actual).Count -or $actual.Count -ne $expected.Count) { throw 'Self-built cache has missing or unlisted runtime/resource files.' }
    foreach ($f in $inventory.files) {
        Assert-NativeRelativePath $f.path
        $path = Join-Path $sdkRoot $f.path
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-NativeSha256 $path) -ine $f.sha256) { throw "Self-built SDK file mismatch: $($f.path)" }
    }
    $noticeRoot = Join-Path $sdkRoot 'notices'
    $actualNotices = @(Get-ChildItem -LiteralPath $noticeRoot -Recurse -File | ForEach-Object { [IO.Path]::GetRelativePath($noticeRoot,$_.FullName).Replace('\','/') })
    if (@(Compare-Object @($noticeInventory.files | ForEach-Object path) $actualNotices).Count -or $actualNotices.Count -ne @($noticeInventory.files).Count) { throw 'Native notices have missing or unlisted files.' }
    foreach ($f in $noticeInventory.files) {
        Assert-NativeRelativePath $f.path
        if ((Get-NativeSha256 (Join-Path $noticeRoot $f.path)) -ine $f.sha256) { throw "Native notice checksum mismatch: $($f.path)" }
    }
    Write-Output "PASS: self-built SDK $($pin.buildId), $($inventory.files.Count) runtime/resource files and $($noticeInventory.files.Count) native notices."
    return
}
if (-not $ArchivePath) { $ArchivePath = Join-Path $PSScriptRoot ('.sdk/downloads/' + $pin.archiveFileName) }
if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) { throw 'Provide -ArchivePath for the pinned self-built SDK ZIP. No vendor SDK download or fallback is allowed.' }
if ((Get-NativeSha256 $ArchivePath) -ine $pin.archiveSha256) { throw 'Self-built SDK archive checksum mismatch; nothing extracted.' }
$info = Read-NativeArchive $ArchivePath $pin
if ($info.manifestSha256 -ine $pin.deliveryManifestSha256 -or $info.manifest.buildId -ne $pin.buildId) { throw 'Self-built SDK manifest mismatch.' }
if (-not $NoticesDirectory) { throw 'Provide -NoticesDirectory for the separately pinned source-specific native notices.' }
if (-not (Test-Path -LiteralPath $noticeInventoryPath)) {
    $committedNoticePin = Join-Path $PSScriptRoot 'ThirdParty/Native/native-notices.json'
    if (Test-Path -LiteralPath $committedNoticePin -PathType Leaf) {
        if ((Get-NativeSha256 $committedNoticePin) -ine $pin.noticeInventorySha256) { throw 'Committed native notice inventory does not match the SDK pin.' }
        $inventoryBytes = [IO.File]::ReadAllBytes($committedNoticePin)
    } else {
        # A source-only clone can reconstruct the same inventory; this NEVER updates its pin.
        $record = New-NativeNoticeRecord $NoticesDirectory $pin.buildId
        $text = ($record | ConvertTo-Json -Depth 8).Replace("`r`n","`n") + "`n"
        $inventoryBytes = [Text.UTF8Encoding]::new($false).GetBytes($text)
        if ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($inventoryBytes)) -ine $pin.noticeInventorySha256) { throw 'Reconstructed native notice inventory does not match the committed SDK pin.' }
    }
    [IO.Directory]::CreateDirectory($sdkRoot) | Out-Null
    [IO.File]::WriteAllBytes($noticeInventoryPath,$inventoryBytes)
}
if ((Get-NativeSha256 $noticeInventoryPath) -ine $pin.noticeInventorySha256) { throw 'Native notice inventory checksum mismatch.' }
$notices = Get-Content -LiteralPath $noticeInventoryPath -Raw | ConvertFrom-Json
foreach ($f in $notices.files) {
    $source = Join-Path ([IO.Path]::GetFullPath($NoticesDirectory)) $f.path
    if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or (Get-NativeSha256 $source) -ine $f.sha256) { throw "Native notice source mismatch: $($f.path)" }
}
$zip = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($ArchivePath))
try {
    foreach ($relative in @('sdk-files.json') + @($info.manifest.files | ForEach-Object path)) {
        $target = Join-Path $sdkRoot $relative
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
        $inputStream = $zip.GetEntry('win64/' + $relative).Open(); $outputStream = [IO.File]::Create($target)
        try { $inputStream.CopyTo($outputStream) } finally { $inputStream.Dispose(); $outputStream.Dispose() }
    }
} finally { $zip.Dispose() }
foreach ($f in $notices.files) {
    $target = Join-Path $sdkRoot ('notices/' + $f.path)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
    [IO.File]::Copy((Join-Path ([IO.Path]::GetFullPath($NoticesDirectory)) $f.path),$target,$true)
}
& $PSCommandPath -VerifyOnly
