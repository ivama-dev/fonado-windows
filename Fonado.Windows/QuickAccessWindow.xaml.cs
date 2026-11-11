using System.Runtime.InteropServices;
using Fonado.Windows.Desktop;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Windows.Foundation;
using Windows.Graphics;
using Windows.System;

namespace Fonado.Windows;

// A view of MainWindow's account and SIP state. This window never owns a phone engine.
public sealed partial class QuickAccessWindow : Window
{
    private readonly Action<int> command;
    private readonly Func<string, Task<bool>> dial;
    private readonly Action<FrameworkElement> profiles;
    private QuickAccessState? current;
    private PopupBounds anchor, workArea;
    private bool applying, disposing, sizing;
    private long dismissedAt;
    private string callId = "";
    public event Action? VisibilityUpdated;
    public bool WasJustDismissed => Environment.TickCount64 - dismissedAt < 250;

    public QuickAccessWindow(Action<int> command, Func<string, Task<bool>> dial, Action<FrameworkElement> profiles)
    {
        this.command = command; this.dial = dial; this.profiles = profiles;
        InitializeComponent();
        AppWindow.SetIcon(Path.Combine(AppContext.BaseDirectory, "Assets", "Fonado.ico"));
        AppWindow.IsShownInSwitchers = false;
        if (AppWindow.Presenter is OverlappedPresenter presenter)
        {
            presenter.IsResizable = presenter.IsMaximizable = presenter.IsMinimizable = false;
            presenter.IsAlwaysOnTop = true;
            presenter.SetBorderAndTitleBar(true, false);
        }
        Root.Loaded += (_, _) =>
        {
            ResizeToContent();
            Root.XamlRoot.Changed += (_, _) => ResizeToContent();
        };
        Activated += (_, args) =>
        {
            if (args.WindowActivationState == WindowActivationState.Deactivated)
                DispatcherQueue.TryEnqueue(() => { if (!disposing && !OwnsForeground()) Hide(); });
        };
        AppWindow.Closing += (_, args) => { if (!disposing) { args.Cancel = true; Hide(); } };
    }

    private bool OwnsForeground()
    {
        var own = WinRT.Interop.WindowNative.GetWindowHandle(this);
        // A profile flyout may have an owned popup HWND. Keep it interactive.
        for (var foreground = GetForegroundWindow(); foreground != IntPtr.Zero; foreground = GetWindow(foreground, 4))
            if (foreground == own) return true;
        return false;
    }

    public void Show(RectInt32? iconArea, Microsoft.UI.WindowId mainWindow)
    {
        if (disposing) return;
        var display = iconArea is { } rectangle ? DisplayArea.GetFromRect(rectangle, DisplayAreaFallback.Nearest)
            : DisplayArea.GetFromWindowId(mainWindow, DisplayAreaFallback.Nearest);
        var area = display.WorkArea;
        workArea = new(area.X, area.Y, area.Width, area.Height);
        anchor = iconArea is { } icon ? new(icon.X, icon.Y, icon.Width, icon.Height)
            : new(area.X + area.Width - 12, area.Y + area.Height, 1, 1);
        // Put the window on the correct monitor before measuring its DPI-scaled content.
        AppWindow.Move(new PointInt32(area.X + area.Width - 360, area.Y + area.Height - 500));
        ResizeToContent();
        AppWindow.Show(); Activate();
        // Window.Activate alone does not reliably transfer foreground from Explorer.
        SetForegroundWindow(WinRT.Interop.WindowNative.GetWindowHandle(this));
        DispatcherQueue.TryEnqueue(() => { if (!disposing && AppWindow.IsVisible) { ResizeToContent(); Number.Focus(FocusState.Programmatic); } });
        VisibilityUpdated?.Invoke();
    }

    public void Hide()
    {
        if (disposing || !AppWindow.IsVisible) return;
        AppWindow.Hide(); dismissedAt = Environment.TickCount64;
        VisibilityUpdated?.Invoke();
    }

    private void ResizeToContent()
    {
        if (disposing || sizing || workArea.Width <= 0) return;
        sizing = true;
        try
        {
            var scale = Root.XamlRoot?.RasterizationScale ?? 1;
            GetClientRect(WinRT.Interop.WindowNative.GetWindowHandle(this), out var client);
            var chromeWidth = Math.Max(0, AppWindow.Size.Width - client.Right);
            var chromeHeight = Math.Max(0, AppWindow.Size.Height - client.Bottom);
            var gap = (int)Math.Ceiling(8 * scale);
            var contentWidth = Math.Min(360, Math.Max(1, (workArea.Width - chromeWidth - 2 * gap) / scale));
            Body.Measure(new Size(Math.Max(1, contentWidth - 2), double.PositiveInfinity));
            var bounds = QuickAccessPlacement.Place(workArea, anchor, (int)Math.Ceiling(contentWidth * scale) + chromeWidth,
                (int)Math.Ceiling((Body.DesiredSize.Height + 2) * scale) + chromeHeight, gap);
            var position = AppWindow.Position; var size = AppWindow.Size;
            if (position.X != bounds.X || position.Y != bounds.Y || size.Width != bounds.Width || size.Height != bounds.Height)
                AppWindow.MoveAndResize(new RectInt32(bounds.X, bounds.Y, bounds.Width, bounds.Height));
        }
        finally { sizing = false; }
    }

    public void Update(QuickAccessState next)
    {
        if (disposing) return;
        applying = true;
        try
        {
            if (current?.Scope != next.Scope) { Number.Text = ""; Feedback.Text = ""; Feedback.Visibility = Visibility.Collapsed; }
            current = next;
            var phone = next.Phone;
            Connection.Text = next.Connection;
            ConnectionIcon.Glyph = phone.Registered ? "\uE73E" : "\uE946";
            ConnectionIcon.Style = (Style)Body.Resources[phone.Registered ? "QuickReady" : "QuickOffline"];
            Company.Text = next.Company; Extension.Text = next.Extension.Replace("Deine Nebenstelle: ", "DW ");
            ToolTipService.SetToolTip(Company, next.Company);
            Identity.Visibility = string.IsNullOrWhiteSpace(next.Company + next.Extension) ? Visibility.Collapsed : Visibility.Visible;
            ProfileRow.Visibility = next.HasProfiles ? Visibility.Visible : Visibility.Collapsed;
            ProfileName.Text = next.Profile; ProfileButton.IsEnabled = next.CanProfiles;
            AutomationProperties.SetName(ProfileButton, "Anrufprofil: " + next.Profile);
            DialRow.Visibility = phone.InCall ? Visibility.Collapsed : Visibility.Visible;
            CallCard.Visibility = phone.InCall ? Visibility.Visible : Visibility.Collapsed;
            Peer.Text = phone.Peer; CallState.Text = phone.Status;
            ToolTipService.SetToolTip(Peer, phone.Peer);
            if (phone.CallId != callId || !phone.InCall) { Duration.Text = ""; LevelMeter.SetLevel(0, 0, false); }
            callId = phone.CallId;
            Answer.Visibility = phone.Incoming ? Visibility.Visible : Visibility.Collapsed;
            Mute.Visibility = Hold.Visibility = phone.Incoming ? Visibility.Collapsed : Visibility.Visible;
            Answer.IsEnabled = next.CanAnswer; Mute.IsEnabled = next.CanMute; Hold.IsEnabled = next.CanHold; End.IsEnabled = next.CanEnd;
            MuteIcon.Glyph = phone.Muted ? "\uE74F" : "\uE720";
            HoldIcon.Glyph = phone.Held ? "\uE768" : "\uE769";
            Mute.Style = (Style)Body.Resources[phone.Muted ? "QuickSelected" : "QuickNeutral"];
            Hold.Style = (Style)Body.Resources[phone.Held ? "QuickSelected" : "QuickNeutral"];
            SetAction(Mute, phone.Muted ? "Mikrofon aktivieren" : "Mikrofon stummschalten");
            SetAction(Hold, phone.Held ? "Gespräch fortsetzen" : "Gespräch halten");
            End.Content = phone.Incoming ? "Ablehnen" : "Auflegen";
            SetAction(End, phone.Consulting ? "Beide Gespräche beenden" : phone.Incoming ? "Anruf ablehnen" : "Auflegen");
            Conversation.Content = phone.Consulting ? "Zur Rückfrage / Weiterleitung" : "Zum Gespräch";
            Dnd.IsOn = phone.DoNotDisturb; Dnd.IsEnabled = next.CanPhone && !next.Busy;
            Number.IsEnabled = next.CanPhone && !next.Busy;
            Dial.IsEnabled = next.CanDial(Number.Text);
        }
        finally { applying = false; }
        if (AppWindow.IsVisible) ResizeToContent();
    }

    public void SetActivity(string duration, double[] levels)
    {
        if (disposing || !AppWindow.IsVisible) return;
        Duration.Text = duration;
        LevelMeter.SetLevel(levels.Length > 0 ? levels[^1] : 0, levels.Length > 0 ? levels.Max() : 0,
            current?.Phone is { Active: true, Held: false, RemoteHeld: false });
    }
    public void SetFeedback(string text)
    {
        Feedback.Text = text; Feedback.Visibility = string.IsNullOrWhiteSpace(text) ? Visibility.Collapsed : Visibility.Visible;
        if (AppWindow.IsVisible) ResizeToContent();
    }
    public void DisposeWindow() { disposing = true; Close(); }
    private static void SetAction(Button button, string text) { AutomationProperties.SetName(button, text); ToolTipService.SetToolTip(button, text); }
    private void CloseClicked(object sender, RoutedEventArgs e) => Hide();
    private void RootKeyDown(object sender, KeyRoutedEventArgs e) { if (e.Key == VirtualKey.Escape) { e.Handled = true; Hide(); } }
    private void NumberChanged(object sender, TextChangedEventArgs e) { if (Dial is not null) Dial.IsEnabled = current?.CanDial(Number.Text) == true; }
    private async void NumberKeyDown(object sender, KeyRoutedEventArgs e) { if (e.Key == VirtualKey.Enter) { e.Handled = true; await DialAsync(); } }
    private async void DialClicked(object sender, RoutedEventArgs e) => await DialAsync();
    private async Task DialAsync()
    {
        if (current?.CanDial(Number.Text) != true) return;
        SetFeedback("");
        var scope = current.Scope;
        if (await dial(Number.Text) && current?.Scope == scope) Number.Text = "";
    }
    private void ProfilesClicked(object sender, RoutedEventArgs e) => profiles(ProfileButton);
    private void DndToggled(object sender, RoutedEventArgs e) { if (!applying && current is { CanPhone: true, Busy: false }) command(7); }
    private void OpenClicked(object sender, RoutedEventArgs e) { Hide(); command(1); }
    private void QuitClicked(object sender, RoutedEventArgs e) { Hide(); command(8); }
    private void FavoritesClicked(object sender, RoutedEventArgs e) { Hide(); command(13); }
    private void HistoryClicked(object sender, RoutedEventArgs e) { Hide(); command(14); }
    private void TeamClicked(object sender, RoutedEventArgs e) { Hide(); command(20); }
    private void AnswerClicked(object sender, RoutedEventArgs e) { if (current?.CanAnswer == true) command(3); }
    private void MuteClicked(object sender, RoutedEventArgs e) { if (current?.CanMute == true) command(4); }
    private void HoldClicked(object sender, RoutedEventArgs e) { if (current?.CanHold == true) command(5); }
    private void EndClicked(object sender, RoutedEventArgs e) { if (current?.CanEnd == true) command(6); }
    [DllImport("user32.dll")] private static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] private static extern bool SetForegroundWindow(IntPtr window);
    [DllImport("user32.dll")] private static extern IntPtr GetWindow(IntPtr window, uint command);
    [StructLayout(LayoutKind.Sequential)] private struct NativeRect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] private static extern bool GetClientRect(IntPtr window, out NativeRect rect);
}
