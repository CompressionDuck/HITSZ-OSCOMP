# /bin/sh

# clear dmesg_log
echo "" > dmesg_log

log_buf_size = $((8*1024*1024)) # 8M
while true; do
    # show realtime, read log and clear it, set buffer size = 8M
    dmesg --read-clear --reltime --buffer-size $log_buf_size >> dmesg_log
done