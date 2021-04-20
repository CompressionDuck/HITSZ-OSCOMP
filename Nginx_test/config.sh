if [ $(whoami) != "root" ];then
	printf "run by sudo!\n"
	exit 1
fi


# 最大连接数
echo 50000 > /proc/sys/net/core/somaxconn

# 禁止洪水抵御
echo 0 > /proc/sys/net/ipv4/tcp_syncookies

# 使空的 tcp 连接重新被利用
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse

# 设置同一个文件同一时间点可以打开 N 次
ulimit -n 20000

# 参数决定了SYN_RECV状态队列的数量，一般默认值为512或者1024，即超过这个数量，系统将不再接受新的TCP连接请求，一定程度上可以防止系统资源耗尽。可根据情况增加该值以接受更多的连接请求。
echo 10240 > /proc/sys/net/ipv4/tcp_max_syn_backlog


