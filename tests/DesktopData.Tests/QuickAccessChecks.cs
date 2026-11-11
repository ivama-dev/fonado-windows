using Fonado.Windows.Desktop;
using Fonado.Windows.Telephony;

static class QuickAccessChecks
{
    public static void Run()
    {
        static void Check(bool result, string label) { if (!result) throw new Exception(label); }
        foreach (var first in new uint[] { 0x202, 0x400 })
        {
            var clicks = new TrayClickFilter();
            var paired = first == 0x202 ? 0x400u : 0x202u;
            Check(clicks.TryActivate(first, 1000), "Mouse-only tray callback did not open quick access");
            Check(!clicks.TryActivate(paired, 1010), "Paired shell callback toggled quick access twice");
            Check(clicks.TryActivate(first, 1600), "Next deliberate tray click was lost");
            clicks.DoubleClick(1700, 500);
            Check(!clicks.TryActivate(0x202, 1710) && !clicks.TryActivate(0x400, 1720), "Double-click release reopened quick access over the main window");
            Check(clicks.TryActivate(0x401, 2300), "Keyboard tray activation was lost");
            Check(!clicks.TryActivate(0x200, 3000) && !clicks.TryActivate(0x7b, 3000), "Hover or context menu opened quick access");
        }
        var phone = new SipSnapshot(true, false, false, false, "Verbunden", "");
        var idle = new QuickAccessState(phone, "Verbunden", "Testfirma", "101", "Standard", "test", true, false, true, true);
        Check(idle.CanDial("+43 (1) 234") && !idle.CanDial("sip:101@other.example") && !idle.CanDial(" "), "Quick dial validation");
        Check(!(idle with { CanPhone = false }).CanDial("101") && !(idle with { Busy = true }).CanDial("101") &&
            !(idle with { Phone = phone with { Registered = false } }).CanDial("101"), "Quick dial readiness guard");
        var incoming = idle with { Phone = phone with { InCall = true, Incoming = true } };
        Check(incoming.CanAnswer && incoming.CanEnd && !incoming.CanMute && !incoming.CanHold && !incoming.CanDial("101"), "Incoming quick actions");
        var active = idle with { Phone = phone with { InCall = true, Active = true } };
        Check(active.CanMute && active.CanHold && active.CanEnd && !active.CanAnswer, "Active quick actions");
        Check((active with { Phone = active.Phone with { Held = true, Active = false } }).CanHold, "Held call cannot resume");
        foreach (var blocked in new[] { active.Phone with { RemoteHeld = true }, active.Phone with { HoldPending = true },
            active.Phone with { Consulting = true }, active.Phone with { TransferPending = true } })
            Check(!(active with { Phone = blocked }).CanHold, "Unsafe quick hold transition");
        Check(!(active with { Busy = true }).CanEnd && !(incoming with { Busy = true }).CanAnswer, "Duplicate pending action allowed");
        Check(!idle.CanEnd && !idle.CanMute && !idle.CanHold && !idle.CanAnswer, "Stale call controls survived hangup");
        var bottom = QuickAccessPlacement.Place(new(0, 0, 1920, 1040), new(1840, 1040, 24, 40), 360, 480, 8);
        Check(bottom == new PopupBounds(1504, 552, 360, 480), "Bottom taskbar anchor");
        var top = QuickAccessPlacement.Place(new(-1920, 40, 1920, 1040), new(-80, 0, 24, 40), 360, 480, 8);
        Check(top.Y == 48 && top.X < 0, "Top taskbar / negative monitor coordinates");
        foreach (var work in new[] { new PopupBounds(-1280, -1024, 1280, 984), new PopupBounds(0, 0, 640, 400), new PopupBounds(1920, 0, 2560, 1400) })
        {
            var popup = QuickAccessPlacement.Place(work, new(work.X + work.Width, work.Y + work.Height, 30, 30), 540, 800, 12);
            Check(popup.X >= work.X && popup.Y >= work.Y && popup.X + popup.Width <= work.X + work.Width && popup.Y + popup.Height <= work.Y + work.Height,
                "Quick access left the monitor work area");
        }
        Console.WriteLine("PASS: quick-access call guards, dial validation, top/bottom taskbar, negative monitors and small work areas.");
    }
}
