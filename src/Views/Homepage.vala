/*
* Copyright 2016–2021 elementary, Inc. (https://elementary.io)
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

public class AppCenter.Homepage : Gtk.Box {
    public signal void show_package (AppCenterCore.Package package);
    public signal void show_category (AppStream.Category category);
    private const int MAX_PACKAGES_IN_BANNER = 5;
    private const int MAX_PACKAGES_IN_CAROUSEL = 12;
    private const string[] pop_picks = {
        "com.slack.Slack",
        "org.telegram",
        "org.gnome.meld",
        "com.valvesoftware.Steam",
        "net.lutris.Lutris",
        "com.mattermost.Desktop",
        "com.visualstudio.code",
        "org.gnome.DejaDup",
        "com.spotify.Client",
        "com.gexperts.Tilix",
        "alacritty",
        "com.uploadedlobster.peek",
        "virt-manager",
        "org.signal.Signal",
        "org.flameshot.Flameshot",
        "com.getpostman.Postman",
        "io.dbeaver.DBeaverCommunity",
        "org.chromium.Chromium"
    };

    private Gtk.FlowBox category_flow;
    private Gtk.ScrolledWindow scrolled_window;

    private Hdy.Carousel banner_carousel;
    private Gtk.Revealer banner_revealer;
    private Gtk.FlowBox recently_updated_carousel;
    private Gtk.Revealer recently_updated_revealer;
    private AppCenter.SearchView search_view;

#if POP_OS
    private Gtk.FlowBox picks_carousel;
    private Gtk.Revealer picks_revealer;
#endif

    private uint banner_timeout_id;

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        expand = true;

        banner_carousel = new Hdy.Carousel () {
            allow_long_swipes = true
        };

        var banner_event_box = new Gtk.EventBox ();
        banner_event_box.events |= Gdk.EventMask.ENTER_NOTIFY_MASK;
        banner_event_box.events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;
        banner_event_box.add (banner_carousel);

        var banner_dots = new Hdy.CarouselIndicatorDots () {
            carousel = banner_carousel
        };

        var banner_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        banner_box.add (banner_event_box);
        banner_box.add (banner_dots);

        banner_revealer = new Gtk.Revealer ();
        banner_revealer.add (banner_box);

#if POP_OS
        var pop_banner_copy_1 = new Gtk.Label (_("EXPLORE YOUR HORIZONS AND"));
        pop_banner_copy_1.margin_top = pop_banner_copy_1.margin_start = 38;
        pop_banner_copy_1.xalign = 0;
        pop_banner_copy_1.hexpand = true;
        pop_banner_copy_1.wrap = true;

        var pop_banner_copy_2 = new Gtk.Label (_("UNLEASH YOUR POTENTIAL"));
        pop_banner_copy_2.margin_start = pop_banner_copy_2.margin_end = 37;
        pop_banner_copy_2.xalign = 0;
        pop_banner_copy_2.hexpand = true;
        pop_banner_copy_2.wrap = true;

        var pop_banner = new Gtk.Grid ();
        pop_banner.height_request = 300;
        pop_banner.expand = true;
        pop_banner.get_style_context ().add_class ("pop-banner");
        pop_banner.attach (pop_banner_copy_1, 0, 0, 1, 1);
        pop_banner.attach (pop_banner_copy_2, 0, 1, 1, 1);

#endif

        var recently_updated_label = new Granite.HeaderLabel (_("Recently Updated")) {
            margin_start = 12,
            margin_top = 48
        };

        recently_updated_carousel = new Gtk.FlowBox () {
            activate_on_single_click = true,
            column_spacing = 12,
            row_spacing = 12,
            homogeneous = true,
            max_children_per_line = 5,
            selection_mode = Gtk.SelectionMode.NONE
        };

        var recently_updated_grid = new Gtk.Grid () {
            margin_end = 12,
            margin_start = 12
        };
        recently_updated_grid.attach (recently_updated_label, 0, 0);
        recently_updated_grid.attach (recently_updated_carousel, 0, 1);

        recently_updated_revealer = new Gtk.Revealer ();
        recently_updated_revealer.add (recently_updated_grid );

#if POP_OS
        var picks_label = new Granite.HeaderLabel (_("Pop!_Picks")) {
            margin_start = 12,
            margin_top = 18
        };

        picks_carousel = new Gtk.FlowBox () {
            activate_on_single_click = true,
            column_spacing = 12,
            row_spacing = 12,
            homogeneous = true,
            max_children_per_line = 5,
            selection_mode = Gtk.SelectionMode.NONE
        };


        var picks_grid = new Gtk.Grid () {
            margin_end = 12,
            margin_start = 12,
            row_spacing = 24
        };

        picks_grid.attach (picks_label, 0, 0);
        picks_grid.attach (picks_carousel, 0, 1);
        picks_revealer = new Gtk.Revealer ();
        picks_revealer.add (picks_grid );
#endif

        var categories_label = new Granite.HeaderLabel (_("Categories")) {
            margin_start = 24,
            margin_top = 24
        };

        category_flow = new Gtk.FlowBox () {
            activate_on_single_click = true,
            homogeneous = true,
            margin_start = 12,
            margin_end =12,
            margin_bottom = 12,
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.NONE
        };

        category_flow.set_sort_func ((child1, child2) => {
            var item1 = (AbstractCategoryCard) child1;
            var item2 = (AbstractCategoryCard) child2;
            if (item1 != null && item2 != null) {
                return item1.category.name.collate (item2.category.name);
            }

            return 0;
        });

        var games_card = new GamesCard ();

        category_flow.add (new LegacyCard (_("Accessories"), "applications-accessories", {"Utility"}, "accessories"));
        category_flow.add (new LegacyCard (_("Audio"), "appcenter-audio-symbolic", {"Audio", "Music"}, "audio"));
        category_flow.add (new LegacyCard (_("Communication"), "", {
            "Chat",
            "ContactManagement",
            "Email",
            "InstantMessaging",
            "IRCClient",
            "Telephony",
            "VideoConference"
        }, "communication"));
        category_flow.add (new LegacyCard (_("Development"), "", {
            "Database",
            "Debugger",
            "Development",
            "GUIDesigner",
            "IDE",
            "RevisionControl",
            "TerminalEmulator",
            "WebDevelopment"
        }, "development"));
        category_flow.add (new LegacyCard (_("Education"), "", {"Education"}, "education"));
        category_flow.add (new LegacyCard (_("Finance"), "appcenter-finance-symbolic", {
            "Economy",
            "Finance"
        }, "finance"));
        category_flow.add (games_card);
        category_flow.add (new LegacyCard (_("Graphics"), "", {
            "2DGraphics",
            "3DGraphics",
            "Graphics",
            "ImageProcessing",
            "Photography",
            "RasterGraphics",
            "VectorGraphics"
        }, "graphics"));
        category_flow.add (new LegacyCard (_("Internet"), "applications-internet", {
            "Network",
            "P2P"
        }, "internet"));
        category_flow.add (new LegacyCard (_("Math, Science, & Engineering"), "", {
            "ArtificialIntelligence",
            "Astronomy",
            "Biology",
            "Calculator",
            "Chemistry",
            "ComputerScience",
            "DataVisualization",
            "Electricity",
            "Electronics",
            "Engineering",
            "Geology",
            "Geoscience",
            "Math",
            "NumericalAnalysis",
            "Physics",
            "Robotics",
            "Science"
        }, "science"));
        category_flow.add (new LegacyCard (_("Media Production"), "appcenter-multimedia-symbolic", {
            "AudioVideoEditing",
            "Midi",
            "Mixer",
            "Recorder",
            "Sequencer"
        }, "media-production"));
        category_flow.add (new LegacyCard (_("Office"), "appcenter-office-symbolic", {
            "Office",
            "Presentation",
            "Publishing",
            "Spreadsheet",
            "WordProcessor"
        }, "office"));
        category_flow.add (new LegacyCard (_("System"), "applications-system-symbolic", {
            "Monitor",
            "System"
        }, "system"));
        category_flow.add (new LegacyCard (_("Universal Access"), "appcenter-accessibility-symbolic", {"Accessibility"}, "accessibility"));
        category_flow.add (new LegacyCard (_("Video"), "appcenter-video-symbolic", {
            "Tuner",
            "TV",
            "Video"
        }, "video"));
        category_flow.add (new LegacyCard (_("Writing & Language"), "preferences-desktop-locale", {
            "Dictionary",
            "Languages",
            "Literature",
            "OCR",
            "TextEditor",
            "TextTools",
            "Translation",
            "WordProcessor"
        }, "writing-language"));
        category_flow.add (new LegacyCard (_("Privacy & Security"), "preferences-system-privacy", {
            "Security",
        }, "privacy-security"));

#if POP_OS
        //  grid.add (picks_revealer);
#endif

        var box = new Gtk.Box (orientation = Gtk.Orientation.VERTICAL, 0);
        box.add (banner_revealer);
#if POP_OS
        box.add (picks_revealer);
#endif
        box.add (recently_updated_revealer);
        box.add (categories_label);
        box.add (category_flow);

        scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };
        scrolled_window.add (box);

        add (scrolled_window);

        var local_package = App.local_package;
        if (local_package != null) {
            var banner = new Widgets.Banner (local_package);

            banner_carousel.prepend (banner);

            banner.clicked.connect (() => {
                show_package (local_package);
            });
        }

#if POP_OS
        banner_carousel.prepend (pop_banner);
        banner_carousel.interactive = false;
        banner_dots.visible = false;

        // Show the banner, since it only contains our artwork currently
        banner_carousel.show_all ();
        banner_revealer.reveal_child = true;
        banner_timeout_start ();

#endif
        load_banners_and_carousels.begin ();

        category_flow.child_activated.connect ((child) => {
            var card = (AbstractCategoryCard) child;
            show_category (card.category);
        });

        banner_event_box.enter_notify_event.connect (() => {
            banner_timeout_stop ();
        });

#if !POP_OS
        banner_event_box.leave_notify_event.connect (() => {
            banner_timeout_start ();
        });
#endif

        recently_updated_carousel.child_activated.connect ((child) => {
            var package_row_grid = (AppCenter.Widgets.ListPackageRowGrid) child.get_child ();

            show_package (package_row_grid.package);
        });

#if POP_OS
        picks_carousel.child_activated.connect ((child) => {
            var package_row_grid = (AppCenter.Widgets.ListPackageRowGrid) child.get_child ();

            show_package (package_row_grid.package);
        });
#endif

        destroy.connect (() => {
            banner_timeout_stop ();
        });
    }

    private async void load_banners_and_carousels () {
        unowned var pk_client = AppCenterCore.PackageKitBackend.get_default ();
        unowned var fp_client = AppCenterCore.FlatpakBackend.get_default ();

        // Fix pango/gtk layout segfault when pk or fp are still loading.
        // And fix segfault in get_featured_packages.
        while (fp_client.working || pk_client.working) {
            yield Utils.nap(1000);
        }

        var packages_by_release_date = fp_client.get_featured_packages_by_release_date ();
        var packages_in_banner = new Gee.LinkedList<AppCenterCore.Package> ();



        int package_count = 0;

#if POP_OS
        var randomized_picks = new List<string> ();

        foreach (var item in pop_picks) {
            randomized_picks.append(item);
        }

        randomized_picks.sort ((a, b) => {
            return GLib.Random.int_range (-10000000, 10000000);
        });

        foreach (var id in randomized_picks) {
            if (picks_carousel.get_children ().length () > MAX_PACKAGES_IN_BANNER) {
                break;
            }

            var package = AppCenterCore.Client.get_default ().get_package_for_component_id (id);
            var installed = false;
            foreach (var origin_package in package.origin_packages) {
                try {
                    if (yield origin_package.backend.is_package_installed (origin_package)) {
                        installed = true;
                        break;
                    }
                } catch (Error e) {
                    continue;
                }
            }

            if (!installed) {
                packages_in_banner.add (package);
                package_count++;
                var package_row = new AppCenter.Widgets.ListPackageRowGrid (package);
                picks_carousel.add (package_row);
            }
        }

        picks_carousel.show_all ();
        picks_revealer.reveal_child = picks_carousel.get_children ().length () > 0;
#else
        foreach (var package in packages_by_release_date) {
            if (package_count >= MAX_PACKAGES_IN_BANNER) {
                break;
            }

            var installed = false;
            foreach (var origin_package in package.origin_packages) {
                try {
                    if (yield origin_package.backend.is_package_installed (origin_package)) {
                        installed = true;
                        break;
                    }
                } catch (Error e) {
                    continue;
                }
            }

            if (!installed) {
                packages_in_banner.add (package);
                package_count++;
            }
        }

        foreach (var package in packages_in_banner) {
            var banner = new Widgets.Banner (package);
            banner.clicked.connect (() => {
                show_package (package);
            });

            banner_carousel.add (banner);
        }
#endif

        banner_carousel.show_all ();
        banner_revealer.reveal_child = true;

        foreach (var package in packages_by_release_date) {
            if (recently_updated_carousel.get_children ().length () >= MAX_PACKAGES_IN_CAROUSEL) {
                break;
            }

            var installed = false;
            foreach (var origin_package in package.origin_packages) {
                try {
                    if (yield origin_package.backend.is_package_installed (origin_package)) {
                        installed = true;
                        break;
                    }
                } catch (Error e) {
                    continue;
                }
            }

            if (!installed && !(package in packages_in_banner)) {
                var package_row = new AppCenter.Widgets.ListPackageRowGrid (package);
                recently_updated_carousel.add (package_row);
            }
        }
        recently_updated_carousel.show_all ();
        recently_updated_revealer.reveal_child = recently_updated_carousel.get_children ().length () > 0;
    }

    private void banner_timeout_start () {
        if (banner_timeout_id != 0) {
            Source.remove (banner_timeout_id);
        }

        banner_timeout_id = Timeout.add (MILLISECONDS_BETWEEN_BANNER_ITEMS, () => {
            if (!banner_carousel.is_visible ()) {
                return Source.CONTINUE;
            }

            var new_index = (uint) banner_carousel.position + 1;
            var max_index = banner_carousel.n_pages - 1; // 0-based index

            if (banner_carousel.position >= max_index) {
                new_index = 0;
            }

            banner_carousel.switch_child (new_index, Granite.TRANSITION_DURATION_OPEN);

            return Source.CONTINUE;
        });
    }

    private void banner_timeout_stop () {
        if (banner_timeout_id != 0) {
            Source.remove (banner_timeout_id);
            banner_timeout_id = 0;
        }
    }

    private abstract class AbstractCategoryCard : Gtk.FlowBoxChild {
        public AppStream.Category category { get; protected set; }

        protected Gtk.Grid content_area;
        protected unowned Gtk.StyleContext style_context;

        protected static Gtk.CssProvider category_provider;

        static construct {
            category_provider = new Gtk.CssProvider ();
            category_provider.load_from_resource ("io/elementary/appcenter/categories.css");
        }

        construct {
            var expanded_grid = new Gtk.Grid () {
                hexpand = true,
                vexpand = true
            };

            content_area = new Gtk.Grid ();
            content_area.add (expanded_grid);

            style_context = content_area.get_style_context ();
            style_context.add_class (Granite.STYLE_CLASS_CARD);
            style_context.add_class (Granite.STYLE_CLASS_ROUNDED);
            style_context.add_class ("category");
            style_context.add_provider (category_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            child = content_area;
        }
    }

    private class LegacyCard : AbstractCategoryCard {
        public LegacyCard (string name, string icon, string[] groups, string style) {
            category = new AppStream.Category ();
            category.set_name (name);
            category.set_icon (icon);

            foreach (var group in groups) {
                category.add_desktop_group (group);
            }

            var name_label = new Gtk.Label (null);
            name_label.wrap = true;
            name_label.max_width_chars = 15;
            name_label.get_style_context ().add_provider (category_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER
            };

            content_area.attach (box, 0, 0);

            if (category.icon != "") {
                var display_image = new Gtk.Image.from_icon_name (category.icon, Gtk.IconSize.DIALOG) {
                    halign = Gtk.Align.END,
                    valign = Gtk.Align.CENTER
                };

                box.add (display_image);

                name_label.xalign = 0;
                name_label.halign = Gtk.Align.START;
            } else {
                name_label.justify = Gtk.Justification.CENTER;
            }

            box.add (name_label);
            style_context.add_class (style);

            if (style == "accessibility") {
                name_label.label = category.name.up ();
            } else {
                name_label.label = category.name;
            }

            if (style == "science") {
                name_label.justify = Gtk.Justification.CENTER;
            }
        }
    }

    private class GamesCard : AbstractCategoryCard {
        construct {
            category = new AppStream.Category () {
                name = _("Fun & Games"),
                icon = "appcenter-games-symbolic"
            };
            category.add_desktop_group ("ActionGame");
            category.add_desktop_group ("AdventureGame");
            category.add_desktop_group ("Amusement");
            category.add_desktop_group ("ArcadeGame");
            category.add_desktop_group ("BlocksGame");
            category.add_desktop_group ("BoardGame");
            category.add_desktop_group ("CardGame");
            category.add_desktop_group ("Game");
            category.add_desktop_group ("KidsGame");
            category.add_desktop_group ("LogicGame");
            category.add_desktop_group ("RolePlaying");
            category.add_desktop_group ("Shooter");
            category.add_desktop_group ("Simulation");
            category.add_desktop_group ("SportsGame");
            category.add_desktop_group ("StrategyGame");

            var image = new Gtk.Image () {
                icon_name = "appcenter-games-symbolic",
                pixel_size = 64
            };

            unowned var image_context = image.get_style_context ();
            image_context.add_class (Granite.STYLE_CLASS_ACCENT);
            image_context.add_class ("slate");

            var fun_label = new Gtk.Label (_("Fun &")) {
                halign = Gtk.Align.START
            };

            unowned var fun_label_context = fun_label.get_style_context ();
            fun_label_context.add_class (Granite.STYLE_CLASS_ACCENT);
            fun_label_context.add_class ("pink");
            fun_label_context.add_provider (category_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            var games_label = new Gtk.Label (_("Games"));

            unowned var games_label_context = games_label.get_style_context ();
            games_label_context.add_class (Granite.STYLE_CLASS_ACCENT);
            games_label_context.add_class ("blue");
            games_label_context.add_provider (category_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            var grid = new Gtk.Grid () {
                column_spacing = 12,
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER
            };
            grid.attach (image, 0, 0, 1, 2);
            grid.attach (fun_label, 1, 0);
            grid.attach (games_label, 1, 1);

            content_area.attach (grid, 0, 0);

            style_context.add_class ("games");
        }
    }
}
