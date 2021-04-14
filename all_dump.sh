# /bin/sh
if [ `whoami` != "root" ];then
        printf "please run by root!(sudo)\n"
        exit 1
fi

res_path=./anony_data

mkdir $res_path
cd $res_path
cnt=0
for i in $(ls /proc)
do
    if echo $i | grep [0-9]; then
        mkdir ./$i -p
        cd ./$i
        python3 ../../dump.py $i
        if [ $? -eq 0 ]
        then
            cnt=$((cnt + 1))
        fi
        cd ..
    fi
done

printf "\n一共打印了%s个程序的匿名页数据\n所有数据保存在%s目录下\n" $cnt $res_path