adb remount
set remote_dir=/data/udhcpd/
adb shell mkdir %remote_dir%
adb push udhcpd_arm64 %remote_dir%udhcpd
adb push init.udhcpd %remote_dir%
adb push udhcpd.conf %remote_dir%

adb shell /system/bin/sh %remote_dir%init.udhcpd
