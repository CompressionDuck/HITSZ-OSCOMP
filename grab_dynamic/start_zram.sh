# /bin/sh
if [ $(whoami) != "root" ];then
	printf "please run by sudo!\n"
	exit 1
fi

if [ -n "$(swapon -s | grep zram0)" ]; then
	swapoff /dev/zram0
fi

if [ -n "$(swapon -s | grep swapfile)" ]; then
	swapoff /swapfile
fi

printf "List all swap devices:\n\n"

if [ -n "$(swapon -s)" ]; then
	swapon -s
	printf "\n### please swapoff all above devices! ###\n"
	printf "so we can use zram as the only swap device\n"
	printf "example: sudo swapoff /swapfile\n"
	
	exit 1
else
	printf "good. There is no swap device.\n"
fi

printf "\n### enable zram device as the only swap device ###\n\n"
# modprobe -v zram num_devices=1

if [ -n "$(lsmod | grep zram)" ]; then
	rmmod zram;
fi

insmod ./zram.ko

zramctl -f -s 1G

mkswap /dev/zram0
swapon /dev/zram0

sysctl vm.swappiness=100

printf "\n### zram has started! ###\n"
zramctl

