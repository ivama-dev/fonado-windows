# Third-party software and licenses

This is a summary of the dependencies currently identified in the Windows application. For details, read [NOTICE.md](NOTICE.md), [SDK-SOURCES.md](SDK-SOURCES.md), and the pinned dependency lock files. Each component retains its own copyright and license terms.

- **Liblinphone SDK 5.5.39, Windows Desktop x64** — Belledonne Communications and contributors. The upstream release's license text is GNU AGPLv3; The official archive, source commit and original runtime/resource checksums are recorded separately; the upstream dependency tree and binary redistribution obligations require review. See [SDK-SOURCES.md](SDK-SOURCES.md).
- **Windows App SDK / WinUI** — Microsoft and contributors. License notices must be collected from the exact packages shipped.
- **MSAL.NET and MSAL extensions** — Microsoft and contributors; upstream MIT licensing applies to the relevant packages.
- **.NET runtime and dependencies** — Microsoft, .NET Foundation, and contributors. Relevant runtime licenses and notices apply if these components are bundled.
- **Windows SDK and build tools** — Microsoft. Build tooling is not relicensed as part of the Fonado application.

Before a Store/MSIX or other binary release, generate a **complete, version-accurate bill of materials and third-party notice bundle** and provide the corresponding source/build information required by the licenses. This summary alone is not a complete release notice bundle.

The Fonado application's own source license is `AGPL-3.0-or-later`; see [LICENSE](LICENSE). This license does not replace any third-party licenses.

## Collected Microsoft notices

Unmodified license and notice texts for the pinned Microsoft dependencies are included in [ThirdParty/Microsoft](ThirdParty/Microsoft). Its `inventory.json` records package versions, upstream sources and SHA-256 checksums. Builds copy this directory to `Licenses/Microsoft`.

This collection covers the identified Microsoft packages and runtime notices. The full native Linphone/dependency source and notice delivery remains pending; see [SDK-SOURCES.md](SDK-SOURCES.md).


## Manrope

The bundled Manrope font from the supplied Fonado brand package is licensed
under the SIL Open Font License 1.1. See MANROPE-OFL.txt in source and
Licenses/Manrope-OFL.txt in published builds for copyright and full terms.
