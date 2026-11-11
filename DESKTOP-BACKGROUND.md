# Background mode and Windows shell status

**Konto → Fenster & Infobereich** provides a saved switch for minimizing Fonado into the notification area. It is enabled by default. When disabled, minimizing keeps the normal taskbar button. Closing the main window continues to hide Fonado in the notification area; **Fonado beenden** remains the explicit exit action and asks before ending a live call.

Hiding a window leaves the same liblinphone worker/registration alive. It does not sign out, change an incoming-call profile or start a second SIP engine. The compact call window remains available for incoming/live calls. A first-use, silent shell hint per app run explains how to reopen Fonado. Left click or keyboard activation of the icon opens the quick-access window; double click opens the main window. A tray failure restores/retains the window; open dialogs prevent hiding it. The feature does not wake an exited process or a sleeping/offline PC.

## Quick-access window

Based on the [Mac menu-bar view](https://github.com/ivama-dev/fonado-macos/blob/3715b719e228aefd757ab6ab0dda2c095a6d692d/macos/fonuMac/MacCallStatusItem.swift), the Windows quick access shows registration, company/extension, incoming-call profile, direct dialing, Favorites/Team/History shortcuts and DND. Incoming and live calls replace direct dialing with caller, status, duration, measured audio level and the applicable answer/mute/hold/end actions. The full conversation view remains available for transfers and consultation.

The same account context, profile writer, number validator and guarded SIP actions serve both windows. A scope change clears typed numbers and feedback. The existing Windows DND behavior is retained: a company-level DND setting cannot be overridden locally; the view displays the existing explanation. Profile selection uses the shared cloud profiles. Opening the view refreshes profile state without creating a SIP worker.

The window anchors to the notification icon using `Shell_NotifyIconGetRect`, remains within that monitor's work area and scales with DPI. It has no separate taskbar or Alt-Tab entry. Escape, the close button or focus leaving the window dismisses it; profile menus remain usable. **Fonado öffnen** restores the main window. The existing mini call window is temporarily hidden while quick access is visible. **Konto → Fenster & Infobereich → Schnellzugriff öffnen** provides access even when Windows hides the notification icon in overflow. Right click continues to open the native menu.

Tray activation accepts both the mouse-release callback and Shell selection callbacks, with paired notifications consumed once. Opening runs on the existing UI thread directly within the shell callback and explicitly requests foreground focus from Explorer. The release following a double click cannot reopen quick access over the main window. Regression checks cover mouse-only, selection-only, paired, keyboard and double-click callback sequences.

The explicit Debug design preview includes a **Tray** menu for ready/incoming/active fixtures. It uses synthetic data and no account or SIP engine. DesktopData checks cover action guards and placement on top/bottom taskbars, negative monitor coordinates and small work areas. Actual calls, hardware audio and a multi-monitor DPI setup remain device acceptance checks.

## Status and quick actions

The notification-area icon uses the dedicated Fonado.Tray.ico artwork. Its
brand mark remains unobscured in every state, including after Explorer restarts.
The artwork is proportionally reduced to 72% of its former painted footprint,
with transparent padding inside the unchanged Windows notification-area slot.
The notification GUID is stable per executable location for unsigned desktop
builds, or per package family for packaged builds. This avoids Windows rejecting
the icon after executable renames, moves or side-by-side installations.
See [Microsoft guidance](https://learn.microsoft.com/en-us/windows/win32/api/shellapi/ns-shellapi-notifyicondataw#troubleshooting). Connection/call
status is available in the tooltip, native menu and quick access.

Taskbar overlays continue to use the following small color/symbol badges:

| State | Badge |
| --- | --- |
| Registered and ready | Green check |
| Signed out/disconnected | Gray cross |
| Do not disturb | Red minus |
| Incoming/outgoing call setup | Lime bell/ellipsis |
| Connected call | Lime activity bars |
| Held call | Amber pause |
| Muted microphone | Amber microphone/slash |

Status priority preserves incoming, held and active call feedback even if registration is interrupted or DND is set. The tooltip includes the telephone status and company/extension/profile while idle, or the peer and duration during a call. It is bounded to the shell limit without splitting Unicode surrogate pairs. Native menu labels strip control characters and escape ampersands.

The right-click menu shows current status, company/extension and profile, and links to Wählen, Favoriten, Anrufliste, Audio and Anrufprofile. Active call actions use the same guarded controller as the main/mini windows. Reconnect is available only outside calls; DND shows its checked state. **In den Hintergrund** and **Fonado beenden** are separate actions. The settings page's **Schnellmenü öffnen** button opens this same menu for discoverability.

When a taskbar button exists, `ITaskbarList3.SetOverlayIcon` applies the same status badge with accessible text. Badges change only on state transitions, without animation. The tray tooltip updates call duration at most once a second. All native icons are cached per state and released on shutdown. A shell restart re-adds the tray icon and reapplies the overlay; another one-shot retry covers taskbar recreation. There is no background timer dedicated to drawing badges.

The shell remains responsible for placing the notification-area icon in its visible or overflow section. Users can move it out of the overflow area; Fonado does not change Windows taskbar settings. Taskbar overlays depend on shell/taskbar configuration. See [Microsoft's notification-area API](https://learn.microsoft.com/en-us/windows/win32/shell/notification-area) and [taskbar overlay API](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-itaskbarlist3-setoverlayicon).

## Settings and validation

`%LOCALAPPDATA%\Fonado\Windows\desktop-settings.json` contains only schema version 1 and `MinimizeToTray`. This is a local Windows-user preference, independent of Fonado account/company and call-routing profiles. Writes use an atomic temporary-file replacement. Unreadable, oversized or unknown-version files are preserved, the switch is disabled, and normal taskbar minimization remains available. The explicit Debug preview stores its setting under its own `qa/desktop` directory.

DesktopData checks cover preference persistence, invalid-file preservation, safe hiding policy, status precedence, tooltip limits and distinct rasterized glyphs. Native icon probing additionally checks eight states, repeated cached lookups and stable GDI/USER resource counts across create/dispose cycles. Native Windows UI checks cover minimizing/reopening and the menu. Sleep/network recovery and incoming call behavior on other hardware remain part of release acceptance.
