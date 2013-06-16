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

echo "$int_scheduler" > /sys/block/mmcblk0/queue/scheduler
echo "$int_read_ahead_kb" > /sys/block/mmcblk0/bdi/read_ahead_kb
echo "$ext_scheduler" > /sys/block/mmcblk1/queue/scheduler
echo "$ext_read_ahead_kb" > /sys/block/mmcblk1/bdi/read_ahead_kb


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