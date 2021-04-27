# /bin/sh

file=log

# clear file
echo "" > $file

log_buf_size=$((8*1024*1024)) # 8M

# clear OS boot info
dmesg --clear

# grab zram_swap info
while true; do
    # Don't show time, read log and clear it, set buffer size = 8M
    dmesg --read-clear --notime --buffer-size $log_buf_size >> $file
    du -sh $file
    sleep 0.01
done
