# HITSZ-OSCOMP

## 资料收集

[赛道信息](https://github.com/oscomp/proj64-linux-anony-page-compression)

## 看板

选择了[飞书文档](https://dgool05s1u.feishu.cn/sheets/shtcnn31Uu3GYhXZNMbwsDB9dcd?from=from_copylink)。

## 测试
运行grab_dynamic文件夹下的auto_grab.sh。直接配置好zram作为swap分区，并运行grab.sh。如果开启swapfile，需要关闭swapfile

打开Ubuntu下的系统监控器，在资源选项卡下能看到swap占用情况

然后，运行test_swap文件夹下的a.out。此文件由fill_mem.c编译而来，编译命令为：
gcc fill_mem.c
此文件每隔0.2s分配1M空间，会迅速占满内存，当内存满后，继续分配的数据将进入交换区swap中，此时开启了grab.sh，那么会抓取数据到result中

## 问题
以上测试过程中，swap分区已经600M了，但是result才几十M。
可能猜测的问题：demsg显示，它把旧的printk内容删除了，可能是grab.sh命令太慢的原因。但是将grab.sh的sleep改为0.001s，任然有这个问题


## 说明
|文件夹|说明|
|---|---|
|dump_static|存放读取程序静态匿名页数据的脚本|
|grab_dynamic|存放读取OS动态换出匿名页的脚本|
|install_anbox_ubuntu.sh|在Ubuntu下安装安卓模拟器anbox的脚本|
|test_algorithm_copy_speed.sh|测试当前内核所支持所有压缩算法，将文件压缩进入zram磁盘的速度、压缩比|

|dump_static/|说明|
|---|---|
|dump.py|导出单个程序pid的匿名页|
|all_dump.sh|调用dump.py，导出所有程序的匿名页|
|divide_dump.py|按照一页一文件，打印单个程序的匿名页|
|divide_all_dump.sh|调用divide_dump.py，按照一页一文件，打印所有程序的匿名页|

|grab_dynamic/|说明|
|---|---|
|zram.ko|修改后的zram模块，将OS动态换出的匿名页打印到dmesg|
|grab.sh|读取dmesg，将二进制转换为十六进制输出到result文件|
|auto_grab.sh|自动启动zram模块，使用默认zram配置，调用grab.sh|


