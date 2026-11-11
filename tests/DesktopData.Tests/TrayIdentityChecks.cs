using Fonado.Windows.Desktop;

internal static class TrayIdentityChecks
{
    public static void Run()
    {
        var root = Path.Combine(Path.GetTempPath(), "fonado-tray-identity");
        var executable = Path.Combine(root, "install", "Fonado.Windows.exe");
        var id = TrayIconIdentity.ForExecutablePath(executable);
        Check(id != Guid.Empty && id == TrayIconIdentity.ForExecutablePath(executable), "Stable identity across restarts");
        Check(id == TrayIconIdentity.ForExecutablePath(executable.ToUpperInvariant()), "Windows path case must not change tray identity");
        Check(id == TrayIconIdentity.ForExecutablePath(Path.Combine(root, "unused", "..", "install", "Fonado.Windows.exe")), "Equivalent paths must retain identity");
        Check(id != TrayIconIdentity.ForExecutablePath(Path.Combine(root, "moved", "Fonado.Windows.exe")), "Moved unsigned builds need a new tray GUID");
        Check(id != TrayIconIdentity.ForExecutablePath(Path.Combine(root, "install", "Different.Windows.exe")), "Different executables must not share the tray GUID");
        var package = TrayIconIdentity.ForPackageFamily("Example.Fonado_12345");
        Check(package == TrayIconIdentity.ForPackageFamily("example.fonado_12345"), "Packaged updates retain family identity");
        Check(package != id, "Packaged and desktop identities are isolated");
        Console.WriteLine("PASS: stable, case-insensitive tray identities; moved and side-by-side builds do not reuse a path-bound GUID.");
    }
    private static void Check(bool value, string message) { if (!value) throw new Exception(message); }
}
