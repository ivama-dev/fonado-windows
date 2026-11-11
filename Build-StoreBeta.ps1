[CmdletBinding()]
param(
    [switch]$Restore,
    [string]$OutputDirectory = '',
    [string]$MakeAppxPath = ''
)

$ErrorActionPreference = 'Stop'
$project = Join-Path $PSScriptRoot 'Fonado.Windows\Fonado.Windows.csproj'
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $PSScriptRoot 'Fonado.Windows\AppPackages\StoreBeta' }
$buildDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$binaryDirectory = Join-Path $buildDirectory 'bin'
$packageDirectory = Join-Path $buildDirectory 'packages'
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $vswhere)) { throw 'Visual Studio Installer was not found.' }
$msbuild = & $vswhere -latest -products '*' -requires Microsoft.Component.MSBuild -find 'MSBuild\Current\Bin\amd64\MSBuild.exe' | Select-Object -First 1
if (-not $msbuild) { throw 'Visual Studio x64 MSBuild was not found.' }
if (-not $MakeAppxPath) {
    $installedMakeAppx = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin\10.0.26100.0\x64\makeappx.exe'
    if (Test-Path -LiteralPath $installedMakeAppx) { $MakeAppxPath = $installedMakeAppx }
}
if ($MakeAppxPath -and -not (Test-Path -LiteralPath $MakeAppxPath -PathType Leaf)) { throw "MakeAppx was not found: $MakeAppxPath" }

$arguments = @(
    $project,
    '/p:Configuration=Release', '/p:Platform=x64', '/p:RuntimeIdentifier=win-x64',
    '/p:WindowsPackageType=MSIX', '/p:FonadoDesignPreview=false', '/p:SelfContained=true',
    '/p:WindowsAppSDKSelfContained=false', '/p:GenerateAppxPackageOnBuild=true',
    '/p:UapAppxPackageBuildMode=StoreUpload', '/p:AppxBundle=Never',
    '/p:AppxPackageSigningEnabled=false', '/p:RestoreLockedMode=true',
    '/p:DebugType=portable',
    "/p:OutputPath=$binaryDirectory\", "/p:AppxPackageDir=$packageDirectory\",
    '/v:minimal', '/nologo'
)
if ($Restore) { $arguments += '/restore' }
if ($MakeAppxPath) { $arguments += "/p:MakeAppxExeFullPath=$([IO.Path]::GetFullPath($MakeAppxPath))" }
& $msbuild @arguments
if ($LASTEXITCODE -ne 0) { throw "Store package build failed with exit code $LASTEXITCODE." }

$manifest = [xml](Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Fonado.Windows\Package.appxmanifest') -Raw)
$version = $manifest.Package.Identity.Version
$upload = Join-Path $packageDirectory "Fonado.Windows_${version}_x64.msixupload"
if (-not (Test-Path -LiteralPath $upload)) { throw 'The expected Store upload package was not created.' }
& (Join-Path $PSScriptRoot 'Verify-StoreBeta.ps1') -UploadPath $upload -ReportPath (Join-Path $buildDirectory 'package-check.json')
Write-Output "Store candidate prepared: $upload"
Write-Output 'Not uploaded or submitted. Complete corresponding-source delivery and packaged-user acceptance before distribution.'
