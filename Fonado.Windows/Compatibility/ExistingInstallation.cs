namespace Fonado.Windows;

// Persisted and server-side identifiers are retained across the product rename.
internal static class ExistingInstallation
{
    public const string SingleInstanceKey = "Fonoo.Windows.Main";
    public const string CloudCapability = "fonoo.cloud.v1";
    public const string ContactAccountProperty = "FonooAccountId";
    public static readonly Uri ServiceEndpoint = new("https://push.dev.fonoo.app/v1/");
    public static string DataDirectory => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Fonoo", "Windows");
}
