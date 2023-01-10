adb push D:\develop\android-busybox\busybox_UDHCPD /system/bin/udhcpd
adb shell chmod +x /system/bin/udhcpd
adb shell ndc tether stop
adb shell "sed -i 's/p2p-p2p0-[0-9]*/$(ifconfig |grep p2p-p2p|awk -F' ' '{print $1}')/g' /sdcard/udhcpd.conf"
adb shell /system/bin/udhcpd -f /sdcard/udhcpd.conf