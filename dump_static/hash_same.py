#! /usr/bin/env python

import hashlib
import os
import concurrent.futures

data_path = "./data_divide"

# 字典保存相同page哈希值的次数，也就是page完全相同的次数
d = dict()
cnt = 0
# ls -lR |grep "^-"|wc -l
cmd_tot = "ls -lR " + data_path + " |grep \"^-\"|wc -l"
tot = int(os.popen(cmd_tot).readlines()[0])
print("一共%d个页" %tot)

for root, dirs, pages in os.walk(data_path):
    # 如果进入了进程号文件夹，那么会有一堆pages
    if pages:
        for page in pages:
            cnt = cnt + 1   # 保存一共有多少个page
            if cnt % 10000 == 0:
                print("已处理%d个页，共计%.2f%%" %(cnt, float(cnt)/tot*100))

            # 使用sha256计算每个page的哈希值ha
            sha = hashlib.sha256()
            with open(root + '/' + page,'rb') as p:
                for line in p:
                    sha.update(line)
            ha = sha.hexdigest()

            if ha in d:
                d[ha] = d[ha] + 1
            else:
                d[ha] = 1

# key:多少page相同，value=出现次数
# 如{3:20}代表，三个页面相同的，出现了20次
times_cnt = dict()
for ha, times in d.items():
    if times > 1:
        if times in times_cnt:
            times_cnt[times] = times_cnt[times] +1
        else:
            times_cnt[times] = 1

print("总共%d个页" %cnt)
if times_cnt:
    out_file = open("hash.result", 'w')
    same_list = sorted(times_cnt.keys())
    same_list.reverse()
    for same in same_list:
        out_file.write(f"出现了{same_list[same]:5d}次，{same:9d}个页面相同的情况\n")
        # print("%2d个页面相同的，出现了%4d次" %(same, times))
else:
    print("没有一个页面相同。。。")
