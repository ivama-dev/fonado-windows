# Fonado Windows 0.1.2

This revision retains the Fonado branding, artwork without the AI suffix and Manrope font with its OFL license. Project names, executable, C# namespaces, UI text and documentation use Fonado.

The main wordmark is smaller and left-aligned at the bottom of navigation. The tray and quick-access views use the revised artwork and restrained logo sizing. The notification-area identity is stable for each executable/package.

Customer-portal links now open `https://app.fonado.ai/kunden/`. Existing package identity, account data, service capabilities and encrypted contact caches remain compatible with earlier installations. Microsoft dependency license/notice texts are included with hashes and source references.

Availability now loads for accounts without previously saved availability settings. Windows accepts the server's explicit initial revision 0, while still rejecting missing/negative revisions and mismatched company/user identities. This fixes the repeated “Die Verfügbarkeit konnte nicht sicher geladen werden” error for that initial state.

## Scope and validation

The native SDK is now a Fonado source build based on **Linphone SDK 5.5.39**, with a matching generated C# wrapper, MbedTLS 3.6.7 and RNNoise v0.2. It retains the required Windows audio/SRTP/Opus features and excludes unused video and Xerces-dependent native services. Source archives, build instructions/adapters and original component notices accompany the SDK delivery; see [SDK-SOURCES.md](SDK-SOURCES.md).

The independent native SDK and matching managed wrapper compile successfully. Component checks cover MbedTLS configuration, RNNoise processing and SRTP packet protection/rejection. All 24 native DLLs load and all 2,936 wrapper imports resolve in the standalone preflight. The matching release evidence records application packaging, installed runtime, audio/call acceptance and WACK results with their actual hashes and limitations.

The earlier vendor-based 0.1.2 candidate passed signed upgrade, two-way calls, mute, hold/resume and incoming background-call checks. Its WACK run completed with warnings. Those historical results and the separate 0.1.0 WACK PASS do not establish acceptance of the new source-built binaries. Microsoft Store certification is separate from local validation.
