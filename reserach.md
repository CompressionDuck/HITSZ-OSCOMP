[不上班行不行](https://www.cnblogs.com/startkey/p/10678173.html)

[[差量更新系列1\]BSDiff算法学习笔记_add_ada的博客-CSDN博客_bsdiff算法原理](https://blog.csdn.net/add_ada/article/details/51232889)

# （1）BSDiff算法包含哪些基本步骤？

**步骤1.**是所有差量更新算法的瓶颈，时间复杂度为O(nlogn),空间复杂度为O(n)，n为old文件的长度。BSDiff采用 Faster suffix sorting方法获得一个字典序，使用了类似于快速排序的二分思想，使用了bucket，I，V三个辅助数组。最终得到一个数组I，记录了以前缀分组的各个字符串组的最后一个字符串在old中的开始位置

**步骤2.**是BSDiff产生patch包的核心部分，详细描述如下：

![1](https://img-blog.csdn.net/20160424124812650?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

![2](https://img-blog.csdn.net/20160424124859572?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

![3](https://img-blog.csdn.net/20160424125102547?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

**步骤3.**将diff string 和extrastring 以及相应的控制字用zip压缩成一个patch包。

![4](https://img-blog.csdn.net/20160424125148292?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

可以看出在用zip压缩之前的patch包是没有节约任何字符的，但diff strings可以被高效的压缩，故BSDiff是一个很依赖于压缩与解压的算法！

# （2）BSDiff算法的时间、空间复杂度分别是？并据此推断该算法的瓶颈；

BSDiff

时间复杂度 O(nlogn) 空间复杂度 O(n)

BSPatch

时间复杂度 O(n+m)  空间复杂度 O(n+m)

字典序排序算法

压缩算法

# （3）为什么BSDiff算法不适用于压缩文件的差分以及小内存设备？

压缩文件的结构依赖于不同的压缩算法, 压缩文件的new和old文件有重复的部分可能较少

bsdiff算法会产生较大的空间占用

# （4）目前是否存在适用于压缩文件和小内存设备的差分算法？它们和BSDiff算法相比，做了哪些改进？

[一种小内存设备系统升级的差分算法的制作方法](http://www.xjishu.com/zhuanli/55/201811416681.html)

# （5）尝试提出BSDiff算法的优化思路和优化方法；

找更好的压缩算法

字典排序更好

[More on bsdiff and delta compression](http://richg42.blogspot.com/2015/11/more-on-bsdiff.html)

# （6）出错回滚的原理、常用方法分别是？对比这些方法的优缺点。

[数据库原理--第十章：数据库恢复技术](https://godway.work/2019/06/17/Database10/)

[『浅入深出』MySQL 中事务的实现 - 面向信仰编程](https://draveness.me/mysql-transaction/)

方法1：数据转储（俗称备份）

定期将系统复制到其他存储介质上保存起来。转储操作十分耗费时间和资源，不能频繁进行

转储可以分为静态转储和动态转储

- 静态转储：在操作系统没有进程运行时进行的转储操作，转储期间不能对操作系统有任何的修改。
	- 得到的是一个一致性副本
	- 不能热插拔
- 动态转储：转储期间允许操作系统进行操作
	- 必须把转储期间操作系统进行的活动记录下来，建立日志文件

方法2：日志文件

对于以记录为单位的日志文件，其需要登记的内容包括：

- 各个事务的开始标记
- 各个事务的结束标记
- 各个事务的所有更新操作

日志文件的作用：

- 事务故障恢复和系统故障恢复必须用日志文件
- 在动态转储方式中必须建立日志文件，后备副本和日志文件结合起来才能有效的恢复数据库
- 在静态转储中也可以建立日志文件，用于加速数据库恢复过程

为保证数据库是可恢复的，登记日志文件的两条原则：

- **登记的次序严格按并发事务执行的时间次序**
- **必须先写日志文件，后写数据库**

恢复：UNDO list和REDO list， 时间戳

升级之前进行备份。将patch包的升级过程记录下来