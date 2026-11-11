# Fonado Windows · 11.11.2026

The application, project, solution, assembly, executable, C# namespaces, XAML
resources, build scripts and current documentation use the Fonado name.
The app starts as Fonado.Windows.exe. The supplied logo is used without its
suffix; the remaining vector contours are unchanged. The unused former
wordmark was removed. Application, tray, taskbar and Store assets are built
from Assets/Fonado.png and Assets/Fonado.ico. The notification-area icon uses
Assets/Fonado.Tray.ico, with a 72% overall painted footprint, transparent padding and no status
badge covering the logo. Its master artwork is Assets/Brand/Fonado-Tray.svg. Status remains
available in the tooltip, menu, quick access and taskbar overlay.

The main wordmark is 96 × 36 px, left-aligned with the navigation icons
at the bottom of expanded navigation,
instead of a large header. It is hidden in compact navigation. The quick-access
wordmark is 88 × 33 px.

The supplied Manrope variable font remains bundled, with its SIL Open Font
License in MANROPE-OFL.txt and Licenses/Manrope-OFL.txt. Green #96B914,
yellow-green #C8D741, anthracite #373737, light gray #F2F2F2 and white
remain the design palette. Dark green #536A0B keeps small accent text legible.

Compatibility is explicit in Compatibility/ExistingInstallation.cs: existing
user data, the single-instance key, server capability and persisted contact
JSON field retain their established identities. Package.appxmanifest retains
the registered Store identity. The existing API endpoint and public authentication IDs
are preserved. Customer-portal links use app.fonado.ai and repository links use the
canonical Fonado names. Immutable historical source paths retain their original spelling.
This prevents sign-in loss, separate competing app instances, broken server
contracts and inaccessible encrypted contact caches. The legacy-cache test
fixture verifies the persisted format using synthetic data.

The 0.1.1.0 source milestone includes the branding and customer-portal link changes.
The earlier local WACK PASS applies to the 0.1.0.0 candidate and its recorded hash;
it is not a certification result for a rebuilt 0.1.1.0 package.

The release changes no user files, live accounts or server configuration.
Source snapshots omit .git and generated build folders. GitHub source publication
is separate from Microsoft Store certification.
