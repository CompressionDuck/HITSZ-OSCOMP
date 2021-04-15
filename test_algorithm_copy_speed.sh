# script should run in root!
if [ `whoami` != "root" ];then
        printf "please run by root!(sudo)\n"
        exit 1
fi

# input the test dir as argument
if [ $# != 1 ]; then
	printf "only input %d argument\n" $#
	printf "usage: sudo sh ***.sh /you/test/compress/path\n" 
	exit 1
fi

test_dir=$1
# printf "you input path:%s\n" $test_dir
if [ ! -d $test_dir ]; then
	printf "path: %s not exist\n" $test_dir
	exit 1
fi

dir_size=$(du -s $test_dir | awk '{print $1}')
twoG=$((2*1024*1024))
if [ $dir_size -gt $twoG ]; then
	printf "path %s size > 2G!\n" $test_dir
	exit 1
fi

# modprobe zram
if [ `lsmod | grep zram | wc -l` -eq 0 ];then
	modprobe -v zram num_devices=0	
fi

if [ $? != 0 ]; then
	exit 1
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
while [ -z "$alg" ];do
	read -p "you don't input anything, input the zram algorithm: " alg
done

res_file=./${alg}.speed

# find a empty zram device, set its disk size=2G, use $alg as algorithm
printf "\ncreat zram block device:\n"
sudo zramctl --find --size 2G --algorithm $alg 

printf "all zram devices are:\n"
zramctl

# let block device zram$id be a file system
mkdir -p $mount_dir

mkfs.ext4 $device_dir > /dev/null
if [ $? != 0 ]; then
	printf "error on mkfs.ext4\n"
	exit 1
fi

mount $device_dir $mount_dir

# add zram status to result
zramctl > $res_file
echo "" >> $res_file

printf "\ncopying $test_dir to zram%i, please wait for a minute...\n" ${id}
(time cp -r $test_dir $mount_dir) >> $res_file 2>&1
printf "##### done! time use is stored in %s #####\n" $res_file
sync

# umount and remove zram device
umount $mount_dir
echo $id > /sys/class/zram-control/hot_remove
