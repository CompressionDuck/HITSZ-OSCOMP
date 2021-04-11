#! /usr/bin/env python
import re
import sys

if len(sys.argv) == 1:
    pid = "self"
else :
    pid = sys.argv[1]

out_name = pid + ".dump"
print("get %s anomynous data:" %pid)

maps_file = open("/proc/"+pid+"/maps", 'r')
mem_file = open("/proc/"+pid+"/mem", 'rb', 0)
out_file = open(out_name, 'wb')
for line in maps_file.readlines():  # for each mapped region
    m = re.match(r'([0-9A-Fa-f]+)-([0-9A-Fa-f]+) ([-r])', line)
    list_line = line.split()
    if (len(list_line)<6) and (m.group(3) == 'r'):  # if this is a anoumous page and readable region
        start = int(m.group(1), 16)
        end = int(m.group(2), 16)
        mem_file.seek(start)  # seek to region start
        chunk = mem_file.read(end - start)  # read region contents
        print(line)
        out_file.write(str.encode(line))
        out_file.write(chunk)  # dump contents to standard output
        out_file.write(str.encode('\n'))
maps_file.close()
mem_file.close()
out_file.close()
print("done! All infomation is saved in %s" %(out_name))
