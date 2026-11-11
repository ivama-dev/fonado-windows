namespace Fonado.Windows.Desktop;

// Shell hosts can report a mouse activation as WM_LBUTTONUP, NIN_SELECT, or both.
// Consume a paired notification once so a second callback cannot close the popup.
public sealed class TrayClickFilter
{
    private long ignoreUntil;

    public bool TryActivate(uint message, long now)
    {
        if (message is not (0x202 or 0x400 or 0x401) || now < ignoreUntil) return false;
        ignoreUntil = now + 250;
        return true;
    }

    public void DoubleClick(long now, uint doubleClickTime) => ignoreUntil = now + doubleClickTime;
}
