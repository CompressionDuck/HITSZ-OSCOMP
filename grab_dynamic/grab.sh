# /bin/sh

file=log
# clear dmesg_log
echo "" > $file

log_buf_size=$((8*1024*1024)) # 8M
    
# show realtime, read log and clear it, set buffer size = 8M
dmesg --read-clear --notime --buffer-size=$log_buf_size --follow >> $file

