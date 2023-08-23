#!/usr/bin/env bash

set -ex

killall io.elementary.appcenter || true
VERSION="$(dpkg-parsechangelog -S Version)"
rm -rf ./obj-x86_64-linux-gnu/
debuild -b -uc -us -nc
sudo dpkg -i "../pop-shop_${VERSION}_amd64.deb" "../pop-shop-dbgsym_${VERSION}_amd64.ddeb"
io.elementary.appcenter
