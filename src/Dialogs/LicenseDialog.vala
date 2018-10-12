/*
 * Copyright (c) 2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Cassidy James Blaede <c@ssidyjam.es>
 *
 */

public class AppCenter.Widgets.LicenseDialog : Gtk.Dialog {
    public signal void download_requested ();

    public string app_name { get; construct; }
    public string license_url { get; construct; }

    public LicenseDialog (string _app_name, string _license_url) {
        Object (
            app_name: _app_name,
            title: "License",
            deletable: false,
            license_url: _license_url,
            resizable: false,
            skip_taskbar_hint: true,
            skip_pager_hint: true
        );
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("dialog-warning", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        var primary_label = new Gtk.Label (_("%s Requires Accepting a License").printf (app_name));
        primary_label.max_width_chars = 50;
        primary_label.selectable = true;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class ("primary");

        var secondary_label = new Gtk.Label (_("You must read and accept this license to install and use %s. If you do not accept, %s will not be installed.").printf (app_name, app_name));
        secondary_label.max_width_chars = 50;
        secondary_label.selectable = true;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        var license_check = new Gtk.CheckButton ();

        var license_label = new Gtk.Label (_("I've read and accept <a href='%s'>the %s license</a>").printf (license_url, app_name));
        license_label.max_width_chars = 50;
        license_label.use_markup = true;
        license_label.wrap = true;
        license_label.xalign = 0;

        var license_grid = new Gtk.Grid ();
        license_grid.column_spacing = 6;
        license_grid.margin_top = 12;

        license_grid.attach (license_check, 0, 0);
        license_grid.attach (license_label, 1, 0);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.margin_start = grid.margin_end = 12;

        grid.attach (image,           0, 0, 1, 2);
        grid.attach (primary_label,   1, 0);
        grid.attach (secondary_label, 1, 1);
        grid.attach (license_grid,    1, 2);
        grid.show_all ();

        get_content_area ().add (grid);

        var cancel_button = (Gtk.Button) add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var install_button = (Gtk.Button) add_button (_("Install"), Gtk.ResponseType.OK);
        install_button.sensitive = false;
        install_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var action_area = get_action_area ();
        action_area.margin = 6;
        action_area.margin_top = 12;

        license_check.bind_property ("active", install_button, "sensitive");

        install_button.clicked.connect (() => {
            download_requested ();
            destroy ();
        });
        cancel_button.clicked.connect (() => destroy ());
    }
}
