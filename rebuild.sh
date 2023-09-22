#!/usr/bin/env bash

set -ex

killall io.elementary.appcenter || true
VERSION="$(dpkg-parsechangelog -S Version)"
rm -rf ./obj-x86_64-linux-gnu/
debuild -b -uc -us -nc

if [ "$1" == "debug" ]; then
    sudo dpkg -i "../pop-shop_${VERSION}_amd64.deb" "../pop-shop-dbgsym_${VERSION}_amd64.ddeb"
    gdb io.elementary.appcenter
else
    sudo dpkg -i "../pop-shop_${VERSION}_amd64.deb"
    io.elementary.appcenter
fi
