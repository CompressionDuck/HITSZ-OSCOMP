#! /usr/bin/env python
import re
import sys

if len(sys.argv) == 1:
    pid = "self"
else :
    pid = sys.argv[1]

out_name = pid + ".dump"
print("正在打印程序号为%s的所有匿名页数据：" %pid)

maps_file = open("/proc/"+pid+"/maps", 'r')
mem_file = open("/proc/"+pid+"/mem", 'rb', 0)
# out_file = open(out_name, 'wb')
file_has_data=False
for line in maps_file.readlines():  # for each mapped region
    m = re.match(r'([0-9A-Fa-f]+)-([0-9A-Fa-f]+) ([-r])', line)
    list_line = line.split()
    if (len(list_line)<6) and (m.group(3) == 'r'):  # if this is a anoumous page and readable region
        # 如果该程序有数据需要打印，则创建文件
        if file_has_data==False:
            out_file = open(out_name, 'wb')
            file_has_data = True
        start = int(m.group(1), 16)
        end = int(m.group(2), 16)
        mem_file.seek(start)  # seek to region start
        chunk = mem_file.read(end - start)  # read region contents
        # print(line)
        # out_file.write(str.encode(line))  # 输出起始地址
        out_file.write(chunk)               # 输出4K大小的匿名页数据
        # out_file.write(str.encode('\n'))  # 输出一个换行符，隔开匿名页
maps_file.close()
mem_file.close()
if file_has_data:   
    out_file.close()
    print("完成！数据保存在 %s 文件夹下\n" %(out_name))
else:
    print(f"{pid}没有可打印的匿名页数据")
