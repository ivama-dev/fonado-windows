# Pinned SDK and source availability

The client uses the official `LinphoneSDK.Windows` NuGet package **5.5.24**, with hashes pinned in `Fonado.Windows/packages.lock.json`.

- Package: https://gitlab.linphone.org/api/v4/projects/411/packages/nuget/download/LinphoneSDK.Windows/5.5.24/linphonesdk.windows.5.5.24.nupkg
- Package SHA-256: `e3a8af43c82af5be5a75dbd47d6f82c8c64c54e862a8f0677b3896f746bdadf0`
- Upstream repository: https://gitlab.linphone.org/BC/public/linphone-sdk
- Tag: `5.5.24`
- Tag commit verified on 2026-10-09: `9fb1c84e291090bcb88e688f8314721791bb885f`
- Exact-tag license: https://gitlab.linphone.org/BC/public/linphone-sdk/-/blob/5.5.24/LICENSE.txt

The exact-tag `LICENSE.txt` is **GNU Affero GPL version 3**. The downloaded package's `.nuspec` reports `GPL-3.0-or-later`. The Windows application is therefore published under **AGPL-3.0-or-later**, rather than relying on the more permissive package label. Preserve every upstream component's actual license and notices.

The upstream build begins with the exact SDK tag and its recursively pinned submodules:

```sh
git clone --branch 5.5.24 --recurse-submodules https://gitlab.linphone.org/BC/public/linphone-sdk.git
cd linphone-sdk
git rev-parse HEAD
git submodule status --recursive
```

Use that release's own Windows build instructions, toolchain options and component licenses. This application currently consumes the official package instead of rebuilding native SDK libraries. No claim of byte-for-byte reproduction of the vendor package is made.

Before distributing a Store/MSIX binary, make the corresponding source for its application, native SDK and covered dependencies available with the required notices, build/install information and exact revisions. A link to an upstream repository by itself is not the complete corresponding-source delivery for a binary release. Archive the covered sources and document the actual binary-to-source/build provenance for that release. Do not include service credentials or signing private keys.

## Source-release status, 11 November 2026

The canonical application repository is [ivama-dev/fonado-windows](https://github.com/ivama-dev/fonado-windows). The exact SDK superproject revision is also available from the [official GitHub mirror](https://github.com/BelledonneCommunications/linphone-sdk/tree/9fb1c84e291090bcb88e688f8314721791bb885f). The 31 pinned external submodule revisions, ANGLE sources and complete native notices have not yet been collected. GitLab was unreachable from the release environments; the upstream project acknowledges a related access limitation in [issue 590](https://github.com/BelledonneCommunications/linphone-sdk/issues/590#issuecomment-5307635432).

The [official 5.5.39 changelog](https://github.com/BelledonneCommunications/linphone-sdk/blob/5.5.39/CHANGELOG.md) reports RTCP/RTP security and bounds-validation fixes after the pinned 5.5.24 package. The Windows client in this source release still pins 5.5.24. A supported Windows Store package containing these fixes and its corresponding sources/notices must be obtained and assessed before public binary distribution. Desktop SDK ZIPs must not be substituted for Windows Store native libraries without validating their variant and compatibility.

This milestone publishes application source only. It does not claim that the SDK source/notice delivery, native security update, signed installation tests or Microsoft Store certification are complete.
