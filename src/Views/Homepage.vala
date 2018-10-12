// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
* Copyright (c) 2016-2017 elementary LLC. (https://elementary.io)
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
* Authored by: Nathan Dyer <mail@nathandyer.me>
*              Dane Henson <thegreatdane@gmail.com>
*/

using AppCenterCore;

const int NUM_PACKAGES_IN_CAROUSEL = 15;

namespace AppCenter {
    public class Homepage : View {
        // Keep things lined up whether certain revealers are shown or not
        private const int HOMEPAGE_MARGIN = 12;
        private const int LABEL_MARGIN = 10;

        private Gtk.FlowBox category_flow;
        private Gtk.ScrolledWindow category_scrolled;
        private string current_category;

        public bool viewing_package { get; private set; default = false; }

        public AppStream.Category currently_viewed_category;
        public MainWindow main_window { get; construct; }
        public Gtk.Revealer switcher_revealer;
        private Gtk.Revealer featured_revealer;
        public Widgets.Carousel featured_carousel;
        private AppCenterCore.Package[] featured_apps;

        public Homepage (MainWindow main_window) {
            Object (main_window: main_window);
        }

        construct {
            var houston = AppCenterCore.Houston.get_default ();

            var switcher = new Widgets.Switcher ();
            switcher.halign = Gtk.Align.CENTER;

            switcher_revealer = new Gtk.Revealer ();
            switcher_revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
            switcher_revealer.set_transition_duration (Widgets.Banner.TRANSITION_DURATION_MILLISECONDS);
            switcher_revealer.add (switcher);

            var pop_banner_copy_1 = new Gtk.Label (_("EXPLORE YOUR HORIZONS AND"));
            pop_banner_copy_1.expand = false;
            pop_banner_copy_1.halign = Gtk.Align.START;
            pop_banner_copy_1.margin_start = 48;
            pop_banner_copy_1.margin_top = 38;
            pop_banner_copy_1.yalign = 0;

            // FIXME: For some reason this isn't working right. Toggling it in
            // the inspector fixes the alignment.
            pop_banner_copy_1.vexpand = false;

            var pop_banner_copy_2 = new Gtk.Label (_("UNLEASH YOUR POTENTIAL"));
            pop_banner_copy_2.halign = Gtk.Align.START;
            pop_banner_copy_2.margin_start = 48;
            pop_banner_copy_2.yalign = 0;

            var pop_banner_copy_area = new Gtk.Grid ();
            pop_banner_copy_area.halign = Gtk.Align.CENTER;
            pop_banner_copy_area.hexpand = true;
            pop_banner_copy_area.width_request = 750;
            pop_banner_copy_area.attach (pop_banner_copy_1, 0, 0, 1, 1);
            pop_banner_copy_area.attach (pop_banner_copy_2, 0, 1, 1, 1);

            var pop_banner = new Gtk.Grid ();
            pop_banner.height_request = 300;
            pop_banner.hexpand = true;
            pop_banner.get_style_context ().add_class ("pop-banner");
            pop_banner.attach (pop_banner_copy_area, 0, 0, 1, 1);

            var featured_label = new Gtk.Label (_("Pop!_Picks"));
            featured_label.get_style_context ().add_class ("h4");
            featured_label.xalign = 0;
            featured_label.margin_start = LABEL_MARGIN;

            featured_carousel = new Widgets.Carousel ();

            var featured_grid = new Gtk.Grid ();
            featured_grid.margin = HOMEPAGE_MARGIN;
            featured_grid.margin_bottom = 0;
            featured_grid.attach (featured_label, 0, 0, 1, 1);
            featured_grid.attach (featured_carousel, 0, 1, 1, 1);

            featured_revealer = new Gtk.Revealer ();
            featured_revealer.add (featured_grid );

            var categories_label = new Gtk.Label (_("Categories"));
            categories_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            categories_label.xalign = 0;
            categories_label.margin_start = HOMEPAGE_MARGIN + LABEL_MARGIN;
            categories_label.margin_top = HOMEPAGE_MARGIN;

            category_flow = new Widgets.CategoryFlowBox ();
            category_flow.margin = HOMEPAGE_MARGIN;
            category_flow.margin_top = 0;
            category_flow.valign = Gtk.Align.START;

            var grid = new Gtk.Grid ();
            grid.attach (pop_banner,        0, 0, 1, 1);
            grid.attach (featured_revealer, 0, 1, 1, 1);
            grid.attach (categories_label,  0, 2, 1, 1);
            grid.attach (category_flow,     0, 3, 1, 1);

            category_scrolled = new Gtk.ScrolledWindow (null, null);
            category_scrolled.add (grid);

            add (category_scrolled);

            houston.get_app_ids.begin ("/newest/project", (obj, res) => {
                var featured_ids = houston.get_app_ids.end (res);
                Utils.shuffle_array (featured_ids);
                new Thread<void*> ("update-featured-carousel", () => {
                    Idle.add (() => {
                        main_window.homepage_loaded ();
                        return false;
                    });

                    featured_apps = {};
                    foreach (var package in featured_ids) {
                        var candidate = package + ".desktop";
                        var candidate_package = AppCenterCore.Client.get_default ().get_package_for_component_id (candidate);

                        if (candidate_package != null) {
                            candidate_package.update_state ();
                            if (candidate_package.state == AppCenterCore.Package.State.NOT_INSTALLED) {
                                featured_apps += candidate_package;
                            }
                        }
                    }

                    shuffle_featured_apps ();
                    return null;
                });
            });

            category_flow.child_activated.connect ((child) => {
                var item = child as Widgets.CategoryItem;
                if (item != null) {
                    currently_viewed_category = item.app_category;
                    show_app_list_for_category (item.app_category);
                }
            });

            category_flow.set_sort_func ((child1, child2) => {
                var item1 = child1 as Widgets.CategoryItem;
                var item2 = child2 as Widgets.CategoryItem;
                if (item1 != null && item2 != null) {
                    return item1.app_category.name.collate (item2.app_category.name);
                }

                return 0;
            });

            featured_carousel.package_activated.connect (show_package);
        }

        public void shuffle_featured_apps () {
            featured_carousel.get_children ().foreach ((c) => c.destroy ());
            Utils.shuffle_array (featured_apps);

            if (featured_apps.length != 0) {
                Idle.add (() => {
                    for (int i = 0; i < NUM_PACKAGES_IN_CAROUSEL && i < featured_apps.length; i++) {
                        featured_carousel.add_package (featured_apps[i]);
                    }
                    featured_revealer.reveal_child = true;
                    return false;
                });
            }
        }

        public override void show_package (AppCenterCore.Package package) {
            base.show_package (package);
            viewing_package = true;
            current_category = null;
            currently_viewed_category = null;
            subview_entered (_("Home"), false, "");
        }

        public override void return_clicked () {
            remove_visible_package ();

            if (previous_package != null) {
                show_package (previous_package);
                if (current_category != null) {
                    subview_entered (current_category, false, "");
                } else {
                    subview_entered (_("Home"), false, "");
                }
            } else if (viewing_package && current_category != null) {
                set_visible_child_name (current_category);
                viewing_package = false;
                subview_entered (_("Home"), true, current_category, _("Search %s").printf (current_category));
            } else {
                set_visible_child (category_scrolled);
                viewing_package = false;
                currently_viewed_category = null;
                current_category = null;
                subview_entered (null, true);
            }
        }

        private void show_app_list_for_category (AppStream.Category category) {
            subview_entered (_("Home"), true, category.name, _("Search %s").printf (category.name));
            current_category = category.name;
            var child = get_child_by_name (category.name);
            if (child != null) {
                set_visible_child (child);
                return;
            }

            var app_list_view = new Views.AppListView ();
            app_list_view.show_all ();
            add_named (app_list_view, category.name);
            set_visible_child (app_list_view);

            app_list_view.show_app.connect ((package) => {
                viewing_package = true;
                base.show_package (package);
                subview_entered (category.name, false, "");
            });

            unowned Client client = Client.get_default ();
            var apps = client.get_applications_for_category (category);
            app_list_view.add_packages (apps);
        }
    }
}
