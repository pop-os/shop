include (Translations)
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../src
    ../daemon
    DESKTOP_FILES
        ${CMAKE_BINARY_DIR}/data/org.pop.shop.desktop.in
    APPDATA_FILES
        ../data/org.pop.shop.appdata.xml.in
)
