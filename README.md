# Fonado for Windows

Native Windows softphone built with C#, WinUI 3 and **liblinphone SDK 5.5.39**. The client uses liblinphone exclusively; its provisioning request declares `sip_engine: "liblinphone"`. All call controls use actual SDK callbacks.

## Features

- Fonado email-code/password sign-in, optional DPAPI-protected remembered login and company/extension provisioning.
- Dialpad, incoming/outgoing SRTP audio, mute, hold/resume and direct/consultative transfer.
- Account/company-scoped favorites with personal groups, drag reordering and keyboard-accessible move actions; synchronized call history with All/Missed filters and shared single-call/list deletion.
- Windows/vCard contacts, read-only personal Outlook/Microsoft 365 mailbox contacts and an internal team directory.
- Shared PBX telephone presence in team/internal favorites, scoped counterpart names and a 15-second Unknown fallback.
- Shared incoming-call device profiles: quick switch, dynamic Standard, create/edit/delete and per-user/company synchronization.
- Audio device selection, measured microphone levels, local hearing/speaker tests and a compact call window.
- Configurable minimize-to-tray, native status badges/quick actions, taskbar overlays, hide-on-close, network/resume registration refresh and one app instance.

This repository contains the Windows application, tests, assets and build scripts. The Fonado backend and Apple/Android clients are separate projects. Using Fonado services requires an active Fonado account, an assigned extension and company permissions. Publishing the client does not grant access to those services.

## Build

Use Windows 10 19041 or later, Visual Studio 2026 with WinUI application development, .NET SDK 10.0.401 and the Windows SDK 26100. The native SDK integration supports **x64**. ARM64 is explicitly rejected until a matching runtime is integrated.

Open `Fonado.Windows.slnx` and select x64, or run:

```powershell
./Start-Dev.ps1 -Restore -BuildOnly
./Start-Dev.ps1
```

Managed dependencies are pinned in `Fonado.Windows/packages.lock.json`. The official Windows Desktop native SDK archive, variant and SHA-256 are pinned separately in `native-sdk.json`; `Restore-NativeSdk.ps1` checks the archive and extracts the required original runtime/resources into the ignored `.sdk` folder. Run it before building directly in Visual Studio. `Start-Dev.ps1 -Restore` also restores these files. SDK binaries are not committed. Choose **Fonado beenden** before rebuilding; closing the main window keeps the app in the notification area.

For a synthetic UI preview, build Debug with `-p:FonadoDesignPreview=true`. The preview is visibly labeled, uses isolated test storage and creates no real account, SIP registration or call. Release builds cannot enable it.

## Tests

```powershell
./Test.ps1
./Verify-Source.ps1
```

The tests use synthetic identities, responses and audio. Desktop/Microsoft contact storage checks need a normal Windows user context for DPAPI; `./Test.ps1 -SkipDpapi` explicitly skips those checks in a restricted command sandbox. [Native SDK diagnostics](diagnostics/LinphoneProbe/README.md) additionally cover local SRTP call/transfer scenarios.

See [background mode and shell status](DESKTOP-BACKGROUND.md), [favorite groups and local storage](FAVORITE-GROUPS.md), [device profiles](DEVICE-PROFILES.md), [audio](AUDIO-INTEGRATION.md), [desktop behavior](DESKTOP-UI-2026-10-05.md), [Outlook contacts](MICROSOFT-CONTACTS.md), [telephone presence](TEAM-PRESENCE.md) and [call history](CALL-HISTORY.md). Hardware hotplug, sleep/network recovery, high DPI/accessibility, resource budgets and signed MSIX acceptance remain release checks.

## License and releases

Fonado Windows is licensed under **AGPL-3.0-or-later**; see [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md). The upstream SDK tag uses AGPLv3; each component retains its own actual terms. [SDK source and dependency information](SDK-SOURCES.md) records the pinned release and this discrepancy.

The current publication is source code. Microsoft Store distribution additionally requires the corresponding SDK/dependency sources and build information for the shipped binaries, third-party notices, a signed-package acceptance test and Store certification. Source publication itself is not Store approval. [Store build instructions](STORE-BETA.md) describe the packaging process.

See [release notes for the Fonado 0.1.1 source milestone](RELEASE-NOTES.md) for the branding changes, validation and remaining binary-release checks.

The Microsoft client ID and Store/package identities in the source are public application identifiers. No client secret, SIP password, bearer/refresh token, customer contact/history file, SSH key or signing key belongs in this repository.

## Fonado branding and compatibility

The brand, executable, solution, C# namespaces, assets and current documentation use **Fonado**. The canonical repository is [ivama-dev/fonado-windows](https://github.com/ivama-dev/fonado-windows), and customer-portal links use `https://app.fonado.ai/kunden/`. [Branding details](FONADO-BRANDING.md) document the smaller, left-aligned main wordmark and the notification-area artwork.

Existing Store identity, service protocol identifiers and encrypted-cache keys remain compatible with existing installations. They are isolated in `Compatibility/ExistingInstallation.cs` and the package manifest. Historical source permalinks keep their original paths. The source release does not deploy the backend or change existing accounts.
