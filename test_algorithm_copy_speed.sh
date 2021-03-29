# script should run in root!
if [ `whoami` != "root" ];then
        printf "please run by root!(sudo)\n"
        exit
fi

# modprobe zram
if [ `lsmod | grep zram | wc -l` -eq 0 ];then
	modprobe -v zram num_devices=0	
fi

# add a zram device
id=`sudo cat /sys/class/zram-control/hot_add`
device=zram$id
device_dir=/dev/zram$id
mount_dir=/mnt/zram$id

printf "create zram device %s\n" $device

cat /sys/block/$device/comp_algorithm
read -p "input one of the zram algorithm: " alg
# if enter empty, repeat asking
while [ "$alg"=="" ];do
	read -p "input the zram algorithm: " alg
done

res_file=./${alg}.speed

# find a empty zram device, set its disk size=2G, use $alg as algorithm
sudo zramctl --find --size 2G --algorithm $alg

printf "all zram devices are:\n"
zramctl

# let block device zram$id be a file system
mkdir -p $mount_dir
mkfs.ext4 $device_dir
mount $device_dir $mount_dir

read -p "input your test file directory path (directory size < 2G): " test_file
printf "copying $test_file to zram%i, please wait for a minute...\n" ${id}
{ time cp -r $test_file $mount_dir/; } 2>>$res_file
printf "#################\ndone! time use is stored in %s\n" $res_file
sync

# add zram status to result
zramctl > $res_file

# umount and remove zram device
umount $mount_dir
echo $id > /sys/class/zram-control/hot_remove
