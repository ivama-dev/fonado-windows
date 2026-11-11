using Fonado.Windows.Telephony;

namespace Fonado.Windows.Desktop;

public sealed record QuickAccessState(SipSnapshot Phone, string Connection, string Company, string Extension,
    string Profile, string Scope, bool CanPhone, bool Busy, bool HasProfiles, bool CanProfiles)
{
    public bool CanDial(string number) => CanPhone && Phone.Registered && !Phone.InCall && !Busy && DialNumber.Normalize(number) is not null;
    public bool CanAnswer => CanPhone && Phone.InCall && Phone.Incoming && !Busy;
    public bool CanMute => CanPhone && Phone.InCall && Phone.Active && !Phone.Incoming && !Busy;
    public bool CanHold => CanPhone && Phone.InCall && !Phone.Incoming && (Phone.Active || Phone.Held) && !Busy
        && !Phone.RemoteHeld && !Phone.HoldPending && !Phone.Consulting && !Phone.TransferPending;
    public bool CanEnd => CanPhone && Phone.InCall && !Busy;
}

// Physical screen pixels, including monitors to the left/above the primary display.
public readonly record struct PopupBounds(int X, int Y, int Width, int Height);
public static class QuickAccessPlacement
{
    public static PopupBounds Place(PopupBounds work, PopupBounds anchor, int width, int height, int gap)
    {
        gap = Math.Max(0, Math.Min(gap, Math.Min(work.Width, work.Height) / 4));
        width = Math.Clamp(width, 1, Math.Max(1, work.Width - 2 * gap));
        height = Math.Clamp(height, 1, Math.Max(1, work.Height - 2 * gap));
        var above = anchor.Y - height - gap;
        var below = anchor.Y + anchor.Height + gap;
        var y = above >= work.Y + gap ? above : below;
        var x = anchor.X + anchor.Width - width;
        return new(Math.Clamp(x, work.X + gap, work.X + work.Width - width - gap),
            Math.Clamp(y, work.Y + gap, work.Y + work.Height - height - gap), width, height);
    }
}
