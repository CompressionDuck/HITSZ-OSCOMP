# /bin/sh
if [ `whoami` != "root" ];then
        printf "please run by root!(sudo)\n"
        exit 1
fi

mkdir ./res
cd res
for i in $(ls /proc)
do
    if echo $i | grep [0-9]; then
        mkdir ./$i -p
        cd ./$i
        python3 ../../dump.py $i
        cd ..
    fi
done
