#Requires -Version 7.2
$ErrorActionPreference = 'Stop'
function Get-NativeSha256([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Get-NativeStreamSha256([IO.Stream]$Stream) {
    $hash = [Security.Cryptography.SHA256]::Create()
    try { [Convert]::ToHexString($hash.ComputeHash($Stream)) } finally { $hash.Dispose() }
}
function Assert-NativeRelativePath([string]$Path) {
    if (-not $Path -or $Path.Contains('\') -or $Path.Contains(':') -or $Path.StartsWith('/') -or
        $Path -match '(^|/)\.\.?(/|$)') { throw "Unsafe SDK relative path: $Path" }
}
function Get-NativeCacheRoot($Pin) {
    $allowed = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '.sdk')) + [IO.Path]::DirectorySeparatorChar
    $candidate = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot $Pin.cacheDirectory))
    if (-not $candidate.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Native SDK cache must stay inside this worktree .sdk directory.' }
    $candidate
}
function New-NativeNoticeRecord([string]$NoticesDirectory, [string]$BuildId) {
    $root = [IO.Path]::GetFullPath($NoticesDirectory)
    foreach ($required in @('NOTICE.txt','Notice-Map.json')) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $required) -PathType Leaf)) { throw "Missing native notice delivery: $required" }
    }
    [string[]]$relativePaths = @(Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object { [IO.Path]::GetRelativePath($root,$_.FullName).Replace('\','/') })
    [Array]::Sort($relativePaths,[StringComparer]::Ordinal)
    $files = @($relativePaths | ForEach-Object {
        Assert-NativeRelativePath $_
        if ($_ -match '(?i)(^|/)(\.git|qa|secrets)(/|$)|\.(pfx|p8|key|sqlite|db|protected|dll|exe)$') { throw "Unexpected native notice file: $_" }
        $path = Join-Path $root $_
        [ordered]@{ path=$_; bytes=(Get-Item -LiteralPath $path).Length; sha256=(Get-NativeSha256 $path) }
    })
    [ordered]@{ sourceKind='selfbuilt-native-notices'; buildId=$BuildId; files=$files }
}
function Read-NativeArchive([string]$ArchivePath, $Pin) {
    $zip = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($ArchivePath))
    try {
        $entry = $zip.GetEntry('win64/sdk-files.json')
        if (-not $entry) { throw 'Self-built archive must contain win64/sdk-files.json.' }
        $stream = $entry.Open()
        try { $manifestHash = Get-NativeStreamSha256 $stream } finally { $stream.Dispose() }
        $reader = [IO.StreamReader]::new($entry.Open())
        try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
        if ($manifest.sourceKind -ne 'selfbuilt-modified' -or $manifest.version -ne $Pin.version -or
            $manifest.sourceCommit -ne $Pin.sourceCommit -or -not $manifest.buildId) { throw 'Expected identified, modified/self-built SDK source provenance.' }
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($f in $manifest.files) {
            Assert-NativeRelativePath $f.path
            if (-not $seen.Add($f.path) -or $f.sha256 -notmatch '^[A-Fa-f0-9]{64}$' -or
                $f.path -notmatch '^bin/[^/]+\.dll$|^lib/mediastreamer/plugins/(libmswasapi|libmswebrtc)\.dll$|^share/(belr/grammars/[^/]+|linphone/rootca\.pem|sounds/.+)$' -or
                $f.path -match '(?i)tester[^/]*\.dll$|^bin/(mbedtls|mbedcrypto|mbedx509|xerces-c)\.dll$') { throw "Unexpected self-built SDK manifest entry: $($f.path)" }
            $payload = $zip.GetEntry('win64/' + $f.path)
            if (-not $payload -or $payload.Length -ne $f.bytes -or (($payload.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000) { throw "Missing or unsupported SDK archive entry: $($f.path)" }
            $stream = $payload.Open()
            try { $actual = Get-NativeStreamSha256 $stream } finally { $stream.Dispose() }
            if ($actual -ine $f.sha256) { throw "SDK archive checksum mismatch: $($f.path)" }
        }
        foreach ($required in @('bin/CsWrapper.dll','bin/liblinphone.dll','bin/mediastreamer2.dll',
            'lib/mediastreamer/plugins/libmswasapi.dll','lib/mediastreamer/plugins/libmswebrtc.dll',
            'share/belr/grammars/sip_grammar.belr','share/belr/grammars/sdp_grammar.belr',
            'share/belr/grammars/identity_grammar.belr','share/belr/grammars/vcard_grammar.belr','share/linphone/rootca.pem')) {
            if (-not $seen.Contains($required)) { throw "Self-built SDK omits required content: $required" }
        }
        foreach ($native in $Pin.nativeArtifacts) {
            $matches = @($manifest.files | Where-Object path -eq $native.path)
            if ($matches.Count -ne 1 -or $matches[0].sha256 -ine $native.sha256 -or $matches[0].bytes -ne $native.bytes) { throw "SDK does not match pinned own native build: $($native.path)" }
        }
        if (@($manifest.files | Where-Object path -match '\.dll$').Count -ne (@($Pin.nativeArtifacts).Count + 1)) { throw 'Expected pinned native DLL set plus exactly the new CsWrapper assembly.' }
        $expected = @('win64/sdk-files.json') + @($manifest.files | ForEach-Object { 'win64/' + $_.path })
        $actual = @($zip.Entries | Where-Object { -not $_.FullName.EndsWith('/') } | ForEach-Object FullName)
        if (@(Compare-Object $expected $actual).Count -or $actual.Count -ne $expected.Count) { throw 'Self-built archive has missing, duplicate or unlisted payload files.' }
        [pscustomobject]@{ manifest=$manifest; manifestSha256=$manifestHash; archiveSha256=(Get-NativeSha256 $ArchivePath) }
    } finally { $zip.Dispose() }
}
function Assert-NativePinReady($Pin) {
    if ($Pin.sourceKind -ne 'selfbuilt-modified' -or $Pin.deliveryReady -ne $true -or
        $Pin.archiveSha256 -notmatch '^[A-Fa-f0-9]{64}$' -or $Pin.deliveryManifestSha256 -notmatch '^[A-Fa-f0-9]{64}$' -or
        $Pin.noticeInventorySha256 -notmatch '^[A-Fa-f0-9]{64}$') {
        throw 'Self-built SDK delivery is not finalized. Pin the actual validated archive and notices with Finalize-SelfBuiltSdkPin.ps1; no vendor fallback is allowed.'
    }
}
