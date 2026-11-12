# Microsoft Store packaging

The official Fonado package identity is declared in `Fonado.Windows/Package.appxmanifest`. Forks must use their own Store identity and signing configuration. The application is x64-only in this revision.

The registered package name remains `Fonoo.fonoo`; the user-facing name is Fonado. Do not rename the technical package identity when changing branding or contact email addresses. Confirm the manifest's identity and publisher against Partner Center's Product identity page before submission. The local verifier compares the built package with the source manifest; it does not check the Partner Center account.

```powershell
./Build-StoreBeta.ps1 -Restore
./Verify-StoreBeta.ps1 -UploadPath "C:\path\Fonado.Windows_0.1.2.0_x64.msixupload" -ReportPath "C:\path\package-check.json"
```

The build creates an unsigned Release/x64 Store upload candidate, with the .NET runtime bundled and Windows App SDK plus Microsoft VCLibs Desktop as framework dependencies. Restore Fonado's pinned source-built SDK runtime and original notices before packaging; see [SDK-SOURCES.md](SDK-SOURCES.md). Build outputs, signing keys and SDK DLLs must not be committed. The verifier checks identity, runtime resources, provenance and exclusion of development/private files; it does not replace installation or certification.

When available, the build uses x64 MakeAppx from the installed Windows SDK 10.0.26100.0. Pass `-MakeAppxPath` to select another installed SDK tool. This avoids the access-denied startup failure observed with the NuGet-provided packaging tool on the release workstation.

Before distributing a binary:

1. Publish the exact application commit and corresponding liblinphone/native dependency sources, licenses and build instructions for that binary, as described in [SDK-SOURCES.md](SDK-SOURCES.md).
2. Verify signed installation/update, remembered login, runtime loading, incoming/outgoing audio and background/tray behavior for the actual new binary hashes. Exercise changed native audio and call controls; distinguish automated media tests from physical microphone/headset acceptance.
3. Run the Windows App Certification Kit and complete Store metadata, privacy information, age rating and accurate synthetic screenshots.
4. Upload the reviewed package and complete Microsoft certification. For private testing, select a private known-user audience; a hidden public listing is not a private beta.

This source publication does not upload an MSIX or submit certification. Microsoft references: [visibility](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/visibility-options), [known-user groups](https://learn.microsoft.com/en-us/windows/apps/publish/create-customer-groups) and [package upload](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/upload-app-packages).

Windows rejects different contents under an already installed full package identity. Local acceptance may use a separate temporary test version: record the exact manifest difference and compare every application/runtime file with the Store candidate. Do not call that an installation of the exact Store manifest version. [Microsoft's package identity rule](https://devblogs.microsoft.com/insidemsix/third-rule-of-msix/).
