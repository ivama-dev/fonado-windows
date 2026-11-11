using Microsoft.UI.Xaml.Automation.Peers;
using Microsoft.UI.Xaml.Controls;

namespace Fonado.Windows.Controls;

public sealed partial class BrandLogo : UserControl
{
    public BrandLogo() => InitializeComponent();

    protected override AutomationPeer OnCreateAutomationPeer() => new LogoAutomationPeer(this);

    private sealed class LogoAutomationPeer(BrandLogo owner) : FrameworkElementAutomationPeer(owner)
    {
        protected override string GetClassNameCore() => nameof(BrandLogo);
        protected override AutomationControlType GetAutomationControlTypeCore() => AutomationControlType.Image;
    }
}
