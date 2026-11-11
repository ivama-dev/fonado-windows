# Fonado Windows 0.1.1

This source release brings the Windows client to the Fonado brand. Project and solution names, executable, C# namespaces, UI text, build scripts and documentation now use Fonado. The supplied artwork uses the wordmark without the AI suffix and bundles the Manrope font with its OFL license.

The main wordmark is smaller and left-aligned at the bottom of navigation. The tray and quick-access views use the revised artwork and restrained logo sizing. The notification-area identity is stable for each executable/package.

Customer-portal links now open `https://app.fonado.ai/kunden/`. Existing package identity, account data, service capabilities and encrypted contact caches remain compatible with earlier installations. Microsoft dependency license/notice texts are included with hashes and source references.

## Scope and validation

This is a source-code milestone for package version **0.1.1.0**. No MSIX, executable, native SDK DLL or private account data is attached to this GitHub release. The earlier WACK overall PASS covers the separately hashed 0.1.0.0 Store candidate; it is not a WACK or Store certification result for this source revision.

Validation on 11 November 2026: source/private-file checks passed, all eight existing unit suites passed with the Windows-user DPAPI checks explicitly skipped in the restricted test context, and the Release/x64 MSIX build and local package checks passed. All 28 collected Microsoft license/notice files retain their recorded hashes; the package also includes their inventory. No live-account sign-in, call or signed-installation acceptance is claimed by these checks.

Native Linphone corresponding sources/notices and a supported security-fixed Windows Store SDK package remain pending, as documented in [SDK-SOURCES.md](SDK-SOURCES.md). Live review-account call tests, signed-package acceptance and Microsoft Store certification are still required for binary distribution.
