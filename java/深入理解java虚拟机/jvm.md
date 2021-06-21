## jvm

### 1.内存模型以及分区，需要详细到每个区放什么？

JVM 分为堆区和栈区，还有方法区，初始化的对象放在堆里面，引用放在栈里面，class 类信息常量池（static 常量和 static 变量）等放在方法区。new:

* 方法区： 主要是存储类信息，常量池（static 常量和 static 变量），编译后的代码（字节码）等数据
* 堆： 初始化的对象，成员变量 （那种非 static 的变量），所有的对象实例和数组都要在堆上分配
* 栈： 栈的结构是栈帧组成的，调用一个方法就压入一帧，帧上面存储局部变量表，操作数栈，方法出口等信息，局部变量表存放的是 8 大基础类型加上一个应用类型，所以还是一个指向地址的指针
* 本地方法栈： 主要为 Native 方法服务
* 程序计数器： 记录当前线程执行的行号

### 2.堆里面的分区： Eden，survival （from+ to），老年代，各自的特点？

堆里面分为新生代和老生代（java8 取消了永久代，采用了 Metaspace），新生代包含 Eden+Survivor 区，survivor 区里面分为 from 和 to 区，内存回收时，如果用的是复制算法，从 from 复制到 to，当经过一次或者多次 GC 之后，存活下来的对象会被移动到老年区，当 JVM 内存不够用的时候，会触发 Full GC，清理 JVM 老年区当新生区满了之后会触发 YGC,先把存活的对象放到其中一个 Survice区，然后进行垃圾清理。 因为如果仅仅清理需要删除的对象，这样会导致内存碎片，因此一般会把 Eden 进行完全的清理，然后整理内存。 那么下次 GC 的时候，就会使用下一个 Survive，这样循环使用。 如果有特别大的对象，新生代放不下，就会使用老年代的担保，直接放到老年代里面。 因为 JVM 认为，一般大对象的存活时间一般比较久远。

### 3.对象创建方法，对象的内存分配，对象的访问定位？

new 一个对象

### 4.GC 的两种判定方法?

引用计数法： 指的是如果某个地方引用了这个对象就+1，如果失效了就-1，当为 0 就 会回收但是 JVM 没有用这种方式，因为无法判定相互循环引用（A 引用 B,B 引用 A） 的情况

引用链法： 通过一种 GC ROOT 的对象（方法区中静态变量引用的对象等-static 变 量）来判断，如果有一条链能够到达 GC ROOT 就说明，不能到达 GC ROOT 就说明可以回收

### 5.SafePoint 是什么?

比如 GC 的时候必须要等到 Java 线程都进入到 safepoint 的时候 VMThread 才能开始执行 GC

1.循环的末尾 (防止大循环的时候一直不进入 safepoint，而其他线程在等待它进入safepoint)

2.方法返回前

3.调用方法的 call 之后4.抛出异常的位置

### 6.GC 的三种收集方法： 标记清除、标记整理、复制算法的原理与特点，分别用在什么地方，如果让你优化收集方法，有什么思路？

标记清除：先标记，标记完毕之后再清除，效率不高，会产生碎片

复制算法： 分为 8： 1 的 Eden 区和 survivor 区，就是上面谈到的 YGC

标记整理： 标记完毕之后，让所有存活的对象向一端移动

### 7.GC 收集器有哪些？ CMS 收集器与 G1 收集器的特点？

并行收集器： 串行收集器使用一个单独的线程进行收集，GC 时服务有停顿时间串行收集器： 次要回收中使用多线程来执行CMS 收集器是基于“标记—清除”算法实现的，经过多次标记才会被清除

G1 从整体来看是基于“标记—整理”算法实现的收集器，从局部（两个 Region 之间）上来看是基于“复制”算法实现的

### 8.Minor GC 与 Full GC 分别在什么时候发生？

新生代内存不够用时候发生 MGC 也叫 YGC，JVM 内存不够的时候发生 FGC

### 9. 几种常用的内存调试工具： jmap、jstack、jconsole、jhat？

jstack 可以看当前栈的情况，jmap 查看内存，jhat 进行 dump 堆的信息mat（eclipse 的也要了解一下）

### 10.类加载的几个过程？

加载、验证、准备、解析、初始化。然后是使用和卸载了通过全限定名来加载生成 class 对象到内存中，然后进行验证这个 class 文件，包括文件格式校验、元数据验证，字节码校验等。 准备是对这个对象分配内存。 解析是将符号引用转化为直接引用（指针引用），初始化就是开始执行构造器的代码

### 11.JVM 内存分哪几个区，每个区的作用是什么?

java虚拟机主要分为以下一个区:

* 方法区：

(1) 有时候也成为永久代，在该区内很少发生垃圾回收，但是并不代表不发生 GC，在这里进行的 GC 主要是对方法区里的常量池和对类型的卸载

(2) 方法区主要用来存储已被虚拟机加载的类的信息、常量、静态变量和即时编译器编译后的代码等数据。

(3) 该区域是被线程共享的。

(4) 方法区里有一个运行时常量池，用于存放静态编译产生的字面量和符号引用。 该常量池具有动态性，也就是说常量并不一定是编译时确定，运行时生成的常量也会存在这个常量池中。

* 虚拟机栈:

1.虚拟机栈也就是我们平常所称的栈内存,它为 java 方法服务，每个方法在执行的时候都会创建一个栈帧，用于存储局部变量表、操作数栈、动态链接和方法出口等信息。

2.虚拟机栈是线程私有的，它的生命周期与线程相同。

3.局部变量表里存储的是基本数据类型、returnAddress 类型（指向一条字节码指令的地址）和对象引用，这个对象引用有可能是指向对象起始地址的一个指针，也有可能是代表对象的句柄或者与对象相关联的位置。 局部变量所需的内存空间在编译器间确定

4.操作数栈的作用主要用来存储运算结果以及运算的操作数，它不同于局部变量表通过索引来访问，而是压栈和出栈的方式

5.每个栈帧都包含一个指向运行时常量池中该栈帧所属方法的引用，持有这个引用是为了支持方法调用过程中的动态连接.动态链接就是将常量池中的符号引用在运行期转化为直接引用。

* 本地方法栈：

本地方法栈和虚拟机栈类似，只不过本地方法栈为 Native 方法服务。

* 堆:

java 堆是所有线程所共享的一块内存，在虚拟机启动时创建，几乎所有的对象实例都在这里创建，因此该区域经常发生垃圾回收操作。

* 程序计数器:

内存空间小，字节码解释器工作时通过改变这个计数值可以选取下一条需要执行的字节码指令，分支、循环、跳转、异常处理和线程恢复等功能都需要依赖这个计数器完成。 该内存区域是唯一一个 java 虚拟机规范没有规定任何 OOM 情况的区域。

### 12.如和判断一个对象是否存活?(或者 GC 对象的判定方法)

判断一个对象是否存活有两种方法:

1.引用计数法所谓引用计数法就是给每一个对象设置一个引用计数器，每当有一个地方引用这个对象时，就将计数器加一，引用失效时，计数器就减一。 当一个对象的引用计数器为零时，说明此对象没有被引用，也就是“死对象”,将会被垃圾回收。

引用计数法有一个缺陷就是无法解决循环引用问题，也就是说当对象 A 引用对象 B，对象B 又引用者对象 A，那么此时 A,B 对象的引用计数器都不为零，也就造成无法完成垃圾回收，所以主流的虚拟机都没有采用这种算法。

2.可达性算法(引用链法)该算法的思想是： 从一个被称为 GC Roots 的对象开始向下搜索，如果一个对象到 GC Roots没有任何引用链相连时，则说明此对象不可用。在 java 中可以作为 GC Roots的对象有以下几种：

* 虚拟机栈中引用的对象
* 方法区类静态属性引用的对象
* 方法区常量池引用的对象
* 本地方法栈 JNI 引用的对象

虽然这些算法可以判定一个对象是否能被回收，但是当满足上述条件时，一个对象比不一定会被回收。 当一个对象不可达 GC Root 时，这个对象并不会立马被回收，而是出于一个死缓的阶段，若要被真正的回收需要经历两次标记如果对象在可达性分析中没有与 GC Root 的引用链，那么此时就会被第一次标记并且进行一次筛选，筛选的条件是是否有必要执行 finalize()方法。 当对象没有覆盖 finalize()方法或者已被虚拟机调用过，那么就认为是没必要的。

如果该对象有必要执行 finalize()方法，那么这个对象将会放在一个称为 F-Queue 的对队列中，虚拟机会触发一个 Finalize()线程去执行，此线程是低优先级的，并且虚拟机不会承诺一直等待它运行完，这是因为如果 finalize()执行缓慢或者发生了死锁，那么就会造成 FQueue 队列一直等待，造成了内存回收系统的崩溃。 GC 对处于 F-Queue 中的对象进行第二次被标记，这时，该对象将被移除”即将回收”集合，等待回收。

### 13.简述 java 垃圾回收机制?

在 java 中，程序员是不需要显示的去释放一个对象的内存的，而是由虚拟机自行执行。在JVM 中，有一个垃圾回收线程，它是低优先级的，在正常情况下是不会执行的，只有在虚拟机空闲或者当前堆内存不足时，才会触发执行，扫面那些没有被任何引用的对象，并将它们添加到要回收的集合中，进行回收。

### 14.java 中垃圾收集的方法有哪些?

* 标记清除:

这是垃圾收集算法中最基础的，根据名字就可以知道，它的思想就是标记哪些要被回收的对象，然后统一回收。这种方法很简单，但是会有两个主要问题：

1.效率不高，标记和清除的效率都很低；

2.会产生大量不连续的内存碎片，导致以后程序在分配较大的对象时，由于没有充足的连续内存而提前触发一次 GC 动作。

* 复制算法:

为了解决效率问题，复制算法将可用内存按容量划分为相等的两部分，然后每次只使用其中的一块，当一块内存用完时，就将还存活的对象复制到第二块内存上，然后一次性清楚完第一块内存，再将第二块上的对象复制到第一块。但是这种方式，内存的代价太高，每次基本上都要浪费一般的内存。于是将该算法进行了改进，内存区域不再是按照 1：1 去划分，而是将内存划分为8:1:1 三部分，较大那份内存交 Eden 区，其余是两块较小的内存区叫 Survior 区。每次都会优先使用 Eden 区，若 Eden 区满，就将对象复制到第二块内存区上，然后清除 Eden 区，如果此时存活的对象太多，以至于 Survivor 不够时，会将这些对象通过分配担保机制复制到老年代中。(java 堆又分为新生代和老年代)

* 标记整理:

该算法主要是为了解决标记-清除，产生大量内存碎片的问题；当对象存活率较高时，也解决了复制算法的效率问题。它的不同之处就是在清除对象的时候现将可回收对象移动到一端，然后清除掉端边界以外的对象，这样就不会产生内存碎片了。

* 分代收集

现在的虚拟机垃圾收集大多采用这种方式，它根据对象的生存周期，将堆分为新生代和老年代。在新生代中，由于对象生存期短，每次回收都会有大量对象死去，那么这时就采用复制算法。老年代里的对象存活率较高，没有额外的空间进行分配担保，所以可以使用标记-整理 或者 标记-清除

### 15.java 内存模型？

java 内存模型(JMM)是线程间通信的控制机制.JMM 定义了主内存和线程之间抽象关系。线程之间的共享变量存储在主内存（main memory）中，每个线程都有一个私有的本地内存（local memory），本地内存中存储了该线程以读/写共享变量的副本。本地内存是JMM 的一个抽象概念，并不真实存在。它涵盖了缓存，写缓冲区，寄存器以及其他的硬件和编译器优化。Java 内存模型的抽象示意图如下：从上图来看，线程 A 与线程 B 之间如要通信的话，必须要经历下面 2 个步骤：1.首先，线程 A 把本地内存 A 中更新过的共享变量刷新到主内存中去。2. 然后，线程 B 到主内存中去读取线程 A 之前已更新过的共享变量。

### 16.java 类加载过程?

java 类加载需要经历以下 几个过程：

* 加载

加载时类加载的第一个过程，在这个阶段，将完成以下三件事情：

1.通过一个类的全限定名获取该类的二进制流。

2.将该二进制流中的静态存储结构转化为方法去运行时数据结构。

3.在内存中生成该类的 Class 对象，作为该类的数据访问入口。

* 验证

验证的目的是为了确保 Class 文件的字节流中的信息不回危害到虚拟机.在该阶段主要完成以下四钟验证:

1.文件格式验证：验证字节流是否符合 Class 文件的规范，如主次版本号是否在当前虚拟机范围内，常量池中的常量是否有不被支持的类型.

2.元数据验证:对字节码描述的信息进行语义分析，如这个类是否有父类，是否集成了不被继承的类等。

3.字节码验证：是整个验证过程中最复杂的一个阶段，通过验证数据流和控制流的分析，确定程序语义是否正确，主要针对方法体的验证。如：方法中的类型转换是否正确，跳转指令是否正确等。

4.符号引用验证：这个动作在后面的解析过程中发生，主要是为了确保解析动作能正确执行。

* 准备

准备阶段是为类的静态变量分配内存并将其初始化为默认值，这些内存都将在方法区中进行分配。准备阶段不分配类中的实例变量的内存，实例变量将会在对象实例化时随着对象一起分配在 Java 堆中。

* 解析

该阶段主要完成符号引用到直接引用的转换动作。解析动作并不一定在初始化动作完成之前，也有可能在初始化之后。

* 初始化

初始化时类加载的最后一步，前面的类加载过程，除了在加载阶段用户应用程序可以通过自定义类加载器参与之外，其余动作完全由虚拟机主导和控制。到了初始化阶段，才真正开始执行类中定义的 Java 程序代码。

### 17.简述 java 类加载机制?

虚拟机把描述类的数据从 Class 文件加载到内存，并对数据进行校验，解析和初始化，最终形成可以被虚拟机直接使用的 java 类型。

### 18.类加载器双亲委派模型机制？

当一个类收到了类加载请求时，不会自己先去加载这个类，而是将其委派给父类，由父类去加载，如果此时父类不能加载，反馈给子类，由子类去完成类的加载。

### 19.什么是类加载器，类加载器有哪些?

实现通过类的权限定名获取该类的二进制字节流的代码块叫做类加载器。主要有以下四种类加载器:

1.启动类加载器(Bootstrap ClassLoader)用来加载 java 核心类库，无法被 java 程序直接引用。

2.扩展类加载器(extensions class loader):它用来加载 Java 的扩展库。Java 虚拟机的实现会提供一个扩展库目录。该类加载器在此目录里面查找并加载 Java 类。

3.系统类加载器（system class loader）：它根据 Java 应用的类路径（CLASSPATH）来加载 Java 类。一般来说，Java 应用的类都是由它来完成加载的，可以通过ClassLoader.getSystemClassLoader()来获取它。

4.用户自定义类加载器，通过继承 java.lang.ClassLoader 类的方式实现。

### 20.简述 java 内存分配与回收策率以及 Minor GC 和Major GC？

1.对象优先在堆的 Eden 区分配。

2.大对象直接进入老年代.

3.长期存活的对象将直接进入老年代.，当 Eden 区没有足够的空间进行分配时，虚拟机会执行一次 Minor GC.Minor Gc 通常发生在新生代的 Eden 区，在这个区的对象生存期短，往往发生 Gc 的频率较高，回收速度比较快;Full Gc/Major GC 发生在老年代，一般情况下，触发老年代 GC的时候不会触发 Minor GC,但是通过配置，可以在 Full GC 之前进行一次 MinorGC 这样可以加快老年代的回收速度。



### 21.g1和cms怎么处理在并发标记过程中误标的？

要解决并发扫描时的对象消失问题，只需破坏这两个条件的任意一个即可。由此分别产生了两种解决方案：

**增量更新（Incremental Update）(CMS)**和**原始快照（Snapshot At The Beginning，SATB）(G1)。**

见深入理解JVM 3.4.6





### jvm参数

-Xmx3550m：设置JVM最大堆内存为3550M。

-Xms3550m：设置JVM初始堆内存为3550M。此值可以设置与-Xmx相同，以避免每次垃圾回收完成后JVM重新分配内存。 

-Xss128k：设置每个线程的栈大小。JDK5.0以后每个线程栈大小为1M，之前每个线程栈大小为256K。应当根据应用的线程所需内存大小进行调整。在相同物理内存下，减小这个值能生成更多的线程。但是操作系统对一个进程内的线程数还是有限制的，不能无限生成，经验值在3000~5000左右。需要注意的是：当这个值被设置的较大（例如>2MB）时将会在很大程度上降低系统的性能。 

-Xmn2g：设置年轻代大小为2G。在整个堆内存大小确定的情况下，增大年轻代将会减小年老代，反之亦然。此值关系到JVM垃圾回收，对系统性能影响较大，官方推荐配置为整个堆大小的3/8。

-XX:NewSize=1024m：设置年轻代初始值为1024M。

-XX:MaxNewSize=1024m：设置年轻代最大值为1024M。

-XX:PermSize=256m：设置持久代初始值为256M。

-XX:MaxPermSize=256m：设置持久代最大值为256M。

-XX:NewRatio=4：设置年轻代（包括1个Eden和2个Survivor区）与年老代的比值。表示年轻代比年老代为1:4。

 -XX:SurvivorRatio=4：设置年轻代中Eden区与Survivor区的比值。表示2个Survivor区（JVM堆内存年轻代中默认有2个大小相等的Survivor区）与1个Eden区的比值为2:4，即1个Survivor区占整个年轻代大小的1/6。 -XX:MaxTenuringThreshold=7：表示一个对象如果在Survivor区（救助空间）移动了7次还没有被垃圾回收就进入年老代。如果设置为0的话，则年轻代对象不经过Survivor区，直接进入年老代，对于需要大量常驻内存的应用，这样做可以提高效率。如果将此值设置为一个较大值，则年轻代对象会在Survivor区进行多次复制，这样可以增加对象在年轻代存活时间，增加对象在年轻代被垃圾回收的概率，减少Full GC的频率，这样做可以在某种程度上提高服务稳定性。



 JVM服务参数调优实战 

大型网站服务器案例 承受海量访问的动态Web应用 

服务器配置：8 CPU, 8G MEM, JDK 1.6.X 

参数方案： -server -Xmx3550m -Xms3550m -Xmn1256m -Xss128k -XX:SurvivorRatio=6 -XX:MaxPermSize=256m -XX:ParallelGCThreads=8 -XX:MaxTenuringThreshold=0 -XX:+UseConcMarkSweepGC 

调优说明： -Xmx 与 -Xms 相同以避免JVM反复重新申请内存。-Xmx 的大小约等于系统内存大小的一半，即充分利用系统资源，又给予系统安全运行的空间。 -Xmn1256m 设置年轻代大小为1256MB。此值对系统性能影响较大，Sun官方推荐配置年轻代大小为整个堆的3/8。 -Xss128k 设置较小的线程栈以支持创建更多的线程，支持海量访问，并提升系统性能。 -XX:SurvivorRatio=6 设置年轻代中Eden区与Survivor区的比值。系统默认是8，根据经验设置为6，则2个Survivor区与1个Eden区的比值为2:6，一个Survivor区占整个年轻代的1/8。 -XX:ParallelGCThreads=8 配置并行收集器的线程数，即同时8个线程一起进行垃圾回收。此值一般配置为与CPU数目相等。 -XX:MaxTenuringThreshold=0 设置垃圾最大年龄（在年轻代的存活次数）。如果设置为0的话，则年轻代对象不经过Survivor区直接进入年老代。对于年老代比较多的应用，可以提高效率；如果将此值设置为一个较大值，则年轻代对象会在Survivor区进行多次复制，这样可以增加对象再年轻代的存活时间，增加在年轻代即被回收的概率。根据被海量访问的动态Web应用之特点，其内存要么被缓存起来以减少直接访问DB，要么被快速回收以支持高并发海量请求，因此其内存对象在年轻代存活多次意义不大，可以直接进入年老代，根据实际应用效果，在这里设置此值为0。 -XX:+UseConcMarkSweepGC 设置年老代为并发收集。CMS（ConcMarkSweepGC）收集的目标是尽量减少应用的暂停时间，减少Full GC发生的几率，利用和应用程序线程并发的垃圾回收线程来标记清除年老代内存，适用于应用中存在比较多的长生命周期对象的情况。 

内部集成构建服务器案例 

高性能数据处理的工具应用 服务器配置：1 CPU, 4G MEM, JDK 1.6.X 

参数方案： -server -XX:PermSize=196m -XX:MaxPermSize=196m -Xmn320m -Xms768m -Xmx1024m 

调优说明： -XX:PermSize=196m -XX:MaxPermSize=196m 根据集成构建的特点，大规模的系统编译可能需要加载大量的Java类到内存中，所以预先分配好大量的持久代内存是高效和必要的。 -Xmn320m 遵循年轻代大小为整个堆的3/8原则。 -Xms768m -Xmx1024m 根据系统大致能够承受的堆内存大小设置即可。



适用于起步阶段的个人网站  建议堆内存 1gb  可以使用串行SeriaIGC 建议使用并行 ParallelGC。
有一定访问量的网站或者app 建议堆内存设置为2gb  建议使用并行 ParallelGC。
并发适中的APp 或者普通的数据处理 建议堆内存4gb 老年代cms/新生代parnew
适应于并发量高的app   建议使用堆内存 8g 或者16g 建议使用G1收集器 注重低延迟和吞吐量


[jvm参数设置大全](https://www.cnblogs.com/marcotan/p/4256885.html)

[JVM底层原理、四大垃圾回收算法详解(长文警告)](https://www.jianshu.com/p/9e6841a895b4) 



```bash
 # 查看 gc 情况,1000ms打印一次，打印10次
 jstat -gcutil pid 1000 10
 jstat -gc 71614 5000
 jstat -gccause 859
 
S0C：年轻代中第一个survivor（幸存区）的容量 （字节）
S1C：年轻代中第二个survivor（幸存区）的容量 (字节)
S0U ：年轻代中第一个survivor（幸存区）目前已使用空间 (字节)
S1U ：年轻代中第二个survivor（幸存区）目前已使用空间 (字节)
EC ：年轻代中Eden（伊甸园）的容量 (字节)
EU ：年轻代中Eden（伊甸园）目前已使用空间 (字节)
OC ：Old代的容量 (字节)
OU ：Old代目前已使用空间 (字节)
MC：metaspace(元空间)的容量 (字节)
MU：metaspace(元空间)目前已使用空间 (字节)
YGC ：从应用程序启动到采样时年轻代中gc次数
YGCT ：从应用程序启动到采样时年轻代中gc所用时间(s)
FGC ：从应用程序启动到采样时old代(全gc)gc次数
FGCT ：从应用程序启动到采样时old代(全gc)gc所用时间(s)
GCT：从应用程序启动到采样时gc用的总时间(s)

 jstat -gcmetacapacity 859
MCMN:最小元数据容量
MCMX：最大元数据容量
MC：当前元数据空间大小
CCSMN：最小压缩类空间大小
CCSMX：最大压缩类空间大小
CCSC：当前压缩类空间大小
YGC ：从应用程序启动到采样时年轻代中gc次数
FGC ：从应用程序启动到采样时old代(全gc)gc次数
FGCT ：从应用程序启动到采样时old代(全gc)gc所用时间(s)
GCT：从应用程序启动到采样时gc用的总时间(s)

```

[jvm 性能调优工具之 jstat](https://www.jianshu.com/p/213710fb9e40)

```bash
#这个命令可以查看 Metaspace 加载的到底是哪些类   需启用参数 -XX:+UnlockDiagnosticVMOptions
jcmd pid GC.class_stats

jcmd pid GC.class_stats |awk '{print $13}'| sort | uniq -c |sort -r| head
```

```bash
#这个可以查看类加载器的数据
jmap -clstats pid
```

```bash
#该命令可以查看当前jvm内存里对象的实例数和占用内存数 
jmap -histo pid > jmap.txt
```

```bash
#jvm 服务JVM的GC和堆内存使用情况  https://www.cnblogs.com/zhanying999666/p/12188937.html
jmap -heap pid  

#G1
Heap Configuration:   #堆配置情况 
   MinHeapFreeRatio         = 40  #堆最小使用比例
   MaxHeapFreeRatio         = 70  #堆最大使用比例
   MaxHeapSize              = 8589934592 (8192.0MB)  #堆最大空间
   NewSize                  = 1363144 (1.2999954223632812MB) #新生代初始化大小
   MaxNewSize               = 5152702464 (4914.0MB)          #新生代可使用最大容量大小
   OldSize                  = 5452592 (5.1999969482421875MB) #老生代大小
   NewRatio                 = 2   #新生代比例
   SurvivorRatio            = 8   #新生代与suvivor的占比
   MetaspaceSize            = 21807104 (20.796875MB) #元数据空间初始大小
   CompressedClassSpaceSize = 1073741824 (1024.0MB) #类指针压缩空间大小, 默认为1G
   MaxMetaspaceSize         = 17592186044415 MB  #元数据空间的最大值, 超过此值就会触发 GC溢出( JVM会动态地改变此值)
   G1HeapRegionSize         = 2097152 (2.0MB) #区块的大小

Heap Usage:
G1 Heap:
   regions  = 4096  # G1区块初始化大小
   capacity = 8589934592 (8192.0MB)  #G1区块最大可使用大小
   used     = 1557972768 (1485.7986145019531MB)  #G1区块已使用内存
   free     = 7031961824 (6706.201385498047MB)   #G1区块空闲内存
   18.137190118432045% used     #G1区块使用比例
G1 Young Generation:  #新生代
Eden Space:  #Eden区空间
   regions  = 670
   capacity = 2699034624 (2574.0MB)
   used     = 1405091840 (1340.0MB)
   free     = 1293942784 (1234.0MB)
   52.05905205905206% used
Survivor Space: #Survivor区
   regions  = 3
   capacity = 6291456 (6.0MB)
   used     = 6291456 (6.0MB)
   free     = 0 (0.0MB)
   100.0% used
G1 Old Generation: #老生代
   regions  = 72
   capacity = 1589641216 (1516.0MB)
   used     = 146589472 (139.79861450195312MB)
   free     = 1443051744 (1376.2013854980469MB)
   9.221544492213267% used
```

```bash
# 查看JVM参数信息
jinfo -flags [pid]

Attaching to process ID 859, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 25.272-b10
Non-default VM flags: -XX:CICompilerCount=2 -XX:CompressedClassSpaceSize=125829120 -XX:ConcGCThreads=1 -XX:G1HeapRegionSize=1048576 -XX:InitialHeapSize=268435456 -XX:MarkStackSize=4194304 -XX:MaxHeapSize=268435456 -XX:MaxMetaspaceSize=134217728 -XX:MaxNewSize=160432128 -XX:MetaspaceSize=67108864 -XX:MinHeapDeltaBytes=1048576 -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:ThreadStackSize=512 -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:+UseG1GC 
Command line:  -XX:+PrintGCDetails -Xloggc:authoritygc.log -Xms256M -Xmx256M -Xss512k -XX:MetaspaceSize=64M -XX:MaxMetaspaceSize=128M -XX:+UseG1GC

```





1）首先配置JVM启动参数，让JVM在遇到OutOfMemoryError时自动生成Dump文件

```bash
-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/path
```

java获取内存dump的几种方式

1、获取内存详情：**jmap -dump:format=b,file=name.dump pid**
这种方式可以用 jvisualvm.exe 进行内存分析，或者采用 Eclipse Memory Analysis Tools (MAT)这个工具

\2. 获取内存dump：  jmap -histo:live pid
这种方式会先出发fullgc，所有如果不希望触发fullgc 可以使用jmap -histo pid

3.第三种方式：jdk启动加参数：
-XX:+HeapDumpBeforeFullGC 
-XX:HeapDumpPath=/httx/logs/dump
这种方式会产生dump日志，再通过jvisualvm.exe 或者Eclipse Memory Analysis Tools 工具进行分析





### cpu过高

①通过 **top** 命令找到占用cpu最高的 **pid[进程id]** 

②通过 **top -Hp pid** 查看进程中占用cpu过高的 **tid[线程id]** 

③通过 **printf  '%x/n' tid**  把线程id转化为十六进制

④通过 **jstack pid | grep tid -A 30** 定位线程堆栈信息

```
jstack 28223 | grep -A30 6e48
```



打印 GC日志

```bash
-XX:+PrintGC 输出简要GC日志 
-XX:+PrintGCDetails 输出详细GC日志 
-Xloggc:gc.log  输出GC日志到文件
-XX:+PrintGCTimeStamps 输出GC的时间戳（以JVM启动到当期的总时长的时间戳形式） 
-XX:+PrintGCDateStamps 输出GC的时间戳（以日期的形式，如 2013-05-04T21:53:59.234+0800） 
-XX:+PrintHeapAtGC 在进行GC的前后打印出堆的信息
-verbose:gc 控制台打印，打印到文件就不生效了
-XX:+PrintReferenceGC 打印年轻代各个引用的数量以及时
```



-XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:+UseParallelGC



​		使用 Direct Buffer，我们需要清楚它对内存和 JVM 参数的影响。首先，因为它不在堆上，所以 Xmx 之类参数，其实并不能影响 Direct Buffer 等堆外成员所使用的内存额度，我们可以使用下面参数设置大小：

```bash
-XX:MaxDirectMemorySize=512M
```

​		从参数设置和内存问题排查角度来看，这意味着我们在计算 Java 可以使用的内存大小的时候，不能只考虑堆的需要，还有 Direct Buffer 等一系列堆外因素。如果出现内存不足，堆外内存占用也是一种可能性。另外，大多数垃圾收集过程中，都不会主动收集 Direct Buffer，它的垃圾收集过程，就是基于我在专栏前面所介绍的 Cleaner（一个内部实现）和幻象引用（PhantomReference）机制，其本身不是 public 类型，内部实现了一个 Deallocator 负责销毁的逻辑。对它的销毁往往要拖到 full GC 的时候，所以使用不当很容易导致 OutOfMemoryError。

​		因为通常的垃圾收集日志等记录，并不包含 Direct Buffer 等信息，所以 Direct Buffer 内存诊断也是个比较头疼的事情。幸好，在 JDK 8 之后的版本，我们可以方便地使用 Native Memory Tracking（NMT）特性来进行诊断，你可以在程序启动时加上下面参数：

```bash
-XX:NativeMemoryTracking={summary|detail}
```

注意，激活 NMT 通常都会导致 JVM 出现 5%~10% 的性能下降，请谨慎考虑。

​		运行时，可以采用下面命令进行交互式对比：

```bash
// 打印NMT信息
jcmd <pid> VM.native_memory detail 

// 进行baseline，以对比分配内存变化
jcmd <pid> VM.native_memory baseline

// 进行baseline，以对比分配内存变化
jcmd <pid> VM.native_memory detail.diff
```



mataSapce内存溢出基本都是加载类异常

-XX:+TraceClassLoading

-XX:+TraceClassUnloading

从gc日志能够看出来，导致该full gc的原因是达到了metaspace的gc阈值，这里先解释下`Metadata GC Threshold`和`Last ditch collection`：

-  `Metadata GC Threshold`：metaspace空间不能满足分配时触发，这个阶段不会清理软引用；
-  `Last ditch collection`：经过`Metadata GC Threshold`触发的full gc后还是不能满足条件，这个时候会触发再一次的gc cause为`Last ditch collection`的full gc，这次full gc会清理掉软引用。

`XX:+HeapDumpBeforeFullGC`、`-XX:+HeapDumpAfterFullGC`分别在发生full gc前后做heap dump







[深度揭秘垃圾回收底层，这次让你彻底弄懂她](https://my.oschina.net/u/3944379/blog/4722027)

[jvm G1 深度分析](https://blog.csdn.net/u013380694/article/details/83341913)

[可能是最全的G1学习笔记](https://www.cnblogs.com/javaadu/p/10713956.html)

[G1日志分析](https://www.cnblogs.com/yuanzipeng/p/13374690.html，https://www.cnblogs.com/javaadu/p/11220234.html)

[G1日志格式](https://my.oschina.net/dabird/blog/710444)

[G1日志在线分析！！！！！](http://gceasy.io/)

[jvm 工具篇-（3）-G1-案例-调优过程](https://www.jianshu.com/p/bc42531b28f3)

[堆内存常见的分配策略、 经典的垃圾收集器、CMS与G1收集器及二者的比较](https://www.cnblogs.com/jjfan0327/p/12795015.html)

[java对象内存估算](https://cloud.tencent.com/developer/article/1552089)

[HotSpot VM G1 垃圾回收的survivor 0区貌似永远是0](https://hllvm-group.iteye.com/group/topic/42352)

[Java中9种常见的CMS GC问题分析与解决](https://tech.meituan.com/2020/11/12/java-9-cms-gc.html)

[一次jvm调优实战](https://mp.weixin.qq.com/s?__biz=MzU2NjIzNDk5NQ==&mid=2247496741&idx=1&sn=1fa0f6cd5802563b203af5926890b06e&chksm=fcad2e39cbdaa72fbedf531ad54ea6b0aaae1f7fc8ed1d90667547f14556ce5af72c79e4ade6&scene=132#wechat_redirect)

[JVM Metaspace内存溢出排查与总结](https://www.cnblogs.com/maoyx/p/13934732.html)

[大量类加载器创建导致诡异FullGC](https://zhuanlan.zhihu.com/p/186226342)

[记录一次线上GC问题/cms参数](https://blog.csdn.net/qq_35211818/article/details/104182847)

[java反射导致的fullgc  碰到过，mybatis](https://blog.csdn.net/z69183787/article/details/99415576)

[Java 虚拟机底层原理知识总结](https://github.com/doocs/jvm)



年轻代进入老年代的三种情况

* 大对象直接进入老年代
* 长期存活的对象进入老年代（被移到survivor空间中，年龄为1，之后每熬过一次MinorGC,年龄加一，当年龄达到一定程度默认15岁时会被晋升到老年代）
* 动态年龄判断（在survivor空间中相同年所有对象的大小总和大于survivor空间的一半，年龄大于或等于该年龄的对象就可以直接进入老年代，无需等到MaxTenuringThreshold中要求的年龄）。





1.在线profiling

但是，当生产系统确实存在这种需求时，也不是没有选择。我建议使用 JFR 配合JMC来做 Profiling，因为它是从 Hotspot JVM 内部收集底层信息，并经过了大量优化，性能开销非常低，通常是低于 2% 的；并且如此强大的工具，也已经被 Oracle 开源出来！所以，JFR/JMC 完全具备了生产系统 Profiling 的能力，目前也确实在真正大规模部署的云产品上使用过相关技术，快速地定位了问题。它的使用也非常方便，你不需要重新启动系统或者提前增加配置。例如，你可以在运行时启动 JFR 记录，并将这段时间的信息写入文件：

前提是应用启动时加了参数：

```bash
-XX:+UnlockCommercialFeatures  
-XX:+FlightRecorder


//开启商业特性和飞行记录器
-XX:+UnlockCommercialFeatures"
-XX:+FlightRecorder"
//开启远程调试
-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005
//开启JMC服务端口
-Dcom.sun.management.jmxremote.rmi.port=1099
-Dcom.sun.management.jmxremote=true
-Dcom.sun.management.jmxremote.port=1099
-Dcom.sun.management.jmxremote.ssl=false
-Dcom.sun.management.jmxremote.authenticate=false
-Dcom.sun.management.jmxremote.local.only=false
//这个ip是你的服务器所在的ip，不是你的本地机器的ip
-Djava.rmi.server.hostname=192.168.1.175
```

```bash
jcmd <pid> JFR.start duration=120s filename=myrecording.jfr
```

然后，使用 JMC 打开“.jfr 文件”就可以进行分析了，方法、异常、线程、IO 等应有尽有，其功能非常强大。

nohup java -jar -server -Xms1024M -Xmx1024M -Xss512k -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=256M -XX:+UseConcMarkSweepGC -XX:+PrintGCDateStamps -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/root/Xhub/dumpLocation  -XX:+PrintGCDetails -Xloggc:/root/Xhub/gclogs/devicegc.log  -XX:+UnlockCommercialFeatures  -XX:+FlightRecorder -Dcom.sun.management.jmxremote.rmi.port=1099 -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.local.only=false -Djava.rmi.server.hostname=192.168.1.175 DSLinkHub-Xhub-device-server-1.0-SNAPSHOT.jar --server.port=8769 --spring.profiles.active=dev> /root/Xhub/serviceLogs/device-8769.txt &

![jmc.png](http://ww1.sinaimg.cn/large/0072fULUgy1gr9o36qfdnj60p00czq3102.jpg)

[jmc使用--线上profiling](https://blog.csdn.net/yunfeng482/article/details/89384912)

[jmc使用](https://www.cnblogs.com/duanxz/p/8533174.html)

