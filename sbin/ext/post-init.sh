#!/sbin/busybox sh
# Logging
#/sbin/busybox cp /data/user.log /data/user.log.bak
#/sbin/busybox rm /data/user.log
#exec >>/data/user.log
#exec 2>&1

mkdir /data/.siyah
chmod 777 /data/.siyah

. /res/customconfig/customconfig-helper

ccxmlsum=`md5sum /res/customconfig/customconfig.xml | awk '{print $1}'`
if [ "a${ccxmlsum}" != "a`cat /data/.siyah/.ccxmlsum`" ];
then
  rm -f /data/.siyah/*.profile
  echo ${ccxmlsum} > /data/.siyah/.ccxmlsum
fi
[ ! -f /data/.siyah/default.profile ] && cp /res/customconfig/default.profile /data/.siyah

read_defaults
read_config
insmod /lib/modules/logger.ko

#cpu min & max frequencies
echo "${scaling_min_freq}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo "${scaling_max_freq}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

#cpu undervolting
echo "${cpu_undervolting}" > /sys/devices/system/cpu/cpu0/cpufreq/vdd_levels

##### GGY Swap #####

#  `expr $zram_size \* 1024 \* 1024`
  
if [ "$zram_switch" == "on" ];then

  echo `expr $zram_swappiness \* 1` > /proc/sys/vm/swappiness
  swapoff /dev/block/zram0 > /dev/null 2>&1
  echo 1 > /sys/devices/virtual/block/zram0/reset
  echo `expr $zram_size \* 1024 \* 1024` > /sys/devices/virtual/block/zram0/disksize
  echo `expr $zram_swappiness \* 1` > /proc/sys/vm/swappiness
  mkswap /dev/block/zram0 > /dev/null 2>&1
  swapon /dev/block/zram0 > /dev/null 2>&1
  
#    chmod 0600 /sys/block/zram0/disksize
#    chown system system /sys/block/zram0/disksize
#    echo "${zram_size}" > /sys/block/zram0/disksize
#    write /sys/block/zram0/disksize 419430400
#    chmod 0600 /sys/block/zram0/initstate
#    chown system system /sys/block/zram0/initstate
#    write /sys/block/zram0/initstate 1
#    mkdir /dev/memcgrp 
#    mount cgroup none /dev/memcgrp memory
#    chmod 0700 /dev/memcgrp
#    chown system system /dev/memcgrp
#    mkdir /dev/memcgrp/hidden
#    chmod 0700 /dev/memcgrp/hidden
#    chown system system /dev/memcgrp/hidden
#    chown system system /dev/memcgrp/tasks
#    chown system system /dev/memcgrp/hidden/tasks
#    chmod 0600 /dev/memcgrp/tasks
#    chmod 0600 /dev/memcgrp/hidden/tasks
#    echo "${zram_swappiness}" > /dev/memcgrp/hidden/memory.swappiness
#    write /dev/memcgrp/hidden/memory.swappiness 80
#    write /dev/memcgrp/hidden/memory.soft_limit_in_bytes 0
#    write /proc/sys/vm/page-cluster 1
#  mkswap /dev/block/zram0
#  swapon /dev/block/zram0 
fi


if [ "$zram_switch" == "off" ];then

        swapoff /dev/block/zram0 > /dev/null 2>&1
	umount /dev/block/zram0 > /dev/null 2>&1
	umount /dev/block/zram1 > /dev/null 2>&1
	
fi

##### GGY Swap end #####

echo "${int_scheduler}" > /sys/block/mmcblk0/queue/scheduler
echo "${int_read_ahead_kb}" > /sys/block/mmcblk0/bdi/read_ahead_kb
echo "${ext_scheduler}" > /sys/block/mmcblk1/queue/scheduler
echo "${ext_read_ahead_kb}" > /sys/block/mmcblk1/bdi/read_ahead_kb


##### GGY TouchWake #####

#if [ "$touchwake" == "on" ];then
#echo 1 > /sys/devices/virtual/misc/touchwake/enabled
#fi

#if [ "$touchwake" == "off" ];then
#echo 0 > /sys/devices/virtual/misc/touchwake/enabled
#fi

##### GGY TouchWake end #####

#mdnie sharpness tweak
if [ "$mdniemod" == "on" ];then
. /sbin/ext/mdnie-sharpness-tweak.sh
fi

if [ "$logger" == "on" ];then
insmod /lib/modules/logger.ko
fi

# disable debugging on some modules
if [ "$logger" == "off" ];then
  rm -rf /dev/log
  echo 0 > /sys/module/ump/parameters/ump_debug_level
  echo 0 > /sys/module/mali/parameters/mali_debug_level
  echo 0 > /sys/module/kernel/parameters/initcall_debug
  echo 0 > /sys//module/lowmemorykiller/parameters/debug_level
  echo 0 > /sys/module/earlysuspend/parameters/debug_mask
  echo 0 > /sys/module/alarm/parameters/debug_mask
  echo 0 > /sys/module/alarm_dev/parameters/debug_mask
  echo 0 > /sys/module/binder/parameters/debug_mask
  echo 0 > /sys/module/xt_qtaguid/parameters/debug_mask
fi

# boeffla sound
#echo "1" > /sys/class/misc/boeffla_sound/boeffla_sound
#echo "${headphone_volume} ${headphone_volume}" > /sys/class/misc/boeffla_sound/headphone_volume
#echo "${speaker_volume} ${speaker_volume}" > /sys/class/misc/boeffla_sound/speaker_volume
#echo "${privacy_mode}" > /sys/class/misc/boeffla_sound/privacy_mode
#echo "${}" > /sys/class/misc/boeffla_sound/eq
#echo "12 8 3 -1 1" > /sys/class/misc/boeffla_sound/eq_gains
#echo "${}" > /sys/class/misc/boeffla_sound/dac_direct
#echo "${}" > /sys/class/misc/boeffla_sound/dac_oversampling
#echo "${}" > /sys/class/misc/boeffla_sound/fll_tuning
#echo "${}" > /sys/class/misc/boeffla_sound/stereo_expansion
#echo "${}" > /sys/class/misc/boeffla_sound/mono_downmix
#echo "${}" > /sys/class/misc/boeffla_sound/mic_level_general
#echo "${}" > /sys/class/misc/boeffla_sound/mic_level_call

# for ntfs automounting
insmod /lib/modules/fuse.ko
mount -o remount,rw /
mkdir -p /mnt/ntfs
chmod 777 /mnt/ntfs
mount -o mode=0777,gid=1000 -t tmpfs tmpfs /mnt/ntfs
mount -o remount,ro /

/sbin/busybox sh /sbin/ext/install.sh

##### Early-init phase tweaks #####
/sbin/busybox sh /sbin/ext/tweaks.sh

/sbin/busybox mount -t rootfs -o remount,ro rootfs

##### EFS Backup #####
(
/sbin/busybox sh /sbin/ext/efs-backup.sh
) &

# apply STweaks defaults
export CONFIG_BOOTING=1
/res/uci.sh apply
export CONFIG_BOOTING=


##### init scripts #####
/sbin/busybox sh /sbin/ext/run-init-scripts.sh

##### ABB settings #####

echo $arm_slice_1_volt > /sys/devices/system/abb/arm/arm_slice_1_volt
echo $arm_slice_2_volt > /sys/devices/system/abb/arm/arm_slice_2_volt
echo $arm_slice_3_volt > /sys/devices/system/abb/arm/arm_slice_3_volt
echo $arm_slice_4_volt > /sys/devices/system/abb/arm/arm_slice_4_volt

echo $g3d_slice_1_volt > /sys/devices/system/abb/g3d/g3d_slice_1_volt
echo $g3d_slice_2_volt > /sys/devices/system/abb/g3d/g3d_slice_2_volt
echo $g3d_slice_3_volt > /sys/devices/system/abb/g3d/g3d_slice_3_volt

echo $mif_slice_1_volt > /sys/devices/system/abb/mif/mif_slice_1_volt
echo $mif_slice_2_volt > /sys/devices/system/abb/mif/mif_slice_2_volt

echo $int_slice_1_volt > /sys/devices/system/abb/int/int_slice_1_volt
echo $int_slice_2_volt > /sys/devices/system/abb/int/int_slice_2_volt

##### CPU settings #####

  if [ -f $2 ];then
     if "$default_scaling_governor" == "zzmoove";then
        echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo $zzmoove_lcdfreq_enable > /sys/devices/system/cpu/cpufreq/zzmoove/lcdfreq_enable
        echo $zzmoove_lcdfreq_kick_in_cores > /sys/devices/system/cpu/cpufreq/zzmoove/lcdfreq_kick_in_cores
        echo $zzmoove_lcdfreq_kick_in_down_delay > /sys/devices/system/cpu/cpufreq/zzmoove/lcdfreq_kick_in_down_delay
        echo $zzmoove_lcdfreq_kick_in_freq > /sys/devices/system/cpu/cpufreq/zzmoove/lcdfreq_kick_in_freq
        echo $zzmoove_lcdfreq_kick_in_up_delay > /sys/devices/system/cpu/cpufreq/zzmoove/lcdfreq_kick_in_up_delay
        echo $zzmoove_down_threshold > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold
        echo $zzmoove_down_threshold_hotplug1 > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold_hotplug1
        echo $zzmoove_down_threshold_hotplug2 > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold_hotplug2
        echo $zzmoove_down_threshold_hotplug3 > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold_hotplug3
        echo $zzmoove_down_threshold_sleep > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold_sleep
        echo $zzmoove_up_threshold > /sys/devices/system/cpu/cpufreq/zzmoove/up_threshold
        echo $zzmoove_up_threshold_hotplug1 > /sys/devices/system/cpu/cpufreq/zzmoove/up_threshold_hotplug1
        echo $zzmoove_up_threshold_hotplug2 > /sys/devices/system/cpu/cpufreq/zzmoove/up_threshold_hotplug2
        echo $zzmoove_up_threshold_hotplug3 > /sys/devices/system/cpu/cpufreq/zzmoove/up_threshold_hotplug3
        echo $zzmoove_early_demand > /sys/devices/system/cpu/cpufreq/zzmoove/early_demand
        echo $zzmoove_grad_up_threshold > /sys/devices/system/cpu/cpufreq/zzmoove/grad_up_threshold
        echo $zzmoove_ignore_nice_load > /sys/devices/system/cpu/cpufreq/zzmoove/ignore_nice_load
        echo $zzmoove_smooth_up > /sys/devices/system/cpu/cpufreq/zzmoove/smooth_up
        echo $zzmoove_smooth_up_sleep > /sys/devices/system/cpu/cpufreq/zzmoove/smooth_up_sleep
     fi
     if "$default_scaling_governor" == "pegasusq";then
        echo "pegasusq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
     fi
     if "$default_scaling_governor" == "lulzactiveq";then
        echo "lulzactiveq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
     fi

chmod 0666 /sys/class/misc/wolfson_control/switch_master
chmod 0666 /sys/class/misc/wolfson_control/switch_eq_speaker
chmod 0666 /sys/class/misc/wolfson_control/speaker_boost_level
chmod 0666 /sys/class/misc/wolfson_control/speaker_left
chmod 0666 /sys/class/misc/wolfson_control/speaker_right
chmod 0666 /sys/class/misc/wolfson_control/switch_privacy_mode
chmod 0666 /sys/class/misc/wolfson_control/headphone_left
chmod 0666 /sys/class/misc/wolfson_control/headphone_right
chmod 0666 /sys/class/misc/wolfson_control/stereo_expansion
chmod 0666 /sys/class/misc/wolfson_control/switch_eq_headphone
chmod 0666 /sys/class/misc/wolfson_control/eq_hp_gain_1
chmod 0666 /sys/class/misc/wolfson_control/eq_hp_gain_2
chmod 0666 /sys/class/misc/wolfson_control/eq_hp_gain_3
chmod 0666 /sys/class/misc/wolfson_control/eq_hp_gain_4
chmod 0666 /sys/class/misc/wolfson_control/eq_hp_gain_5
chmod 0666 /sys/class/misc/wolfson_control/mic_level_general
chmod 0666 /sys/class/misc/wolfson_control/mic_level_camera
chmod 0666 /sys/class/misc/wolfson_control/mic_level_call
chmod 0666 /sys/class/misc/wolfson_control/switch_fll_tuning
chmod 0666 /sys/class/misc/wolfson_control/switch_oversampling
chmod 0666 /sys/class/misc/wolfson_control/switch_dac_direct
chmod 0666 /sys/class/misc/wolfson_control/switch_mono_downmix

echo 1 > /sys/class/misc/wolfson_control/switch_master

echo $speaker_boost_level > /sys/class/misc/wolfson_control/speaker_boost_level
echo $speaker_left > /sys/class/misc/wolfson_control/speaker_left
echo $speaker_right > /sys/class/misc/wolfson_control/speaker_right
echo $switch_privacy_mode > /sys/class/misc/wolfson_control/switch_privacy_mode
echo $headphone_left > /sys/class/misc/wolfson_control/headphone_left
echo $headphone_right > /sys/class/misc/wolfson_control/headphone_right
echo $stereo_expansion > /sys/class/misc/wolfson_control/stereo_expansion

if [ "$eq_selection" == "0" ];
then
case "$eq_preset" in
  0)
    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo 0 > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo 0 > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo 0 > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo 0 > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo 0 > /sys/class/misc/wolfson_control/eq_hp_gain_5
    ;;
  1)
    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo 12 > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo 8 > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo 3 > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo -1 > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo 1 > /sys/class/misc/wolfson_control/eq_hp_gain_5
    ;;
  2)
    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo 10 > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo 7 > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo 0 > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo 2 > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo 5 > /sys/class/misc/wolfson_control/eq_hp_gain_5
    ;;
  3)
    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo -5 > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo 1 > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo 0 > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo 4 > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo 3 > /sys/class/misc/wolfson_control/eq_hp_gain_5
    ;;
  4)
    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo 0 > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo 0 > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo 0 > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo -3 > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo -5 > /sys/class/misc/wolfson_control/eq_hp_gain_5
    ;;
  5)
    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo 8 > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo 3 > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo -2 > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo 3 > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo 8 > /sys/class/misc/wolfson_control/eq_hp_gain_5
    ;;
  6)
    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo 12 > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo 8 > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo 4 > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo 2 > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo 3 > /sys/class/misc/wolfson_control/eq_hp_gain_5
    ;;
  7)
    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo 10 > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo 2 > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo -1 > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo 2 > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo 10 > /sys/class/misc/wolfson_control/eq_hp_gain_5
    ;;
esac;
else
    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo $eq_hp_gain_1 > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo $eq_hp_gain_2 > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo $eq_hp_gain_3 > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo $eq_hp_gain_4 > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo $eq_hp_gain_5 > /sys/class/misc/wolfson_control/eq_hp_gain_5
fi

echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone

echo $mic_level_general > /sys/class/misc/wolfson_control/mic_level_general
echo $mic_level_camera > /sys/class/misc/wolfson_control/mic_level_camera
echo $mic_level_call > /sys/class/misc/wolfson_control/mic_level_call
echo $switch_fll_tuning > /sys/class/misc/wolfson_control/switch_fll_tuning
echo $switch_oversampling > /sys/class/misc/wolfson_control/switch_oversampling
echo $switch_dac_direct > /sys/class/misc/wolfson_control/switch_dac_direct
echo $switch_mono_downmix > /sys/class/misc/wolfson_control/switch_mono_downmix


echo $eq_sp_gain_1 > /sys/class/misc/wolfson_control/eq_sp_gain_1
echo $eq_sp_gain_2 > /sys/class/misc/wolfson_control/eq_sp_gain_2
echo $eq_sp_gain_3 > /sys/class/misc/wolfson_control/eq_sp_gain_3
echo $eq_sp_gain_4 > /sys/class/misc/wolfson_control/eq_sp_gain_4
echo $eq_sp_gain_5 > /sys/class/misc/wolfson_control/eq_sp_gain_5

echo 1 > /sys/class/misc/wolfson_control/switch_eq_speaker
