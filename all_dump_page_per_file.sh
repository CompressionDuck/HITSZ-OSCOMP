# /bin/sh
if [ `whoami` != "root" ];then
        printf "please run by root!(sudo)\n"
        exit 1
fi

res_path=./anony_data_page_per_file

mkdir -p $res_path
cd $res_path

cnt=0

#对于/proc下的每个目录
for i in $(ls /proc);do
      #选择数字目录，代表程序pid
    if echo $i | grep [0-9]; then
        python3 ../dump_page_per_file.py $i
        if [ $? -eq 0 ];then
            cnt=$((cnt + 1))
        fi
    fi
done

printf "\n一共打印了%s个程序的匿名页数据\n所有数据保存在%s目录下\n" $cnt $res_path
