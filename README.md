# HITSZ-OSCOMP

## 资料收集

[赛道信息](https://github.com/oscomp/proj64-linux-anony-page-compression)

## 看板

选择了[飞书文档](https://dgool05s1u.feishu.cn/sheets/shtcnn31Uu3GYhXZNMbwsDB9dcd?from=from_copylink)。

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
|dump_page_per_file.py|按照一页一文件，打印单个程序的匿名页|
|all_dump_page_per_file.sh|调用dump_page_per_file.py，按照一页一文件，打印所有程序的匿名页|

|grab_dynamic/|说明|
|---|---|
|zram.ko|修改后的zram模块，将OS动态换出的匿名页打印到dmesg|
|grab.sh|读取dmesg，将二进制转换为十六进制输出到result文件|
|auto_grab.sh|自动启动zram模块，使用默认zram配置，调用grab.sh|


