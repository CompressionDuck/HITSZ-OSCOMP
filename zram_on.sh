# /bin/sh
if [ $(whoami) != "root" ];then
	printf "please run by sudo!\n"
	exit 1
fi

rmmod zram
modprobe zram num_devices=1
echo 1G > /sys/block/zram0/disksize

mkswap /dev/zram0
swapon /dev/zram0
