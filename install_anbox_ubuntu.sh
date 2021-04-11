if [ `whoami` != "root" ];then
	printf "run in root!(sudo)\n"
	exit
fi
add-apt-repository ppa:morphis/anbox-support
apt install -y anbox-modules-dkms
modprobe ashmem_linux
modprobe binder_linux
snap install --devmode --beta anbox
