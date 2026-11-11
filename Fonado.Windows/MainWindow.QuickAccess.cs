using Fonado.Windows.Desktop;
using Fonado.Windows.Telephony;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace Fonado.Windows;

public sealed partial class MainWindow
{
    private QuickAccessWindow? quickAccess;
    private QuickAccessState QuickAccessSnapshot => new(DisplaySnapshot,
        snapshot.Registered ? previewMode ? "Verbunden · Designvorschau" : "Verbunden" : snapshot.InCall ? "Telefonie nicht registriert" : Status.Text,
        CompanyName.Text, ExtensionLabel.Text,
        ProfileName.Text, accountId + ":" + activeTenant, engine is not null || previewMode,
        callActionPending || operation is not null || closed || closingWithEngine || modalOpen || audioDialogOpen || quitDialogOpen,
        availability is not null && ProfileContextCurrent(CaptureProfileContext()), CanOpenProfiles);

    private void UpdateQuickAccess() => quickAccess?.Update(QuickAccessSnapshot);

    private void ToggleQuickAccess()
    {
        if (quickAccess?.AppWindow.IsVisible == true) { quickAccess.Hide(); return; }
        if (quickAccess?.WasJustDismissed == true) return;
        ShowQuickAccess();
    }

    private void ShowQuickAccess()
    {
        if (closed || closingWithEngine) return;
        if (modalOpen || audioDialogOpen || quitDialogOpen) { ShowMain(); return; }
        if (quickAccess is null)
        {
            quickAccess = new(QuickAccessCommand, QuickDialAsync, anchor => ProfilesClicked(anchor, new RoutedEventArgs()));
            quickAccess.VisibilityUpdated += () =>
            {
                RefreshActivityCadence();
                if (quickAccess.AppWindow.IsVisible) miniCall?.AppWindow.Hide();
                else if (!AppWindow.IsVisible) ShowMiniCall(false);
            };
        }
        UpdateQuickAccess();
        quickAccess.SetActivity(durationText, activityLevels);
        quickAccess.Show(tray?.GetIconArea(), AppWindow.Id);
        _ = RefreshQuickProfilesAsync();
    }

    private async Task RefreshQuickProfilesAsync()
    {
        if (!CanOpenProfiles) return;
        var context = CaptureProfileContext(); profileBusy = true; RenderProfileButton();
        try { await ReadProfilesAsync(context); }
        catch (OperationCanceledException) when (!ProfileContextCurrent(context)) { }
        catch (Exception error) { if (ProfileScopeCurrent(context)) ShowNotice(ProfileError(error, context)); }
        finally { profileBusy = false; RenderProfileButton(); }
    }

    private async Task<bool> QuickDialAsync(string value)
    {
        if (!QuickAccessSnapshot.CanDial(value) || DialNumber.Normalize(value) is not { } number) return false;
#if FONADO_DESIGN_PREVIEW
        if (previewMode)
        {
            UpdatePhone(snapshot with { InCall = true, Active = true, Peer = "Alex Beispiel", CallId = Guid.NewGuid().ToString(), Status = "Gespräch · Designvorschau" });
            return true;
        }
#endif
        Number.Text = number;
        await PhoneActionAsync(phone => phone.DialAsync(number));
        return snapshot.InCall;
    }

    private void QuickAccessCommand(int command)
    {
        var state = QuickAccessSnapshot;
        if (command == 3 && !state.CanAnswer || command == 4 && !state.CanMute || command == 5 && !state.CanHold ||
            command == 6 && !state.CanEnd || command == 7 && (!state.CanPhone || state.Busy)) return;
#if FONADO_DESIGN_PREVIEW
        if (previewMode)
        {
            if (command == 3) { UpdatePhone(snapshot with { Incoming = false, Active = true, Status = "Gespräch · Designvorschau" }); return; }
            if (command == 7) { UpdatePhone(snapshot with { DoNotDisturb = !snapshot.DoNotDisturb }); return; }
            if (command == 6) { UpdatePhone(new(true, false, false, false, "Verbunden · Designvorschau", "")); return; }
            if (command is 4 or 5) { PreviewMiniCommand(command); return; }
        }
#endif
        DesktopCommand(command);
    }

    private void QuickAccessClicked(object sender, RoutedEventArgs e) => ShowQuickAccess();
    private void PreviewQuickClicked(object sender, RoutedEventArgs e)
    {
#if FONADO_DESIGN_PREVIEW
        var mode = (sender as FrameworkElement)?.Tag as string;
        CompanyName.Text = "Beispielfirma · Designvorschau"; ExtensionLabel.Text = "Deine Nebenstelle: 100";
        UpdatePhone(new(true, mode != "ready", mode == "incoming", false,
            mode == "incoming" ? "Eingehender Anruf · Designvorschau" : mode == "call" ? "Gespräch · Designvorschau" : "Verbunden · Designvorschau",
            mode == "ready" ? "" : "Alex Beispiel", Active: mode == "call", CallId: mode == "ready" ? "" : "preview-quick-call"));
        ShowQuickAccess();
#endif
    }
}
