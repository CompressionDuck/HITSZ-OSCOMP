#! /usr/bin/env python
import re
try:
    pid = input("please input the pid you want to show its anoumous page:(dafault self):")
except: #input nothing
    pid = "self"

output_file_name = "data"
print(output_file_name)
maps_file = open("/proc/"+str(pid)+"/maps", 'r')
mem_file = open("/proc/"+str(pid)+"/mem", 'rb', 0)
output_file = open(output_file_name, 'wb')
for line in maps_file.readlines():  # for each mapped region
    m = re.match(r'([0-9A-Fa-f]+)-([0-9A-Fa-f]+) ([-r])', line)
    list_line = line.split()
    if (len(list_line)<6) and (m.group(3) == 'r'):  # if this is a anoumous page and readable region
        start = int(m.group(1), 16)
        end = int(m.group(2), 16)
        print(line)
        mem_file.seek(start)  # seek to region start
        chunk = mem_file.read(end - start)  # read region contents
        output_file.write(line)
        output_file.write(chunk)  # dump contents to standard output
        output_file.write('\n')
maps_file.close()
mem_file.close()
output_file.close()
print("done! All infomation is saved in %s" %(output_file_name))
