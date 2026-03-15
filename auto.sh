#!/bin/bash
safe_exit() {
    (return 0 2>/dev/null) && return "$1" || exit "$1"
}
adb wait-for-device
adb reboot bootloader
until fastboot devices | grep -q fastboot; do
    sleep 1
done
echo "setting selinux as permissive on cmdline"
fastboot oem set-gpu-preemption 0 androidboot.selinux=permissive
fastboot continue
echo "waiting for adb..."
adb wait-for-device
echo "waiting for android boot..."
until adb shell getprop sys.boot_completed 2>/dev/null | grep -q 1; do
    sleep 1
done
echo "waiting for /data..."
until adb shell '[ -d /data/data ]' 2>/dev/null; do
    sleep 1
done
selinux=$(adb shell getprop ro.boot.selinux | tr -d '\r')
if
[ "$selinux" != "permissive" ]; then
echo "selinux enforcing, exiting"
safe_exit 0
fi
echo "loading ksu"
until adb shell '/system/bin/service call miui.mqsas.IMQSNative 21 i32 1 s16 "sh" i32 1 s16 "/data/local/tmp/ksu_step1.sh" s16 "/data/local/tmp/ksu_result.txt" i32 60'; do
sleep 1
done
until adb shell '/system/bin/service call miui.mqsas.IMQSNative 21 i32 1 s16 "sh" i32 1 s16 "/data/local/tmp/ksu_step2.sh" s16 "/data/local/tmp/ksu_result.txt" i32 60'; do
sleep 1
done
echo "ksu loaded, loading lspd (device will softboot don't panic)"
sleep 3
until adb shell '/system/bin/service call miui.mqsas.IMQSNative 21 i32 1 s16 '/system/bin/sh' i32 1 s16 '/data/local/tmp/fix_lspd.sh' s16 '/data/local/tmp/lspd_fix_out.txt' i32 180'; do
sleep 1
done
