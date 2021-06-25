## ConcurrentHashMap

### 重要属性

sizeCtl属性,不同状态，sizeCtl所代表的含义也有所不同。

- 未初始化：
  - sizeCtl=0：表示没有指定初始容量。
  - sizeCtl>0：表示初始容量。

- 初始化中：
  - sizeCtl=-1,标记作用，告知其他线程，正在初始化
- 正常状态：
  - sizeCtl=0.75n ,扩容阈值
- 扩容中:
  - sizeCtl < 0 : 表示有其他线程正在执行扩容
  - sizeCtl = (resizeStamp(n) << RESIZE_STAMP_SHIFT) + 2 :表示此时只有一个线程在执行扩容

ConcurrentHashMap的状态图如下：

![img](https://upload-images.jianshu.io/upload_images/6283837-f2a6af20a4c73b93.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)







transferIndex属性,**扩容索引，表示已经分配给扩容线程的table数组索引位置。主要用来协调多个线程，并发安全地获取迁移任务（hash桶）。**

1 在扩容之前，transferIndex 在数组的最右边 。此时有一个线程发现已经到达扩容阈值，准备开始扩容。

![img](https://upload-images.jianshu.io/upload_images/6283837-6a95de459a4f48d5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)

2 扩容线程，在迁移数据之前，首先要将transferIndex右移（以cas的方式修改 **transferIndex=transferIndex-stride(要迁移hash桶的个数)**），获取迁移任务。每个扩容线程都会通过for循环+CAS的方式设置transferIndex，因此可以确保多线程扩容的并发安全。

![img](https://upload-images.jianshu.io/upload_images/6283837-7e10aa6066673c79.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)

image.png

换个角度，我们可以将待迁移的table数组，看成一个任务队列，transferIndex看成任务队列的头指针。而扩容线程，就是这个队列的消费者。扩容线程通过CAS设置transferIndex索引的过程，就是消费者从任务队列中获取任务的过程。为了性能考虑，我们当然不会每次只获取一个任务（hash桶），因此ConcurrentHashMap规定，每次至少要获取16个迁移任务（迁移16个hash桶，MIN_TRANSFER_STRIDE = 16）





ForwardingNode节点

1. 标记作用，表示其他线程正在扩容，并且此节点已经扩容完毕
2. 关联了nextTable,扩容期间可以通过find方法，访问已经迁移到了nextTable中的数据



### 扩容时机

1.容量超过阈值

2.当链表中元素个数超过默认设定（8个），当数组的大小还未超过64的时候，此时进行数组的扩容，如果超过则将链表转化成红黑树

3.当发现其他线程扩容时，帮其扩容。



扩容过程分析

1. 线程执行put操作，发现容量已经达到扩容阈值，需要进行扩容操作，此时transferindex=tab.length=32

![img](https://upload-images.jianshu.io/upload_images/6283837-7f4245fc23fc4324.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)



2. 扩容线程A 以cas的方式修改transferindex=31-16=16 ,然后按照降序迁移table[31]--table[16]这个区间的hash桶

![img](https://upload-images.jianshu.io/upload_images/6283837-a6f735b4644ab7dd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)



3. 迁移hash桶时，会将桶内的链表或者红黑树，按照一定算法，拆分成2份，将其插入nextTable[i]和nextTable[i+n]（n是table数组的长度）。 迁移完毕的hash桶,会被设置成ForwardingNode节点，以此告知访问此桶的其他线程，此节点已经迁移完毕。

![img](https://upload-images.jianshu.io/upload_images/6283837-6978c0be378fd383.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)

```java
private final void transfer(Node<K,V>[] tab, Node<K,V>[] nextTab) {
    ...//省略无关代码
        synchronized (f) {
        //将node链表，分成2个新的node链表
        for (Node<K,V> p = f; p != lastRun; p = p.next) {
            int ph = p.hash; K pk = p.key; V pv = p.val;
            if ((ph & n) == 0)
                ln = new Node<K,V>(ph, pk, pv, ln);
            else
                hn = new Node<K,V>(ph, pk, pv, hn);
        }
        //将新node链表赋给nextTab
        setTabAt(nextTab, i, ln);
        setTabAt(nextTab, i + n, hn);
        setTabAt(tab, i, fwd);
    }
    ...//省略无关代码
}
```

4. 此时线程2访问到了ForwardingNode节点，如果线程2执行的put或remove等写操作，那么就会先帮其扩容。如果线程2执行的是get等读方法，则会调用ForwardingNode的find方法，去nextTable里面查找相关元素。

![img](https://upload-images.jianshu.io/upload_images/6283837-84175020fe1fa8e1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)



5. 线程2加入扩容操作

![img](https://upload-images.jianshu.io/upload_images/6283837-0562184a535d7e53.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)



6. 如果准备加入扩容的线程，发现以下情况，放弃扩容，直接返回。

- 发现transferIndex=0,即**所有node均已分配**
- 发现扩容线程已经达到**最大扩容线程数**

![img](https://upload-images.jianshu.io/upload_images/6283837-d1febe6c1f9379b1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)





### 部分方法解析

#### 1. tryPresize()



```java
private final void tryPresize(int size) {
    //计算扩容的目标size
    int c = (size >= (MAXIMUM_CAPACITY >>> 1)) ? MAXIMUM_CAPACITY :
    tableSizeFor(size + (size >>> 1) + 1);
    int sc;
    while ((sc = sizeCtl) >= 0) {
        Node<K,V>[] tab = table; int n;
        //tab没有初始化
        if (tab == null || (n = tab.length) == 0) {
            n = (sc > c) ? sc : c;
            //初始化之前，CAS设置sizeCtl=-1 
            if (U.compareAndSwapInt(this, SIZECTL, sc, -1)) {
                try {
                    if (table == tab) {
                        @SuppressWarnings("unchecked")
                        Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n];
                        table = nt;
                        //sc=0.75n,相当于扩容阈值
                        sc = n - (n >>> 2);
                    }
                } finally {
                    //此时并没有通过CAS赋值，因为其他想要执行初始化的线程，发现sizeCtl=-1，就直接返回，从而确保任何情况，只会有一个线程执行初始化操作。
                    sizeCtl = sc;
                }
            }
        }
        //目标扩容size小于扩容阈值，或者容量超过最大限制时，不需要扩容
        else if (c <= sc || n >= MAXIMUM_CAPACITY)
            break;
        //扩容
        else if (tab == table) {
            int rs = resizeStamp(n);
            //sc<0表示，已经有其他线程正在扩容
            if (sc < 0) {
                Node<K,V>[] nt;
                /**
                      1 (sc >>> RESIZE_STAMP_SHIFT) != rs ：扩容线程数 > MAX_RESIZERS-1
                      2 sc == rs + 1 和 sc == rs + MAX_RESIZERS ：表示什么？？？
                      3 (nt = nextTable) == null ：表示nextTable正在初始化
                      4 transferIndex <= 0 ：表示所有hash桶均分配出去
                    */
                //如果不需要帮其扩容，直接返回
                if ((sc >>> RESIZE_STAMP_SHIFT) != rs || sc == rs + 1 ||
                    sc == rs + MAX_RESIZERS || (nt = nextTable) == null ||
                    transferIndex <= 0)
                    break;
                //CAS设置sizeCtl=sizeCtl+1
                if (U.compareAndSwapInt(this, SIZECTL, sc, sc + 1))
                    //帮其扩容
                    transfer(tab, nt);
            }
            //第一个执行扩容操作的线程，将sizeCtl设置为：(resizeStamp(n) << RESIZE_STAMP_SHIFT) + 2)
            else if (U.compareAndSwapInt(this, SIZECTL, sc,
                                         (rs << RESIZE_STAMP_SHIFT) + 2))
                transfer(tab, null);
        }
    }
}
```



#### 2. transfer()



```java
private final void transfer(Node<K,V>[] tab, Node<K,V>[] nextTab) {
    int n = tab.length, stride;
    //计算需要迁移多少个hash桶（MIN_TRANSFER_STRIDE该值作为下限，以避免扩容线程过多）
    if ((stride = (NCPU > 1) ? (n >>> 3) / NCPU : n) < MIN_TRANSFER_STRIDE)
        stride = MIN_TRANSFER_STRIDE; // subdivide range

    if (nextTab == null) {            // initiating
        try {
            //扩容一倍
            @SuppressWarnings("unchecked")
            Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n << 1];
            nextTab = nt;
        } catch (Throwable ex) {      // try to cope with OOME
            sizeCtl = Integer.MAX_VALUE;
            return;
        }
        nextTable = nextTab;
        transferIndex = n;
    }
    int nextn = nextTab.length;
    ForwardingNode<K,V> fwd = new ForwardingNode<K,V>(nextTab);
    boolean advance = true;
    boolean finishing = false; // to ensure sweep before committing nextTab

    //1 逆序迁移已经获取到的hash桶集合，如果迁移完毕，则更新transferIndex，获取下一批待迁移的hash桶
    //2 如果transferIndex=0，表示所以hash桶均被分配，将i置为-1，准备退出transfer方法
    for (int i = 0, bound = 0;;) {
        Node<K,V> f; int fh;

        //更新待迁移的hash桶索引
        while (advance) {
            int nextIndex, nextBound;
            //更新迁移索引i。
            if (--i >= bound || finishing)
                advance = false;
            else if ((nextIndex = transferIndex) <= 0) {
                //transferIndex<=0表示已经没有需要迁移的hash桶，将i置为-1，线程准备退出
                i = -1;
                advance = false;
            }
            //当迁移完bound这个桶后，尝试更新transferIndex，，获取下一批待迁移的hash桶
            else if (U.compareAndSwapInt
                     (this, TRANSFERINDEX, nextIndex,
                      nextBound = (nextIndex > stride ?
                                   nextIndex - stride : 0))) {
                bound = nextBound;
                i = nextIndex - 1;
                advance = false;
            }
        }
        //退出transfer
        if (i < 0 || i >= n || i + n >= nextn) {
            int sc;
            if (finishing) {
                //最后一个迁移的线程，recheck后，做收尾工作，然后退出
                nextTable = null;
                table = nextTab;
                sizeCtl = (n << 1) - (n >>> 1);
                return;
            }
            if (U.compareAndSwapInt(this, SIZECTL, sc = sizeCtl, sc - 1)) {
                /**
                     第一个扩容的线程，执行transfer方法之前，会设置 sizeCtl = (resizeStamp(n) << RESIZE_STAMP_SHIFT) + 2)
                     后续帮其扩容的线程，执行transfer方法之前，会设置 sizeCtl = sizeCtl+1
                     每一个退出transfer的方法的线程，退出之前，会设置 sizeCtl = sizeCtl-1
                     那么最后一个线程退出时：
                     必然有sc == (resizeStamp(n) << RESIZE_STAMP_SHIFT) + 2)，即 (sc - 2) == resizeStamp(n) << RESIZE_STAMP_SHIFT
                    */

                //不相等，说明不到最后一个线程，直接退出transfer方法
                if ((sc - 2) != resizeStamp(n) << RESIZE_STAMP_SHIFT)
                    return;
                finishing = advance = true;
                //最后退出的线程要重新check下是否全部迁移完毕
                i = n; // recheck before commit
            }
        }
        else if ((f = tabAt(tab, i)) == null)
            advance = casTabAt(tab, i, null, fwd);
        else if ((fh = f.hash) == MOVED)
            advance = true; // already processed
        //迁移node节点
        else {
            synchronized (f) {
                if (tabAt(tab, i) == f) {
                    Node<K,V> ln, hn;
                    //链表迁移
                    if (fh >= 0) {
                        int runBit = fh & n;
                        Node<K,V> lastRun = f;
                        for (Node<K,V> p = f.next; p != null; p = p.next) {
                            int b = p.hash & n;
                            if (b != runBit) {
                                runBit = b;
                                lastRun = p;
                            }
                        }
                        if (runBit == 0) {
                            ln = lastRun;
                            hn = null;
                        }
                        else {
                            hn = lastRun;
                            ln = null;
                        }
                        //将node链表，分成2个新的node链表
                        for (Node<K,V> p = f; p != lastRun; p = p.next) {
                            int ph = p.hash; K pk = p.key; V pv = p.val;
                            if ((ph & n) == 0)
                                ln = new Node<K,V>(ph, pk, pv, ln);
                            else
                                hn = new Node<K,V>(ph, pk, pv, hn);
                        }
                        //将新node链表赋给nextTab
                        setTabAt(nextTab, i, ln);
                        setTabAt(nextTab, i + n, hn);
                        setTabAt(tab, i, fwd);
                        advance = true;
                    }
                    //红黑树迁移
                    else if (f instanceof TreeBin) {
                        TreeBin<K,V> t = (TreeBin<K,V>)f;
                        TreeNode<K,V> lo = null, loTail = null;
                        TreeNode<K,V> hi = null, hiTail = null;
                        int lc = 0, hc = 0;
                        for (Node<K,V> e = t.first; e != null; e = e.next) {
                            int h = e.hash;
                            TreeNode<K,V> p = new TreeNode<K,V>
                                (h, e.key, e.val, null, null);
                            if ((h & n) == 0) {
                                if ((p.prev = loTail) == null)
                                    lo = p;
                                else
                                    loTail.next = p;
                                loTail = p;
                                ++lc;
                            }
                            else {
                                if ((p.prev = hiTail) == null)
                                    hi = p;
                                else
                                    hiTail.next = p;
                                hiTail = p;
                                ++hc;
                            }
                        }
                        ln = (lc <= UNTREEIFY_THRESHOLD) ? untreeify(lo) :
                        (hc != 0) ? new TreeBin<K,V>(lo) : t;
                        hn = (hc <= UNTREEIFY_THRESHOLD) ? untreeify(hi) :
                        (lc != 0) ? new TreeBin<K,V>(hi) : t;
                        setTabAt(nextTab, i, ln);
                        setTabAt(nextTab, i + n, hn);
                        setTabAt(tab, i, fwd);
                        advance = true;
                    }
                }
            }
        }
    }
}
```





[阿里十年架构师，教你深度分析ConcurrentHashMap原理分析 ](https://www.sohu.com/a/320372210_120176035)

[Java7/8 中的 HashMap 和 ConcurrentHashMap 全解析](https://javadoop.com/post/hashmap)

