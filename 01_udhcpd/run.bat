adb remount
adb push busybox_UDHCPD /system/bin/udhcpd
adb push init.udhcpd /system/bin/
adb push udhcpd.conf /sdcard/

adb shell chmod +x /system/bin/udhcpd
adb shell chmod +x /system/bin/init.udhcpd

adb shell /system/bin/init.udhcpd
