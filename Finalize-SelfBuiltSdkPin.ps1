#Requires -Version 7.2
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ArchivePath, [Parameter(Mandatory)][string]$NoticesDirectory)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'NativeSdk.Common.ps1')
$pinPath = Join-Path $PSScriptRoot 'native-sdk.json'
$pin = Get-Content -LiteralPath $pinPath -Raw | ConvertFrom-Json
$info = Read-NativeArchive $ArchivePath $pin
$noticeRecord = New-NativeNoticeRecord $NoticesDirectory $info.manifest.buildId
$utf8 = [Text.UTF8Encoding]::new($false)
$cache = Get-NativeCacheRoot $pin
[IO.Directory]::CreateDirectory($cache) | Out-Null
$noticePinPath = Join-Path $cache 'native-notices.json'
$committedNoticePin = Join-Path $PSScriptRoot 'ThirdParty/Native/native-notices.json'
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($committedNoticePin)) | Out-Null
$noticeText = ($noticeRecord | ConvertTo-Json -Depth 8).Replace("`r`n","`n")+"`n"
[IO.File]::WriteAllText($committedNoticePin,$noticeText,$utf8)
[IO.File]::WriteAllText($noticePinPath,$noticeText,$utf8)
$pin | Add-Member -Force NoteProperty buildId $info.manifest.buildId
$pin | Add-Member -Force NoteProperty archiveSha256 $info.archiveSha256
$pin | Add-Member -Force NoteProperty archiveFileName ([IO.Path]::GetFileName($ArchivePath))
$pin | Add-Member -Force NoteProperty deliveryManifestSha256 $info.manifestSha256
$pin | Add-Member -Force NoteProperty noticeInventorySha256 (Get-NativeSha256 $committedNoticePin)
$pin | Add-Member -Force NoteProperty deliveryReady $true
[IO.File]::WriteAllText($pinPath,($pin | ConvertTo-Json -Depth 10).Replace("`r`n","`n")+"`n",$utf8)
& (Join-Path $PSScriptRoot 'Restore-NativeSdk.ps1') -ArchivePath $ArchivePath -NoticesDirectory $NoticesDirectory
Write-Output 'Self-built SDK bytes and notices pinned locally. Source-publication, ABI, installed-package, phone/audio and WACK acceptance are separate checks.'
