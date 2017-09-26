#!/bin/bash

set -ex

debuild -b
sudo dpkg -i ../pop-shop_0.2.6-0_amd64.deb
killall io.elementary.appcenter || true
killall org.pop-os.shop || true
org.pop-os.shop -s &
