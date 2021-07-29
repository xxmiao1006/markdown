## HashMap源码（JDK1.8）

JDK1.8版本hashMap源码解读，1.8的hashMap底层实际是用**数组+链表+红黑树**来实现的。

hashmap使用了链表来解决hash冲突的问题，在1.8后又对链表长度过长降低查询效率的问题进行了优化，当链表长度过长时转化成红黑树来优化查询，链表的查询时间复杂度O(n)，红黑树O(logn);

### 1. 变量

```java
//默认容量  16
static final int DEFAULT_INITIAL_CAPACITY = 1 << 4; // aka 16

//最大容量
static final int MAXIMUM_CAPACITY = 1 << 30;

//默认的负载因子值 0.75（据说这样会符合泊松分布）
static final float DEFAULT_LOAD_FACTOR = 0.75f;

//树化阈值
static final int TREEIFY_THRESHOLD = 8;

//树化还原链表阈值
static final int UNTREEIFY_THRESHOLD = 6;

//可以树化的最小容量
static final int MIN_TREEIFY_CAPACITY = 64;

//底层实现   node数组  长度总是2的次幂
transient Node<K,V>[] table;

//实际长度，map中key-value键值对个数
transient int size;

//下次扩容的阈值 (capacity * load factory)
int threshold;

//负载因子 默认0.75
final float loadFactor;

```



### 2. 构造函数

有4种构造函数

```java
    //带初始化容量和负载因子的构造函数
    public HashMap(int initialCapacity, float loadFactor) {
        //校验数据合法  初始化容量小于0抛异常
        if (initialCapacity < 0)
            throw new IllegalArgumentException("Illegal initial capacity: " +
                                               initialCapacity);
        //初始化容量大于默认的最大容量，则赋予最大容量
        if (initialCapacity > MAXIMUM_CAPACITY)
            initialCapacity = MAXIMUM_CAPACITY;
        //负载因子的合法性校验
        if (loadFactor <= 0 || Float.isNaN(loadFactor))
            throw new IllegalArgumentException("Illegal load factor: " +
                                               loadFactor);
        //给负载因子和扩容阈值赋值
        this.loadFactor = loadFactor;
        this.threshold = tableSizeFor(initialCapacity);
    }

    //调用两个参数的构造函数，负载因子使用默认的0.75
    public HashMap(int initialCapacity) {
        this(initialCapacity, DEFAULT_LOAD_FACTOR);
    }

    /**
     *  使用默认的初始化容量16和负载因子0.75构造hashmap
     * Constructs an empty <tt>HashMap</tt> with the default initial capacity
     * (16) and the default load factor (0.75).
     */
    public HashMap() {
        this.loadFactor = DEFAULT_LOAD_FACTOR; // all other fields defaulted
    }

    /**
     * Constructs a new <tt>HashMap</tt> with the same mappings as the
     * specified <tt>Map</tt>.  The <tt>HashMap</tt> is created with
     * default load factor (0.75) and an initial capacity sufficient to
     * hold the mappings in the specified <tt>Map</tt>.
     *
     * @param   m the map whose mappings are to be placed in this map
     * @throws  NullPointerException if the specified map is null
     */
	//不常用
    public HashMap(Map<? extends K, ? extends V> m) {
        this.loadFactor = DEFAULT_LOAD_FACTOR;
        putMapEntries(m, false);
    }
```



### 3. 常用方法

内部方法

```java
//计算key  hash值的方法
//可以看到是将key值的hashcode值和hashcode值右移16位进行按位与操作，这样可以使高位和地位都参与运算
//使得到的hash值更均匀
//据说一个好的hash计算方法应该符合泊松分布= =！（hashmap源码注释）
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}


//这个方法是返回容量最近的2次幂，，如6->8   12->16
//这个方法能将你输入的数的二进制数从等于1的最高位开始到最低位都变成1，最后返回再+1就变成了2的次幂值
static final int tableSizeFor(int cap) {
    int n = cap - 1;
    n |= n >>> 1;
    n |= n >>> 2;
    n |= n >>> 4;
    n |= n >>> 8;
    n |= n >>> 16;
    return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
}

//hashmap的扩容方法    重点
final Node<K,V>[] resize() {
    Node<K,V>[] oldTab = table;
    //旧的容量
    int oldCap = (oldTab == null) ? 0 : oldTab.length;
    //旧的扩容阈值
    int oldThr = threshold;
    int newCap, newThr = 0;
    //第一种情况：扩容，旧的容量大于0
    if (oldCap > 0) {
        //大于最大容量则直接返回
        if (oldCap >= MAXIMUM_CAPACITY) {
            threshold = Integer.MAX_VALUE;
            return oldTab;
        }
        //将容量和扩容阈值左移一位，扩大 为原来的两倍
        else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                 oldCap >= DEFAULT_INITIAL_CAPACITY)
            newThr = oldThr << 1; // double threshold
    }//第二种情况 初始化，（调用了单个构造函数的情况，传入了初始化容量，进行初始化）
    else if (oldThr > 0) // initial capacity was placed in threshold
        //这个时候的oldThr可以从之前的构造函数看到threshold = tableSizeFor(initialCapacity)
        newCap = oldThr;
    else {               // zero initial threshold signifies using defaults
        //第三种情况 初始化，使用默认无参构造函数初始化的时候，容量和扩容阈值都使用默认值
        newCap = DEFAULT_INITIAL_CAPACITY;
        newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
    }
    //初始化的时候计算新的扩容阈值
    if (newThr == 0) {
        float ft = (float)newCap * loadFactor;
        newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                  (int)ft : Integer.MAX_VALUE);
    }
    //赋值，扩容阈值
    threshold = newThr;

    //这里可以看到，hashMap扩容是申请一个两倍大小的数组
    //将之前的数据一个个重新进行计算再放进去，非常耗时间
    @SuppressWarnings({"rawtypes","unchecked"})
    Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
    table = newTab;
    if (oldTab != null) {
        for (int j = 0; j < oldCap; ++j) {
            Node<K,V> e;
            if ((e = oldTab[j]) != null) {
                oldTab[j] = null;
                if (e.next == null)
                    newTab[e.hash & (newCap - 1)] = e;
                else if (e instanceof TreeNode)
                    ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                else { // preserve order
                    Node<K,V> loHead = null, loTail = null;
                    Node<K,V> hiHead = null, hiTail = null;
                    Node<K,V> next;
                    do {
                        next = e.next;
                        if ((e.hash & oldCap) == 0) {
                            if (loTail == null)
                                loHead = e;
                            else
                                loTail.next = e;
                            loTail = e;
                        }
                        else {
                            if (hiTail == null)
                                hiHead = e;
                            else
                                hiTail.next = e;
                            hiTail = e;
                        }
                    } while ((e = next) != null);
                    if (loTail != null) {
                        loTail.next = null;
                        newTab[j] = loHead;
                    }
                    if (hiTail != null) {
                        hiTail.next = null;
                        newTab[j + oldCap] = hiHead;
                    }
                }
            }
        }
    }
    return newTab;
}
```



* get(Object key)

```java
public V get(Object key) {
        Node<K,V> e;
    	//使用key调用getnode方法，不为空则返回value，否则返回null
        return (e = getNode(hash(key), key)) == null ? null : e.value;
}

//实际去hash表里通过key查数据的方法
final Node<K,V> getNode(int hash, Object key) {
        Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
    	//将table赋值给tab，如果hash表不为空而且长度不为0，通过hash值计算下标找第一个元素，不为空继续往下走，为空返回null
    	//这里可以看到hashmap是怎么通过hash值计算得到实际的数组下标的（length-1 & hash）将key的hash值与数组长度-1进行按位与
    	//（2的n次幂-1后二进制全是1，全是1能够保证数据均匀分布，如果有一些位置为0，对应的一些数组位置永远都不会有数据）
        if ((tab = table) != null && (n = tab.length) > 0 &&
            (first = tab[(n - 1) & hash]) != null) {
            //通过下标找到了第一个元素，这里要将key值进行比较，有可能不同的key值hash值相同
            if (first.hash == hash && // always check first node
                ((k = first.key) == key || (key != null && key.equals(k))))
                //如果第一元素的key值等于我们要找的key值，返回
                return first;
            //第一个元素的key值不等于我们要找的key值，hash表使用链表或红黑树往下存的，直接找下一个节点
            if ((e = first.next) != null) {
                //如果下一节点不为空，需要判断它属于树节点还是链表节点，
                if (first instanceof TreeNode)
                    //走树节点查找逻辑 找到则返回  否则返回null
                    return ((TreeNode<K,V>)first).getTreeNode(hash, key);
                do {
                    //走链表节点查找逻辑 找到则返回  否则返回null
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        return e;
                } while ((e = e.next) != null);
            }
        }
        return null;
}
```



* put(K key, V value)

```java
    public V put(K key, V value) {
        return putVal(hash(key), key, value, false, true);
    }

	//@param onlyIfAbsent if true, don't change existing value 
    //@param evict if false, the table is in creation mode. 
    final V putVal(int hash, K key, V value, boolean onlyIfAbsent, boolean evict) {
        Node<K,V>[] tab; Node<K,V> p; int n, i;
        //如果tab为null或length为0，则进行扩容，这里可以看到hashmap初始化时在第一次put时，而不是构造时
        if ((tab = table) == null || (n = tab.length) == 0)
            n = (tab = resize()).length;
        
        //计算出下标后通过下标取值，如果tab[i]==null则直接new 一个node
        if ((p = tab[i = (n - 1) & hash]) == null)
            tab[i] = newNode(hash, key, value, null);
        else {
            //tab[i]不为空 这里是在map里找到匹配的key的node 并且赋值给e
            //这里匹配node的逻辑和getNode类似，比较hash和key值，并且分树和链表走不同的查找逻辑，找不到会新增一个node返回
            Node<K,V> e; K k;
            if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
                e = p;
            else if (p instanceof TreeNode)
                //树
                e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
            else {
                //链表  顺着链表一直往下找，直到找到匹配key的值更新或p.next==null新增
                for (int binCount = 0; ; ++binCount) {//计算node个数
                    if ((e = p.next) == null) {//如果为空 直接在链表后面新建一个node
                        p.next = newNode(hash, key, value, null);
                        //判断是否需要树化
                        if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                            //注意这里，方法里面会判断table.length太小小于MIN_TREEIFY_CAPACITY，会进行扩容 而不是树化
                            treeifyBin(tab, hash);
                        break;
                    }
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        break;
                    p = e;
                }
            }
            //找到匹配的key
            if (e != null) { // existing mapping for key
                //旧值
                V oldValue = e.value;
                if (!onlyIfAbsent || oldValue == null)
                    //如果可以改变存在值或者旧的值为null，则将value覆盖旧值
                    e.value = value;
                afterNodeAccess(e);
                return oldValue;
            }
        }
        ++modCount;
        //put完后 判断是否需要扩容
        if (++size > threshold)
            resize();
        afterNodeInsertion(evict);
        return null;
    }
```





1. 为什么这里需要将高位数据移位到低位进行异或运算呢？

这是因为有些数据计算出的哈希值差异主要在高位，而 HashMap 里的哈希寻址是忽略容量以上的高位的，那么这种处理就可以有效避免类似情况下的哈希碰撞。高位与低位进行异或，让高位也得以参与散列运算，使得散列更加均匀

2. 红黑树转换？

关于红黑树的转化，HashMap做了以下限制。

- 当链表的长度>=8且数组长度>=64时，会把链表转化成红黑树。
- 当链表长度>=8，但数组长度<64时，会优先进行扩容，而不是转化成红黑树。
- 当红黑树节点数<=6，自动转化成链表。

**为什么需要数组长度到64才会转化红黑树？**当数组长度较短时，如16，链表长度达到8已经是占用了最大限度的50%，意味着负载已经快要达到上限，此时如果转化成红黑树，之后的扩容又会再一次把红黑树拆分平均到新的数组中，这样非但没有带来性能的好处，反而会降低性能。所以在数组长度低于64时，优先进行扩容。

**为什么要大于等于8转化为红黑树，而不是7或9？**

树节点的比普通节点更大，在链表较短时红黑树并未能明显体现性能优势，反而会浪费空间，在链表较短是采用链表而不是红黑树。在理论数学计算中（装载因子=0.75），链表的长度到达8的概率是百万分之一；把7作为分水岭，大于7转化为红黑树，小于7转化为链表。红黑树的出现是为了在某些极端的情况下，抗住大量的hash冲突，正常情况下使用链表是更加合适的。

3. **扩容方案** 

装载因子=HashMap中节点数/数组长度，默认0.75。在理论计算中，0.75是一个比较合适的数值，大于0.75哈希冲突的概率呈指数级别上升，而小于0.75冲突减少并不明显。HashMap中的装载因子的默认大小是0.75，没有特殊要求的情况下，不建议修改他的值。

**HashMap是如何进行扩容的呢？**HashMap会把数组长度扩展为原来的两倍，再把旧数组的数据迁移到新的数组，而HashMap针对迁移做了优化：使用HashMap数组长度是2的整数次幂的特点，以一种更高效率的方式完成数据迁移。

JDK1.7之前的数据迁移比较简单，就是遍历所有的节点，把所有的节点依次通过hash函数计算新的下标，再插入到新数组的链表中。这样会有两个缺点：1、每个节点都需要进行一次求余计算；2、插入到新的数组时候采用的是**头插入法**，在多线程环境下会形成链表环。jdk1.8之后进行了优化，原因在于他控制数组的长度始终是2的整数次幂，每次扩展数组都是原来的2倍，带来的好处是key在新的数组的hash结果只有两种：在原来的位置，或者在原来位置+原数组长度。



4. 线程安全

HashMap并不是线程安全的，在多线程的情况下无法保证数据的一致性

jdk1.7及以前扩容时采用的是头插法，这种方式插入速度快，但在多线程环境下会造成链表环，而链表环会在下一次插入时找不到链表尾而发生死循环。

那如果结果数据一致性问题呢？解决这个问题有三个方案：

- 采用Hashtable
- 调用Collections.synchronizeMap()方法来让HashMap具有多线程能力
- 采用ConcurrentHashMap





5. HashMap中，拓展了拥有这些特性的其他集合类作为补充：

- 线程安全的ConcurrentHashMap、Hashtable、SynchronizeMap
- 记住插入顺序的LinkedHashMap
- 记录key顺序的TreeMap







### java中byte数组不能作为map的key使用

用byte数组作为map的key来使用,发现在遍历的时候get到之前传进去的值总是为空,很是困惑,后来查了下资料发现java中的字节数组不能直接作为map的key来使用. 原因是这样的,当使用`byte[]`作为key的时候,map会对这个字节数组的地址进行hashcode得到一个值作为key,而不是以内容作为它的key,所以两次byte数组地址不一样的话,得到的结果就会完全不同.

[java中byte数组不能作为map的key使用](http://www.yangtaotech.cn/post/java_map_key.html)









[厉害了！把 HashMap 剖析的只剩渣了！](https://juejin.cn/post/6902793228026642446)

[深入解析ConcurrentHashMap：感受并发编程智慧](https://juejin.cn/post/6904078580129464334)

