## redis设计与实现

### 一. redis数据结构

#### 1. 简单字符串对象

​		redis没有直接使用c语言传统的字符串表示，而是自己构建了一种名为简单动态字符串（simple dynamic string ,SDS）的抽象类型，并将SDS用作redis的默认字符串表示。根据传统，c语言使用长度为N+1的字符数组来表示长度为N的字符串，并且字符数组的最后一个元素总是空字符'\0'。

SDS的代码结构：

```c

/*
 * 保存字符串对象的结构
 */
struct sdshdr {
    
    // buf 中已占用空间的长度
    int len;

    // buf 中剩余可用空间的长度
    int free;

    // 数据空间
    char buf[];
};
```

​		SDS比C字符串更适用于redis的原因：

* C字符串并不记录自身的长度信息，所以为了获取一个C字符串的长度，程序必须遍历整个字符串，对遇到的每个字符进行计数，知道字符串结果的空字符为止，这个操作的时间复杂度为O(n)，而SDS里面程序只要访问SDS的len属性，就可以立即知道长度信息。时间复杂度为O(1)。r**edis将获取字符串长度所需的复杂度从O(n)降到了O(1)**，所以即使我们对一个非常长的字符串键反复执行STRLEN命令，也不会对系统性能造成任何影响。

* **杜绝缓冲区溢出**，C字符串不记录自身长度带来的另一个问题是容易造成缓冲区溢出。当SDSAPI需要对SDS进行修改时，API会检查SDS的空间是否满足修改所需的要求，如果不满足的话，会自动将SDS的空间扩展至执行修改所需的大小然后才执行实际的修改操作。

  * **SDS的空间预分配**（内存分配设计复杂的算法，并且可能需要执行系统调用，所以通常是一个比较耗时的操作）。	当对SDS进行修改后，SDS的长度也即len属性的值，将小于1MB，那么程序会分配和len大小同样大小的未使用空间，这是SDS的len属性会和free属性相同；如将SDS改成13字节，那么程序也会分配13字节的未使用空间，SDS字符数组的实际长度为13+13+1=27字节，额外的一字节保存空字符如果对SDS修改后，SDS的长度大于等于1MB，那么程序分配1MB的未使用空间；比如修改后len的长度变为30MB，那么程序会分1MB的未使用空间，SDS的buf数组实际长度为30MB+1MB+1byte。通过空间预分配策略，redis减少了连续执行字符串增长操作所需的内存重分配次数。

  * **惰性空间释放**。惰性空间释放用于优化SDS字符串的缩短操作，当SDS的API需要缩短SDS保存的字符串时，程序并不立即使用内存重分配来回收缩短后多出来的字节，而是使用free属性将这些字节的数量记录起来，并等待将来使用。通过惰性空间释放的策略，SDS避免了缩短字符串时所需的内存重分配操作，并为将来可能有的增长操作提供了优化，同时SDS也提供了对于的API，让我们在有需要时真正的释放SDS未使用的空间，所以不用当心惰性空间释放策略会造成内存浪费。

* 二进制安全，SDS使用len的属性值而不是空字符来判断字符串是否结束，使得redis不仅可以保存文本数据，还可以保存任意二进制的数据。
* 兼容部分C字符串函数



#### 2. 字典



```c

/*
 * 字典
 */
typedef struct dict {

    // 类型特定函数
    dictType *type;

    // 私有数据
    void *privdata;

    // 哈希表
    dictht ht[2];

    // rehash 索引
    // 当 rehash 不在进行时，值为 -1
    int rehashidx; /* rehashing not in progress if rehashidx == -1 */

    // 目前正在运行的安全迭代器的数量
    int iterators; /* number of iterators currently running */

} dict;

/* This is our hash table structure. Every dictionary has two of this as we
 * implement incremental rehashing, for the old to the new table. */
/*
 * 哈希表
 *
 * 每个字典都使用两个哈希表，从而实现渐进式 rehash 。
 */
typedef struct dictht {
    
    // 哈希表数组
    dictEntry **table;

    // 哈希表大小
    unsigned long size;
    
    // 哈希表大小掩码，用于计算索引值
    // 总是等于 size - 1
    unsigned long sizemask;

    // 该哈希表已有节点的数量
    unsigned long used;

} dictht;


/*
 * 哈希表节点
 */
typedef struct dictEntry {
    
    // 键
    void *key;

    // 值
    union {
        void *val;
        uint64_t u64;
        int64_t s64;
    } v;

    // 指向下个哈希表节点，形成链表
    struct dictEntry *next;

} dictEntry;
```





[redis中文注释版源码](https://github.com/huangz1990/redis-3.0-annotated)

