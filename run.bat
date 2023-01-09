adb push D:\develop\android-busybox\busybox_UDHCPD /system/bin/udhcpd
adb shell chmod +x /system/bin/udhcpd
adb shell /system/bin/udhcpd -f /sdcard/udhcpd.conf