# Chapter1-系统虚拟化概述

## 系统虚拟化

所谓虚拟化，就是虚拟化一个接口。例如，想要在linux上运行windows的应用，则需要在linux上有一套符合windows的系统调用接口才能正常运行。而操作系统的接口有很多层次，虚拟化哪一层接口是需要我们考虑的事情。

操作系统的接口分为以下几层：

### ISA\(Instruction Set Architecture\)

即通常所说的指令集架构，有以**x86**为代表的CISC架构，以及以**MIPS**，**ARM**，**RISC-V**。从下图可以看到，ISA位于硬件和操作系统中间。ISA又分为用户的ISA和系统的ISA，这两者的区别在于，系统的ISA只能被内核使用，而用户ISA可以被用户以及内核使用。

例如修改中断控制向量表这条指令，很明显不能让用户使用。

```text
msr vbar_el1, x0
```

用户态程序可以使用的指令，例如

```text
mov x0, sp
```

![](.gitbook/assets/image%20%282%29.png)

### ABI\(Application Binary Interface\)

提供操作系统服务或硬件功能，包含用户ISA和系统调用

![](.gitbook/assets/image%20%283%29.png)

以windows+x86为例，x86（ISA）和windows提供的系统调用共同组成了一个**ABI**。只要保证ABI相同，应用就可以在不同的操作系统上运行。例如想要在linux上运行windows应用，就需要模拟出**ABI**。

### API\(Application Programming Interface\)

![](.gitbook/assets/image%20%284%29.png)

不同的用户态库提供的接口，包含库的接口和用户ISA。详情请看[百科](https://zh.wikipedia.org/wiki/%E5%BA%94%E7%94%A8%E7%A8%8B%E5%BA%8F%E6%8E%A5%E5%8F%A3)

## 如何定义虚拟化

ISA提供了操作系统和Machine之间的界限。

![](.gitbook/assets/image%20%285%29.png)

虚拟化的本质就是在现有的机器的ISA（包括系统ISA和用户ISA）的基础上，利用底层的系统ISA和用户ISA（这意味着其有最高的权限），向上提供多个系统ISA和用户ISA，让上层软件以为自己运行在真实的物理主机上。系统虚拟化技术的核心是虚拟机监控器。

{% hint style="info" %}
虚拟机监控器与操作系统有许多类似的地方：运行在最底层以管理软件，支持上层软件复用硬件资源。两者的一个重要区别在于：操作系统会为硬件定义新的“抽象”，其体现为新的软件接口；而虚拟机监控器并不引入新的接口，只有对已有硬件接口的“虚拟化”。例如，操作系统将对次满的操作抽象为对文件的操作，向上提供不同于磁盘接口的文件系统接口；虚拟机监控器则可以把一个（或多个）文件虚拟成一个磁盘，对上层的客户操作系统提供磁盘的接口（如IDE，SATA）。
{% endhint %}

{% hint style="info" %}
名词解释：

客户机（Guest Machine）：即虚拟机，在vmware中的各个虚拟机就叫做客户机

宿主机（Host Machine）：虚拟机对应的物理主机

虚拟机监控器\(**V**irtual **M**achine **M**onitor, **VMM**, **Hypervisor**\)
{% endhint %}

### 高效系统虚拟化的三个特性

* 为虚拟机内程序提供与该程序原先执行的硬件**完全一样的接口**
* 虚拟机只比无虚拟化的情况下**性能略差一点**
* 虚拟机监控器**控制所有物理资源**

## 

