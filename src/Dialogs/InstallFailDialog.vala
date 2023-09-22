/*
 * Copyright 2020 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

public class InstallFailDialog : Granite.MessageDialog {
    public AppCenterCore.Package? package { get; construct; }
    public string error_message { get; construct; }
    private const string FALLBACK_ICON = "application-default-icon";
    private const int REPAIR_RESPONSE_ID = 1;

    public InstallFailDialog (AppCenterCore.Package? package, string error_message) {
        Object (
            title: "",
            secondary_text: _(error_message.contains ("whilst offline")
                                ? "You appear to be offline.\n\nVerify your internet connection, including the system's VPN and proxy settings, and try again."
                                : "Try the following to resolve this error:\n\n• Install all available updates, reboot, and try again.\n\n• If the software supports multiple installation types, use the drop-down next to the Install button to select a different option and try again."
                            ),
            badge_icon: new ThemedIcon ("dialog-error"),
            error_message: error_message,
            package: package
        );
    }

    construct {
        if (package == null) {
            primary_text = _("Failed to install app.");
            image_icon = new ThemedIcon (FALLBACK_ICON);
        } else {
            primary_text = _("Failed to install %s.").printf (package.get_name ());
            image_icon = package.get_icon (48, get_scale_factor ());
        }
        
        add_button (_("Ignore"), Gtk.ResponseType.CLOSE);
        
        string UPDATES_BUTTON_TEXT = "Check For Updates";
        int UPDATES_BUTTON_RESPONSE = 1;
        if (error_message.contains ("whilst offline")) {
            UPDATES_BUTTON_TEXT = "Network Settings...";
            UPDATES_BUTTON_RESPONSE = 2;
        } else if (package.is_flatpak) {
            UPDATES_BUTTON_TEXT = "Repair";
            UPDATES_BUTTON_RESPONSE = 3;
        }
        var updates_button = add_button (_(UPDATES_BUTTON_TEXT), UPDATES_BUTTON_RESPONSE);
        updates_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        updates_button.grab_focus ();

        show_error_details (error_message);
    }
}
