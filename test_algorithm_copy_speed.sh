if [[ `whoami` != "root" ]];then
        printf "please run by root!(sudo)\n"
        exit
fi

if [[ `lsmod | grep zram | wc -l` -eq 0 ]];then
	modprobe -v zram
	echo 0 > /sys/class/zram-control/hot_remove
fi

id=`sudo cat /sys/class/zram-control/hot_add`
device=zram$id
device_dir=/dev/zram$id
mount_dir=/mnt/zram$id

printf "create zram device %s\n" $device
cat /sys/block/$device/comp_algorithm
read -p "input the zram algorithm: " alg
res_file=./${alg}.speed

sudo zramctl -f -s 2G -a $alg
printf "all zram devices are:\n"
zramctl
mkdir -p $mount_dir
mkfs.ext4 $device_dir
mount $device_dir $mount_dir

read -p "input your test file directory path (directory size < 2G): " test_file
printf "copying $test_file to zram%i, please wait for a minute...\n" ${id}
{ time cp -r $test_file $mount_dir/; } 2>>$res_file
printf "#################\ndone! time use is stored in %s\n" $res_file
sync
zramctl > $res_file
umount $mount_dir
echo $id > /sys/class/zram-control/hot_remove
