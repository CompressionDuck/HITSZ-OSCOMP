# /bin/sh
if [ $(whoami) != "root" ];then
	printf "please run by sudo!\n"
	exit 1
fi

modprobe -v zram num_devices=1
echo 1G > /sys/block/zram0/disksize

mkswap /dev/zram0
if [ "$?" != "0" ];then
	printf "mkswap error\n"
	exit 1
fi

# set priority = 0, > -2 of the /swapfile
# so zram0 will be used before /swapfile
swapon -p 0 /dev/zram0

# let OS be most willing to use swap 
sysctl vm.swappiness=100

printf "\n### zram has started! ###\n"
