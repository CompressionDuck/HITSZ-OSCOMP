#! /usr/bin/env python
import re
import sys
import os


if len(sys.argv) == 1:
    pid = "self"
else :
    pid = sys.argv[1]


print("正在打印程序号为%s的所有匿名页数据：" %pid)

maps_file = open("/proc/"+pid+"/maps", 'r')
mem_file = open("/proc/"+pid+"/mem", 'rb', 0)
dir_path = pid
os.makedirs(dir_path, exist_ok=True)
os.chdir(dir_path)
cnt = 0
page_size = 4*1024
for line in maps_file.readlines():  # for each mapped region
    m = re.match(r'([0-9A-Fa-f]+)-([0-9A-Fa-f]+) ([-r])', line)
    list_line = line.split()
    if (len(list_line)<6) and (m.group(3) == 'r'):  # if this is a anoumous page and readable region
        start = int(m.group(1), 16)
        end = int(m.group(2), 16)
        mem_file.seek(start)  # seek to region start
        
        
        while start < end:
            chunk = mem_file.read(page_size)  # read region contents
            cnt = cnt + 1
            out_name = f'{cnt}.page'
            out_file = open(out_name, 'wb')
            # print(line)
            # out_file.write(str.encode(line))  # 输出起始地址
            out_file.write(chunk)               # 输出4K大小的匿名页数据
            # out_file.write(str.encode('\n'))  # 输出一个换行符，隔开匿名页
            out_file.close()
            start += page_size
        
        
        
maps_file.close()
mem_file.close()
os.chdir("../")
if cnt > 0:
    print("成功！一共打印了%d个页，结果保存在%s\n" %(cnt, dir_path))
    exit(0)
else:
    print("无数据。该程序无匿名页数据\n")
    exit(1)
