# Native SDK sources and provenance

This candidate uses a **Fonado source build of Linphone SDK 5.5.39, Windows x64**, based on commit `4d00285c92511acbeba7b2c7c9c621599192584f`. The client is a packaged WinUI 3/.NET full-trust desktop application.

- Download and SHA-256: [native-sdk.json](native-sdk.json).
- Upstream source tag: [5.5.39](https://github.com/BelledonneCommunications/linphone-sdk/tree/5.5.39).
- Source commit: `4d00285c92511acbeba7b2c7c9c621599192584f`.
- Security changes: [official changelog](https://github.com/BelledonneCommunications/linphone-sdk/blob/5.5.39/CHANGELOG.md).
- Earlier vendor-binary inquiry: [issue 610](https://github.com/BelledonneCommunications/linphone-sdk/issues/610).

The native runtime, matching generated C# wrapper, resources and notices are delivered separately. `Restore-NativeSdk.ps1` verifies the pinned archives and closed file inventories before building. It never falls back to the earlier vendor DLLs. Builds copy the runtime inventory into `Licenses/Native-SDK-Files.json` and original component notices into `Licenses/Native`; the Store verifier checks their actual packaged bytes.

Download both companion assets from the [matching Fonado release](https://github.com/ivama-dev/fonado-windows/releases/tag/v0.1.2):

- `Fonado-Independent-SDK-5.5.39-win64-20261112-audio-v1.zip`: the source-built runtime/resources, SHA-256 `ECB24FB353E8D88AFE3D88A439E9AE479DE1F7EDE57C2675FCC608FF91C10CD0`.
- `Fonado-Independent-SDK-5.5.39-source-20261112.zip`: corresponding sources, build instructions and original notices, SHA-256 `1D1D2A38242490E8B13F34040A2FAC464A97DBE39E66CCB45A0897E608EE310A`.

Keep these assets together when redistributing the native build. Extract the source ZIP, then use PowerShell 7.2 or later (choose your own paths):

```powershell
./Restore-NativeSdk.ps1 -ArchivePath 'C:\downloads\Fonado-Independent-SDK-5.5.39-win64-20261112-audio-v1.zip' -NoticesDirectory 'C:\sources\Fonado-Independent-SDK-5.5.39-source\Notices'
./Restore-NativeSdk.ps1 -VerifyOnly
```

The normal restore checks committed pins; it does not establish new ones. `Finalize-SelfBuiltSdkPin.ps1` is a release-authoring helper for a deliberately changed SDK, not a required restore step for consumers.

SDK files remain in the ignored `.sdk` cache. No native binaries, signing keys or credentials belong in source control. The earlier v0.1.1 application source milestone used LinphoneSDK.Windows 5.5.24; its historical NuGet metadata discrepancy remains documented in that release.

## Source delivery and modifications

The corresponding-source delivery contains the original archives used by the selected build, hashes/revisions, Fonado's adapters/patches, feature configuration, generators and rebuild instructions. Its entry point accepts explicit source, build and tool roots. Compiler/SDK prerequisites are explicit; no workstation-specific directory or global PATH/Python change is required.

The audio profile keeps SRTP, MbedTLS, WASAPI, WebRTC echo cancellation/VAD, RNNoise, Opus and vCard support. It excludes video, which Fonado already disables, and unused native AdvancedIM/full-conference services requiring Xerces. Fonado's team, availability, provisioning and contact integrations remain in application code.

The native `GetVersion` fallback reports `5.5.0`, the version in the archived upstream CMake project. The actual selected source tag/commit is recorded above; the fallback string is not used as proof of the source revision.

- MbedTLS uses the complete official **3.6.7** release with documented DTLS-SRTP/threading configuration.
- RNNoise uses the complete official **v0.2** release and its unchanged embedded default C model. Original release copyright/license material is supplied. Applying the root BSD license to the included C model is a release-scope interpretation; no separate model-specific confirmation is asserted. The optional training checkpoint is not redistributed or needed for this build. Equivalence to the earlier vendor model is not claimed.
- Fonado's build changes check explicit local tools instead of requiring an MSYS auto-installer, disable Git-hook copying, and replace a small AWK filter-table generator with documented Python code. Original scripts remain present; fixtures verify the replacement. No Windows security setting is changed.

## Earlier vendor candidate

The earlier local candidate used the official vendor ZIP with SHA-256 `77DCB9007A9B304B568D9CF57AB69C9DAB7C45F577D08366A747AFCBEF214E29`. Exact vendor revisions remained unavailable for:

- Mbed-TLS: `857ff3a350861584a9aaaf8a6ada7a8714c20135`.
- RNNoise: `d107462bff3bcda43d8115487959d1e66da905dc`.
- Xerces-C: `cb8467f9e4ed31e3af9474f439af98182bf64728`.

The source-built delivery uses the identified replacements and excludes Xerces. It does not retrospectively establish the missing sources of the old vendor binaries. A manufacturer response is not a prerequisite for a different build with its own corresponding sources, build instructions and notices.

## Validation scope

Compilation, source availability, runtime loading and functional acceptance are separate checks. Earlier vendor-based installation, call and WACK results do not automatically apply to new SDK hashes. See the matching release evidence for actual results. Local validation does not constitute Microsoft Store certification.

The application remains AGPL-3.0-or-later; upstream components keep their own licenses. Preserve original copyright, license and notice files when completing the native delivery.
