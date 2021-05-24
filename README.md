# 操作系统大赛——功能设计赛道

| 赛队名                     | 压缩鸭                                                       |
| -------------------------- | ------------------------------------------------------------ |
| 所选赛题号                 | 64                                                           |
| 所选赛题链接               | https://github.com/oscomp/proj64-linux-anony-page-compression |
| 是否与赛题指导老师取得联系 | 是，暂时共计咨询了6次                                        |
| 目前作品进展情况           | 1. 已经得出四种生产环境匿名页数据，使用lzbench测速<br />2. 页面分类后对三种匿名页进行lzbench测压缩性能，发现三种匿名页lz4都是压缩速率最快的<br />3. 使用sha1计算页面摘要来去重，已经实现但是还有bug |
| 预计作品提交时间           | 初赛截止前会尽力debug，争取做出一版没有bug的哈希去重算法     |

## 飞书文档

[飞书文档链接](https://dgool05s1u.feishu.cn/docs/doccnLzlXxf0JhIrM60NHJBYN2d)


## 文件说明

| 文件夹                  | 文件名 | 说明                                |
| ----------------------- | ------ | ----------------------------------- |
| dump_static/           |        | 读取程序静态申请的匿名页                                     |
| | hash_same.py       | 分析某个文件夹下所有匿名页有多少页面sha256哈希后摘要相同 |
| | dump.py            | 导出单个程序pid的申请的匿名页                            |
| | all_dump.sh | 调用dump.py，导出OS下所有程序申请的匿名页 |
| | divide_dump.py     | 按照一页一文件，打印单个程序的匿名页                     |
|                         | divide_all_dump.sh | 调用divide_dump.py，按照一页一文件，打印所有程序的匿名页 |
| grab_dynamic            |        | 读取OS动态换出的匿名页              |
|  | grab.sh | 调大内核log缓冲区，不间断读取log，依然有bug |
|  | grab.sh.bug | 读取dmesg，将二进制转换为十六进制输出到result文件，有bug |
|  | start_zram.sh | 启动zram，格式化为swap分区，作为swap |
| Nginx_test              |        | 配置Nginx环境，并测试               |
|  | config.sh | 配置Nginx，最大限度提高并发量 |
|  | loop_test.sh | 死循环不断使用压力测试工具ab测试Nginx |
| test_swap               |        | 测试swap分区                                                 |
|  | fill_mem.c | 逐渐申请占用指定内存 |
|  | zram_copy_test.sh | 测试当前内核所支持所有压缩算法，将文件压缩进入zram磁盘的速度、压缩比 |
| install_anbox_ubuntu.sh |  | 在Ubuntu下安装安卓模拟器anbox的脚本 |

