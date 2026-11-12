# Copyright and third-party software

Copyright (C) 2026 Fonado contributors.

The original Windows client code and accompanying project material in this repository are provided under GNU Affero General Public License version 3 or (at your option) any later version, without warranty. See `LICENSE`. Fonado names and marks do not grant an endorsement or a right to present modified software as an official Fonado release.

Dependencies retain their own copyrights and licenses; the application's license does not relicense third-party software:

- **Fonado source build of Linphone SDK 5.5.39**, Belledonne Communications and upstream contributors, with documented Fonado build adapters and MbedTLS 3.6.7/RNNoise v0.2 source replacements. The upstream SDK tag includes AGPLv3; component licenses and notices remain applicable. See `SDK-SOURCES.md`, `native-sdk.json` and the accompanying native source/notice delivery.
- **Microsoft Windows App SDK / WinUI**, Microsoft and contributors; Microsoft-published package/source license terms apply.
- **MSAL.NET and MSAL extensions**, Microsoft and contributors, MIT-licensed upstream projects.
- **.NET runtime/SDK**, .NET Foundation, Microsoft and contributors; original runtime and third-party notices apply when bundled.
- **Windows SDK build tooling**, Microsoft; development-tool terms apply. Its presence in NuGet restore does not place the tool under this application's license.

Native SDK binaries are restored from the separately pinned Fonado source-built archive and are not committed to this repository. Its original component notices are included under `Licenses/Native` in the application package. The `.NET` dependency lock file identifies the resolved managed packages. Matching binary releases must provide the native corresponding-source bundle and build instructions alongside the application source. This short notice does not replace those original texts.
