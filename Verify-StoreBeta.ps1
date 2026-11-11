[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$UploadPath,
    [string]$ReportPath = ''
)

$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'Restore-NativeSdk.ps1') -VerifyOnly
$sourceManifest = [xml](Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Fonado.Windows\Package.appxmanifest') -Raw)
$expectedIdentity = $sourceManifest.Package.Identity
$crtPin = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'store-frameworks.json') -Raw | ConvertFrom-Json
& (Join-Path $PSScriptRoot 'Restore-StoreDependencies.ps1') -VerifyOnly
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Read-PackageText([IO.Compression.ZipArchive]$Archive, [string]$Name) {
    $entry = $Archive.GetEntry($Name)
    if (-not $entry) { throw "Required package file is missing: $Name" }
    $reader = [IO.StreamReader]::new($entry.Open())
    try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
}

$absoluteUpload = [IO.Path]::GetFullPath($UploadPath)
$uploadArchive = [IO.Compression.ZipFile]::OpenRead($absoluteUpload)
$payloadStream = [IO.MemoryStream]::new()
$payloadArchive = $null
try {
    $packages = @($uploadArchive.Entries | Where-Object { $_.FullName.EndsWith('.msix', [StringComparison]::OrdinalIgnoreCase) })
    if ($packages.Count -ne 1) { throw 'Expected exactly one x64 MSIX inside the upload archive.' }
    $source = $packages[0].Open()
    try { $source.CopyTo($payloadStream) } finally { $source.Dispose() }
    $payloadStream.Position = 0
    $payloadArchive = [IO.Compression.ZipArchive]::new($payloadStream, [IO.Compression.ZipArchiveMode]::Read, $true)
    $names = @($payloadArchive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
    $blocked = @($names | Where-Object {
        $_ -match '(?i)(^|/)(qa|tests|diagnostics|\.git|\.vs)(/|$)|\.(pfx|p8|key|sqlite|db|protected|ps1|pdb)$|\.private\.json$|tester[^/]*\.(dll|exe)$'
    })
    if ($blocked.Count) { throw "Unexpected private, test or development files in MSIX: $($blocked -join ', ')" }
    foreach ($required in @(
        'Fonado.Windows.exe', 'Fonado.Windows.dll', 'resources.pri', 'coreclr.dll', 'hostfxr.dll', 'hostpolicy.dll',
        'CsWrapper.dll', 'liblinphone.dll', 'mediastreamer2.dll', 'belle-sip.dll',
        'mediastreamer/plugins/libmswasapi.dll', 'mediastreamer/plugins/libmswebrtc.dll',
        'share/belr/grammars/identity_grammar.belr', 'share/belr/grammars/sip_grammar.belr', 'share/belr/grammars/sdp_grammar.belr',
        'share/linphone/rootca.pem', 'Assets/Fonado.ico', 'Assets/Fonado.Tray.ico', 'Assets/StoreLogo.png', 'Assets/AudioTest.wav'
    )) {
        if ($names -notcontains $required) { throw "Required runtime or resource is missing: $required" }
    }
    $manifest = [xml](Read-PackageText $payloadArchive 'AppxManifest.xml')
    $sdkPin = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'native-sdk.json') -Raw | ConvertFrom-Json
    $packagedSdk = Read-PackageText $payloadArchive 'Licenses/Native-SDK.json' | ConvertFrom-Json
    $sdkFiles = Read-PackageText $payloadArchive 'Licenses/Native-SDK-Files.json' | ConvertFrom-Json
    $packagedCrtPin = Read-PackageText $payloadArchive 'Licenses/Store-Frameworks.json' | ConvertFrom-Json
    if ($packagedCrtPin.name -ne $crtPin.name -or $packagedCrtPin.minVersion -ne $crtPin.minVersion -or $packagedCrtPin.sha256 -ne $crtPin.sha256 -or
        $packagedCrtPin.publisher -ne $crtPin.publisher -or $sdkPin.sha256 -ne $crtPin.validatedNativeSdkSha256) { throw 'Packaged CRT framework provenance mismatch or native SDK requires a new CRT import audit.' }
    if ($packagedSdk.sha256 -ne $sdkPin.sha256 -or $packagedSdk.version -ne $sdkPin.version -or $sdkFiles.archiveSha256 -ne $sdkPin.sha256) { throw 'Packaged native SDK provenance mismatch.' }
    foreach ($sdkFile in $sdkFiles.files) {
        $payloadName = if ($sdkFile.path.StartsWith('bin/')) { $sdkFile.path.Substring(4) } elseif ($sdkFile.path.StartsWith('lib/mediastreamer/plugins/')) { $sdkFile.path.Substring(4) } elseif ($sdkFile.path.StartsWith('share/')) { $sdkFile.path } else { throw 'Unexpected SDK file mapping.' }
        $sdkEntry = $payloadArchive.GetEntry($payloadName)
        if (-not $sdkEntry) { throw "Missing SDK runtime/resource: $payloadName" }
        $hashAlgorithm = [Security.Cryptography.SHA256]::Create(); $sdkStream = $sdkEntry.Open()
        try { $actualHash = [BitConverter]::ToString($hashAlgorithm.ComputeHash($sdkStream)).Replace('-','') } finally { $sdkStream.Dispose(); $hashAlgorithm.Dispose() }
        if ($actualHash -ne $sdkFile.sha256) { throw "SDK runtime/resource checksum mismatch: $payloadName" }
    }
    if ($manifest.Package.Identity.Name -ne $expectedIdentity.Name -or
        $manifest.Package.Identity.Publisher -ne $expectedIdentity.Publisher -or
        $manifest.Package.Identity.Version -ne $expectedIdentity.Version -or
        $manifest.Package.Identity.ProcessorArchitecture -ne 'x64') { throw 'Store package identity does not match Fonado.' }
    if ($manifest.Package.Applications.Application.Executable -ne 'Fonado.Windows.exe' -or
        $manifest.Package.Applications.Application.EntryPoint -ne 'Windows.FullTrustApplication') { throw 'Expected the regular full-trust desktop entry point.' }
    $deviceFamily = $manifest.Package.Dependencies.TargetDeviceFamily
    if ($deviceFamily.Name -ne 'Windows.Desktop' -or $deviceFamily.MinVersion -ne '10.0.19041.0') { throw 'Unexpected Windows target.' }
    $crtDependency = @($manifest.Package.Dependencies.PackageDependency | Where-Object Name -eq $crtPin.name)
    if ($crtDependency.Count -ne 1 -or $crtDependency[0].Publisher -ne $crtPin.publisher -or $crtDependency[0].MinVersion -ne $crtPin.minVersion) { throw 'The package must declare its pinned Microsoft VC-Libs desktop framework dependency.' }
    $runtime = (Read-PackageText $payloadArchive 'Fonado.Windows.runtimeconfig.json' | ConvertFrom-Json).runtimeOptions
    if ($runtime.framework -or -not @($runtime.includedFrameworks | Where-Object name -eq 'Microsoft.NETCore.App').Count) { throw '.NET runtime is not self-contained.' }
    $microsoft = Read-PackageText $payloadArchive 'microsoft365.json' | ConvertFrom-Json
    if ($microsoft.ClientId -ne '9ade0cad-97cb-49e0-a22c-e6db148a225f' -or
        @($microsoft.PSObject.Properties.Name | Where-Object { $_ -match '(?i)secret|password|token|private' }).Count) { throw 'Unexpected Microsoft connection configuration.' }
    $report = [ordered]@{
        checkedAtUtc = [DateTime]::UtcNow.ToString('o')
        upload = $absoluteUpload
        uploadSha256 = (Get-FileHash -LiteralPath $absoluteUpload -Algorithm SHA256).Hash
        identity = $manifest.Package.Identity.Name
        publisher = $manifest.Package.Identity.Publisher
        version = $manifest.Package.Identity.Version
        architecture = 'x64'
        windowsMinimum = $deviceFamily.MinVersion
        dotnetRuntime = @($runtime.includedFrameworks | Where-Object name -eq 'Microsoft.NETCore.App')[0].version
        runtimeResourcesPresent = $true
        excludedPrivateAndTestFiles = $true
        status = 'local_package_checks_passed'
        scope = 'Archive, identity, bundled .NET, SIP/audio resources and configuration checks; not Store certification or installed-package acceptance.'
        linphoneDistributionLicense = 'awaiting_resolution'
        linphoneSdkVersion = $sdkPin.version
        linphoneSdkVariant = $sdkPin.variant
        nativeSdkFilesVerified = $sdkFiles.files.Count
        vcRuntimeFramework = $crtPin.name
        vcRuntimeMinimumVersion = $crtPin.minVersion
        vcRuntimePackageSha256 = $crtPin.sha256
        vcRuntimePackageSignature = 'Valid Microsoft Corporation'
        submitted = $false
    }
    if ($ReportPath) {
        $absoluteReport = [IO.Path]::GetFullPath($ReportPath)
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($absoluteReport)) | Out-Null
        $report | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $absoluteReport -Encoding utf8
    }
    Write-Output 'PASS: Store identity, x64 runtime, self-contained .NET, SIP/audio resources and package file exclusions.'
}
finally {
    if ($payloadArchive) { $payloadArchive.Dispose() }
    $payloadStream.Dispose()
    $uploadArchive.Dispose()
}
