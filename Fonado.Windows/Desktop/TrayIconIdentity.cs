using System.Security.Cryptography;
using System.Text;

namespace Fonado.Windows.Desktop;

// Windows binds a notification GUID to the executable that first registered it.
// Unsigned desktop builds therefore need an identity scoped to their location.
public static class TrayIconIdentity
{
    public static Guid ForExecutablePath(string executablePath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(executablePath);
        return Create("exe:" + Path.GetFullPath(executablePath).ToUpperInvariant());
    }

    public static Guid ForPackageFamily(string familyName)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(familyName);
        return Create("package:" + familyName.ToUpperInvariant());
    }

    private static Guid Create(string identity) => new(SHA256.HashData(
        Encoding.UTF8.GetBytes("Fonado.Tray.v1\n" + identity)).AsSpan(0, 16));
}
