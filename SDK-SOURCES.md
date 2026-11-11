# Native SDK sources and provenance

This candidate uses the official **Linphone SDK 5.5.39, Windows Desktop Win32 x64** archive. The client is a packaged WinUI 3/.NET full-trust desktop application, rather than a UWP/AppContainer application.

- Download and SHA-256: [native-sdk.json](native-sdk.json).
- Upstream source tag: [5.5.39](https://github.com/BelledonneCommunications/linphone-sdk/tree/5.5.39).
- Source commit: `4d00285c92511acbeba7b2c7c9c621599192584f`.
- Security changes: [official changelog](https://github.com/BelledonneCommunications/linphone-sdk/blob/5.5.39/CHANGELOG.md).
- Vendor clarification: [issue 610](https://github.com/BelledonneCommunications/linphone-sdk/issues/610).

Run `./Restore-NativeSdk.ps1` before building directly in Visual Studio, or use `./Start-Dev.ps1 -Restore -BuildOnly`. To reuse an already downloaded official archive, pass `-ArchivePath`. The script verifies the pinned archive hash, extracts only the runtime files/resources used by this client, and records their individual SHA-256 checksums. Builds copy that inventory into `Licenses/Native-SDK-Files.json`; the Store verifier checks every recorded native file/resource against its packaged bytes.

SDK files remain in the ignored `.sdk` cache. No native binaries, signing keys or credentials belong in source control. The earlier v0.1.1 application source milestone used LinphoneSDK.Windows 5.5.24; its historical NuGet metadata discrepancy remains documented in that release.

## Distribution evidence still incomplete

The SDK superproject and 28 of 31 exact top-level dependency snapshots have been secured locally. Exact vendor revisions remain unavailable for:

- Mbed-TLS: `857ff3a350861584a9aaaf8a6ada7a8714c20135`.
- RNNoise: `d107462bff3bcda43d8115487959d1e66da905dc`.
- Xerces-C: `cb8467f9e4ed31e3af9474f439af98182bf64728`.

Additional build inputs, original component notices, binary/component mapping and the complete corresponding-source delivery still require verification. An upstream version number or nearby source revision does not prove the vendor fork's exact content. This candidate is for local acceptance testing; it is not cleared for public binary distribution.

The separate desktop archive compiles the application and resolves all 2,936 imports of its C# wrapper. Those checks do not prove installed MSIX compatibility, phone service connectivity or audio behavior. Signed installation, upgrade, phone/audio acceptance and Windows App Certification Kit checks remain necessary.

The application remains AGPL-3.0-or-later; upstream components keep their own licenses. Preserve original copyright, license and notice files when completing the native delivery.