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

* C字符串并不记录自身的长度信息，所以为了获取一个C字符串的长度，程序必须遍历整个字符串，对遇到的每个字符进行计数，直到字符串结果的空字符为止，这个操作的时间复杂度为O(n)，而SDS里面程序只要访问SDS的len属性，就可以立即知道长度信息。时间复杂度为O(1)。r**edis将获取字符串长度所需的复杂度从O(n)降到了O(1)**，所以即使我们对一个非常长的字符串键反复执行STRLEN命令，也不会对系统性能造成任何影响。

* **杜绝缓冲区溢出**，C字符串不记录自身长度带来的另一个问题是容易造成缓冲区溢出。当SDSAPI需要对SDS进行修改时，API会检查SDS的空间是否满足修改所需的要求，如果不满足的话，会自动将SDS的空间扩展至执行修改所需的大小然后才执行实际的修改操作。
* **SDS的空间预分配**（内存分配设计复杂的算法，并且可能需要执行系统调用，所以通常是一个比较耗时的操作）。	当对SDS进行修改后，SDS的长度也即len属性的值，将小于1MB，那么程序会分配和len大小同样大小的未使用空间，这时SDS的len属性会和free属性相同；如将SDS改成13字节，那么程序也会分配13字节的未使用空间，SDS字符数组的实际长度为13+13+1=27字节，额外的一字节保存空字符。如果对SDS修改后，SDS的长度大于等于1MB，那么程序分配1MB的未使用空间；比如修改后len的长度变为30MB，那么程序会分1MB的未使用空间，SDS的buf数组实际长度为30MB+1MB+1byte。通过空间预分配策略，redis减少了连续执行字符串增长操作所需的内存重分配次数。
  
* **惰性空间释放**。惰性空间释放用于优化SDS字符串的缩短操作，当SDS的API需要缩短SDS保存的字符串时，程序并不立即使用内存重分配来回收缩短后多出来的字节，而是使用free属性将这些字节的数量记录起来，并等待将来使用。通过惰性空间释放的策略，SDS避免了缩短字符串时所需的内存重分配操作，并为将来可能有的增长操作提供了优化，同时SDS也提供了对应的API，让我们在有需要时真正的释放SDS未使用的空间，所以不用担心惰性空间释放策略会造成内存浪费。
  
* 二进制安全，SDS使用len的属性值而不是空字符来判断字符串是否结束，使得redis不仅可以保存文本数据，还可以保存任意二进制的数据。
* 兼容部分C字符串函数



#### 2. 链表

​		列表键的底层实现之一就是链表。当一个列表键的元素较多，或者列表中包含的元素都是比较长的字符串时，Redis就会使用链表作为列表键的底层实现数据结构。

​		发布与订阅、慢查询、监视器等功能也用到了链表，Redis本身还使用了链表来保存多个客户端的状态信息，以及使用链表来构建客户端输出缓冲区(缓冲区)。

​		每个链表节点使用一个`adlist.h/listNode`结构来表示，多个listNodek可以通过prev和next指针组成**双端链表**。

```c
/*
 * 双端链表节点
 */
typedef struct listNode {

    // 前置节点
    struct listNode *prev;

    // 后置节点
    struct listNode *next;

    // 节点的值
    void *value;

} listNode;

```

​		使用`adlist.h/list`里持有链表的话，会更加方便

```c
/*
 * 双端链表结构
 */
typedef struct list {

    // 表头节点
    listNode *head;

    // 表尾节点
    listNode *tail;

    // 节点值复制函数  复制链表节点所保存的值
    void *(*dup)(void *ptr);

    // 节点值释放函数  释放链表节点所保存的值
    void (*free)(void *ptr);

    // 节点值对比函数  用于对比链表节点的值是否与另一个输入值相等
    int (*match)(void *ptr, void *key);

    // 链表所包含的节点数量
    unsigned long len;

} list;
```

Redis的链表实现的特性总结如下：

* 双端：链表节点带有prev和next指针
* 无环：表头的prev和表尾的next指针指向null,对链表的访问以null为终点
* 带表头指针和表尾指针：list结构里面维护了表头指针和表尾指针，获取表头表尾的复杂的为O(1)
* 带链表长度计数器： list结构里面的len属性维护了链表的长度，获取链表长度的操作时间复杂度为O(1)
* 多态：链表指针使用了 void*指针来保存节点的值，并且可以通过list的dup,free,match三个属性为节点值设置类型特定函数，所以链表可以用于保存各种不同类型的值



#### 3. 字典

​		Redis数据库的键空间是使用字典来实现的，字典也是Redis哈希键的底层实现之一。当一个哈希键包含的键值对比较多，又或者键值对中的元素都是比较长的字符串时，哈希键就会使用字典来作为底层的数据结构。

​		Redis的字典使用哈希表作为底层实现。

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

​		dict的ht属性是一个包含两个项的数组，数组中的每一个项都是一个哈希表dictht,一般情况下，字典只使用ht[0]哈希表，ht[1]哈希表只会在对ht[0]哈希表进行rehash时使用。

​		除了ht[1]外，另一个和rehash有关的属性就是rehashidx，它记录了rehash目前的进度，如果目前没有在rehash，那么它的值为-1。

​		Redis使用的是MurmurHash2哈希算法。当字典被用作数据库的底层实现，或者哈希键的底层实现时，使用MurmurHash2算法来计算键的哈希值。

​		**Redis使用链地址法解决哈希冲突**，因为dictEntry节点没有指向链表表尾的指针，所以为了速度考虑，程序总是将新节点保存在链表的头部（**头插法**，时间复杂度为O(1)）

​		**Redis字典的rehash**:

* 为字典的ht[1]哈希表分配空间，这个哈希表的空间大小取决于要执行的操作，以及ht[0]当前包含的键值对的数量（也即是ht[0].used）属性的值：
  * 如果执行的是扩展操作，那么ht[1]的大小为第一个大于等于ht[0].used*2的2<sup>n</sup>
  * 如果执行的是收缩操作，那么ht[1]的大小为第一个大于等于ht[0].used的2<sup>n</sup>
* 将保存在ht[0]中的所有的键值对rehash到hash[1]上面：rehash指的是重新计算key的哈希值和索引值，然后将键值对放置到ht[1]的指定位置上。（说的太笼统了 实际上rdis的这个过程称为**渐进式hash**，详细了解见下文）
* 当ht[0]里面所有的键值对都移动到了ht[1]之后，释放ht[0]，并将ht[1]设置为ht[0]，并在ht[1]新创建一个空白哈希表，为下一次rehash做准备。



​		**哈希表的扩展与收缩**：

* 服务器目前没有执行bgsave或者bgrewriteaof命令，并且哈希表的负载因子大于等于1
* 服务器目前正在执行bgsave或者bgrewriteaof命令，并且哈希表的负载因子大于等于5
* 哈希表的负载因子在小于0.1时，程序自动开始对哈希表执行收缩操作。



​		**渐进式rehash**

​		之前我们说过rehash的过程中，需要将ht[0]里面的所有键值对rehash到ht[1]中，但是这个动作并不是集中式的、一次性的；而是分多次，渐进式的。这样做的原因在于假设字典里面的键值对数量非常多，要一次性的rehash的话庞大的计算量可能导致服务器在一段时间内停止服务。下面是渐进式rehash的详细步骤：

* 为ht[1]分配空间，让字典同时拥有ht[0]和ht[1]两个哈希表
* 在字典中维持一个索引计数器变量rehashidx，并将它的值设置为0，表示rehash操作正式开始
* 在rehash进行期间，每次对字典执行添加、删除、修改操作时，程序除了执行指定的操作以外，还会顺带将ht[0]哈希表在rehashidx索引上的所有键值对rehash到ht[1]，当rehash操作完成后，rehashidx的值增加1.
* 随着字典的不断执行，最终在某个时间点上，ht[0]的所有键值对被rehash到ht[1]上，这是程序将rehashidx的值置为-1，表示rehash的操作已完成。

​		渐进式rehash的好处在于采取分而治之的方式，将rehash键值对所需要的计算工作均摊到字典的每个增加删除修改查找操作上，从而避免了集中式rehash而带来的庞大的计算量。

> ​	因为在渐进式hash中，字典会维护两个hash表，ht[0],ht[1]两个哈希表，所以在渐进式hash中，字典的删除、查找、更新操作会在两个hash表中进行。例如，如果需要查找一个键的话，程序会现在ht[0]查找，如果没找到的话然后再到ht[1]查找。
>
> ​	另外在渐进式hash执行期间，新添加到字典的键值对一律会被保存到ht[1]中，而ht[0]不会再添加任务元素，这一措施保证了ht[0]的元素只减不增，并随着rehash的操作的执行而最终变成空的。



#### 4. 跳跃表

​		Redis使用跳跃表作为有序集合键的底层实现之一，如果一个有序集合包含的元素较多，又或者有序集合中的元素成员是比较长的字符串时，Redis就会使用跳跃表来作为有序集合键的底层实现。Redis只在两个地方用到了跳跃表，一个是实现有序集合键，还有一个是在集群节点中用作内部数据结构。

​		Redis的跳跃表由`redis.h/zskiplistnode`和`redis.h/zskiplist`两个结构定义

```c

/*
 * 跳跃表
 */
typedef struct zskiplist {

    // 表头节点和表尾节点
    struct zskiplistNode *header, *tail;

    // 表中节点的数量
    unsigned long length;

    // 表中层数最大的节点的层数
    int level;

} zskiplist;

/* ZSETs use a specialized version of Skiplists */
/*
 * 跳跃表节点
 */
typedef struct zskiplistNode {

    // 成员对象
    robj *obj;

    // 分值
    double score;

    // 后退指针
    struct zskiplistNode *backward;

    // 层
    struct zskiplistLevel {

        // 前进指针
        struct zskiplistNode *forward;

        // 跨度
        unsigned int span;

    } level[];

} zskiplistNode;
```



#### 5. 整数集合	

​		整数集合(intset)是集合键的底层实现之一，当一个集合中只包含证书键，并且这个集合的元素不多时，Redis就会使用整数集合作为集合键的底层实现。

​		每个`intset.h/intset`结构表示一个整数集合

```c
typedef struct intset {
    
    // 编码方式
    //INTSET_ENC_INT16、INTSET_ENC_INT32、INTSET_ENC_INT64
    uint32_t encoding;

    // 集合包含的元素数量
    uint32_t length;

    // 保存元素的数组
    int8_t contents[];

} intset;
```

​		Contents是整数集合的底层实现: 整数集合的每个元素都是contents数组的一个数组项(item)，各个项在数组中按值得大小从小到大有序排列，并且数组中不包含重复项。length记录了整数集合包含的元素数量，也即是contents数组的长度。contents数组真正的类型取决于encoding属性的值。

​		整数集合的升级：每当我们要将一个新元素添加到整数集合里面去时，并且新元素的类型比整数集合现有所有元素的类型都要长时，整数集合需要先进行升级(upgrade)，然后才能将新元素添加到整数集合里面。

​		升级步骤: 

* 根据新元素的类型，扩展整数集合底层数组的大小，并为新元素分配空间。

* 将底层所有现有的元素，转换为和新元素类型相同的类型，并将类型转换后的元素放置到正确的位置上，而且在放置元素的过程中，需要维持底层数组有序的性质不变。

* 将新元素添加到底层数组。

  **升级的好处：提示灵活性、节约内存。注意整数集合不支持降级**



#### 6. 压缩列表

​		压缩列表(ziplist)是列表键和哈希键的底层实现之一。当一个列表键只包含少量列表项，并且每个列表项要么就是小整数值，要么就是长度比较短的字符串，那么Redis就会使用压缩列表来做列表键的底层实现。

​		压缩列表是Redis为了节约内存开发的，是由一系列特殊编码的连续内存块组成的顺序型(sequential)数据结构。一个压缩列表可以包含任意多个节点(entry)，每个节点可以保存一个字节数组或者一个整数值。

```c
/*
 * 保存 ziplist 节点信息的结构
 */
typedef struct zlentry {

    // prevrawlen ：前置节点的长度
    // prevrawlensize ：编码 prevrawlen 所需的字节大小
    unsigned int prevrawlensize, prevrawlen;

    // len ：当前节点值的长度
    // lensize ：编码 len 所需的字节大小
    unsigned int lensize, len;

    // 当前节点 header 的大小
    // 等于 prevrawlensize + lensize
    unsigned int headersize;

    // 当前节点值所使用的编码类型
    unsigned char encoding;

    // 指向当前节点的指针
    unsigned char *p;

} zlentry;

```



### 二. 对象

​		前面我们介绍了Redis实现的一些底层数据结构，但是Redis并没有直接用这些数据结构来实现键值对数据库，而是基于这些数据结构创建了一个对象系统。这个系统包含**字符串对象、列表对象、哈希对象、集合对象、有序集合对象这五种类型的对象**，每种对象都用到了至少一种我们前面所介绍的数据结构。

​		Redis使用对象来表示数据库中的键和值，每次当我们在Redis的数据库中新创建一个键值对时，至少会创建两个对象，一个对象用作键值对的键（键对象），另一个对象用作键值对的值（值对象）。Redis中的每一个对象都由一个redisObject结构表示，该结构中和保存数据有关的由三个属性，分别时type属性、encoding属性、ptr属性:

```c
/* Object types */
// 对象类型
#define REDIS_STRING 0  //TYPE命令输出  string
#define REDIS_LIST 1	//TYPE命令输出  list
#define REDIS_SET 2		//TYPE命令输出  set
#define REDIS_ZSET 3	//TYPE命令输出  zset
#define REDIS_HASH 4	//TYPE命令输出  hash

/* Objects encoding. Some kind of objects like Strings and Hashes can be
 * internally represented in multiple ways. The 'encoding' field of the object
 * is set to one of this fields for this object. */
// 对象编码
#define REDIS_ENCODING_RAW 0     /* Raw representation */ //OBJECT ENCODING命令输出  raw
#define REDIS_ENCODING_INT 1     /* Encoded as integer */  //OBJECT ENCODING命令输出  int
#define REDIS_ENCODING_HT 2      /* Encoded as hash table */  //OBJECT ENCODING命令输出  hashtable
#define REDIS_ENCODING_ZIPMAP 3  /* Encoded as zipmap */  //OBJECT ENCODING命令输出  --
#define REDIS_ENCODING_LINKEDLIST 4 /* Encoded as regular linked list */  //OBJECT ENCODING命令输出  linkedlist
#define REDIS_ENCODING_ZIPLIST 5 /* Encoded as ziplist */  //OBJECT ENCODING命令输出  ziplist
#define REDIS_ENCODING_INTSET 6  /* Encoded as intset */  //OBJECT ENCODING命令输出  intset
#define REDIS_ENCODING_SKIPLIST 7  /* Encoded as skiplist */  //OBJECT ENCODING命令输出  skiplist
#define REDIS_ENCODING_EMBSTR 8  /* Embedded sds string encoding */  //OBJECT ENCODING命令输出  embstr


/* A redis object, that is a type able to hold a string / list / set */

/* The actual Redis Object */
/*
 * Redis 对象
 */
#define REDIS_LRU_BITS 24
#define REDIS_LRU_CLOCK_MAX ((1<<REDIS_LRU_BITS)-1) /* Max value of obj->lru */
#define REDIS_LRU_CLOCK_RESOLUTION 1000 /* LRU clock resolution in ms */
typedef struct redisObject {

    // 类型
    unsigned type:4;

    // 编码
    unsigned encoding:4;

    // 对象最后一次被访问的时间
    unsigned lru:REDIS_LRU_BITS; /* lru time (relative to server.lruclock) */

    // 引用计数
    int refcount;

    // 指向实际值的指针
    void *ptr;

} robj;
```

​		使用type命令可以查看当前键值对的值类型: TYPE key

​		使用object encoding命令可以查看一个数据库键的值对象编码：OBJECT ENCODING key

​		不同类型编码对应的对象：

| 类型         | 编码                      | 对象                                           |
| ------------ | ------------------------- | ---------------------------------------------- |
| REDIS_STRING | REDIS_ENCODING_INT        | 使用整数值实现的字符串对象                     |
| REDIS_STRING | REDIS_ENCODING_EMBSTR     | 使用embstr编码的简单动态字符串实现的字符串对象 |
| REDIS_STRING | REDIS_ENCODING_RAW        | 使用简单动态字符串实现的字符串对象             |
| REDIS_LIST   | REDIS_ENCODING_ZIPLIST    | 使用压缩列表实现的列表对象                     |
| REDIS_LIST   | REDIS_ENCODING_LINKEDLIST | 使用双端列表实现的列表对象                     |
| REDIS_HASH   | REDIS_ENCODING_ZIPLIST    | 使用压缩列表实现的哈希对象                     |
| REDIS_HASH   | REDIS_ENCODING_HT         | 使用字典实现的哈希对象                         |
| REDIS_SET    | REDIS_ENCODING_INTSET     | 使用整数集合实现的集合对象                     |
| REDIS_SET    | REDIS_ENCODING_HT         | 使用字典实现的集合对象                         |
| REDIS_ZSET   | REDIS_ENCODING_ZIPLIST    | 使用压缩列表实现的有序集合对象                 |
| REDIS_ZSET   | REDIS_ENCODING_SKIPLIST   | 使用跳表实现的有序集合对象                     |

​		通过encoding属性来设置对象的编码，而不是为特定类型的对象关联一种固定的编码，极大的提升了Redis的灵活性和效率。可以根据不同的使用场景来为一个对象设置不同的编码，从而优化对象在某一场景下的效率.

#### 1. 字符串对象

​		字符串对象的编码可以是`int`,`raw`,或者`embstr`

* 如果一个字符串对象保存的是整数值，并且这个整数值可以用long类型来表示，那么字符串对象的编码会设置为`int`；

* 如果一个字符串对象保存的是一个字符串值，并且这个字符串值的长度大于32字节，那么字符串对象会使用SDS来保存这个字符串，并将对象的编码设置为`raw`；

* 如果一个字符串对象保存的是一个字符串值，并且这个字符串值得长度小于32字节，那么字符串对象会使用`embstr`编码的方式来保存这个字符串的值。

​		embstr编码是专门用于保存短字符串的一种编码，它的底层实现和`raw`一样，都是使用redisObject结构和sdshdr结构来表示字符串对象，但不一样的是row编码会调用两次内存分配函数来分别创建redisObject和sdshdr结构，而embstr编码则通过调用一次内存分配函数来分配一块连续的空间，空间中依次包含redisObject和sdshdr两个结构（内存释放的时候同样如此）。还有要注意的是，**给embstr编码的字符串作修改操作时，会转变成`raw`编码，相当于embstr编码是只读的，因为Redis没有为embstr编码的字符串对象编写任何相应的修改程序**

​		同样，如果我们对int编码的字符串对象执行一些修改使得这个对象保存的不再是long类型的值，也会转为`raw`编码。



#### 2. 列表对象

​		列表对象的编码可以是`ziplist`或者`linkedlist`

​		当列表对象同时满足以下两个条件时，列表对象使用`ziplist`编码：

* 列表对象保存的所有字符串元素的长度都小于64字节
* 列表对象保存的元素数量小于512个；

​		不能满足这两个条件的列表对象需要使用`linkedlist`编码

​		这两个条件的值可以修改的，配置文件中`list-max-ziplist-value`和`list-max-ziplist-entries`选项



#### 3. 哈希对象

​		哈希对象的编码可以是`ziplist`,`hashtable`

​		当哈希对象同时满足以下两个条件时，哈希对象使用`ziplist`编码

- 哈希对象保存的所有键值对的键和值的字符串的长度都小于64字节
- 哈希对象保存的元素数量小于512个；

​		不能满足这两个条件的列表对象需要使用`hashtable`编码

​		这两个条件的值可以修改的，配置文件中`hash-max-ziplist-value`和`hash-max-ziplist-entries`选项



#### 4. 集合对象

​		集合对象的编码可以是`intset`,`hashtable`

​		当哈集合对象同时满足以下两个条件时，集合对象使用`intset`编码

* 集合对象保存的所有元素都是整数值

* 集合对象保存的元素数量不超过512个

  不能满足这两个条件的列表对象需要使用`hashtable`编码

  这个条件的值可以修改的，配置文件中`set-max-intset-entries`选项



#### 5. 有序集合对象

​		有序集合的编码可以是`ziplist`,`skiplist`

​		`skiplist`编码的有序集合对象使用zset结构作为底层实现，一个zset同时包含一个字典和一个跳跃表

```c
/*
 * 有序集合
 */
typedef struct zset {

    // 字典，键为成员，值为分值
    // 用于支持 O(1) 复杂度的按成员取分值操作
    dict *dict;

    // 跳跃表，按分值排序成员
    // 用于支持平均复杂度为 O(log N) 的按分值定位成员操作
    // 以及范围操作
    zskiplist *zsl;

} zset;
```

​		zset结构中的跳跃表按分支从小到大保存了所有集合元素，每个跳跃表节点都保存了一个集合元素：跳跃表节点的object属性保存了元素的成员，而跳跃表节点的score属性则保存了元素的分值。通过这个跳跃表，程序可以对有序集合进行范围型操作，比如ZRANK,ZRANGE等命令就是基于跳跃表API实现的。

​		初次之外，zset结构中的dict字典为有序集合创建了一个从成员到分值的映射，字典中的每一个键值对都保存了一个集合元素：字典的键保存了元素的成员，而字典的值则保存了元素的分值。通过这个字典，程序可以用0(1)复杂度查找给定成员的分值，ZSCORE命令就是根据这一特性实现的，而很多其他有序集合命令都在实现的内部用到了这一特性。

​		值得一提的是，虽然zset结构同时使用跳跃表和字典来保存有序集合元素，但这两种数据结构都会通过指针来共享相同的成员和分值，所以同时使用跳跃表和字典来保存集合元素不会产生任何重复的成员或者分值，也不会因此浪费额外的内存。

​		实际上这个单独一种字典或者跳表都可以实现zset,为什么zset需要同时使用跳跃表和字典来实现？因为无论单独使用哪一种数据结构，性能都没有同时使用这两种好，字典可以让我们用0(1)复杂度查找给定成员的分值，而跳表用来执行有序范围性操作。

​		编码的转换：

​		当有序集合对象同时满足以下两个条件时，对象使用ziplist编码

* 有序集合保存的数量小于128个

* 有序集合保存的所有元素成员的长度都小于64字节。

  不能同时满足以上条件的有序集合对象将使用`skiplist`编码





### 三. redis数据库

#### 		1. 数据库键空间

​		Redis是一个键值对(key-value pair)数据库服务器，服务器中的每个数据库都由一个`redis.h/redisDB`结构表示，其中，redisDb结构的dict字典保存了数据库中的所有键值对，我们将这个字典称为键空间(key space)

```c
typedef struct redisDb {

    // 数据库键空间，保存着数据库中的所有键值对
    dict *dict;                 /* The keyspace for this DB */

    // 键的过期时间，字典的键为键，字典的值为过期事件 UNIX 时间戳
    dict *expires;              /* Timeout of keys with a timeout set */

    // 正处于阻塞状态的键
    dict *blocking_keys;        /* Keys with clients waiting for data (BLPOP) */

    // 可以解除阻塞的键
    dict *ready_keys;           /* Blocked keys that received a PUSH */

    // 正在被 WATCH 命令监视的键
    dict *watched_keys;         /* WATCHED keys for MULTI/EXEC CAS */

    struct evictionPoolEntry *eviction_pool;    /* Eviction pool of keys */

    // 数据库号码
    int id;                     /* Database ID */

    // 数据库的键的平均 TTL ，统计信息
    long long avg_ttl;          /* Average TTL, just for stats */

} redisDb;
```

数据库键空间的例子：

![数据库键空间的例子.png](http://ww1.sinaimg.cn/large/0072fULUgy1gqfmp5ze6hj30mj0avdh4.jpg)



​		实际上所有针对数据库的操作，都是通过对键空间字典进行操作来实现的。当使用命令对Redis数据库进行一些操作的时候，服务器不仅会对键空间执行指定的读写操作，还会执行一些额外的操作，比如：

* 读取一个键之后，服务器会根据键是否存在来更新服务器的键空间命中（hit）次数或键空间的不命中次数（miss）次数，这两个值可以在INFO status命令的`keyspace_hits`属性和`keyspace_miss`属性中查看。
* 在读取一个键之后，服务器会更新键的LRU（最近最后一次使用时间），可以值可以用来计算键的闲置时间，使用OBJECT idletime <key>命令可以查看key的闲置时间。
* 如果服务器在读取一个键后发现该键已经过期，那么服务器会先删除这个过期键(后面详细说明)
* 如果有客户端使用watch命令监视了这个键，那么服务器在对被监视的键进行修改之后，会把这个键标记为脏（dirty）,从而让事务程序注意到这个键已经被修改。
* 服务器每次修改一个键都会对脏（dirty）计数器的值增1，这个计数器会触发服务器的持久化以及复制操作，详情见redis持久化
* 服务器如果开启了数据库通知功能，那么在对键进行修改过后，服务器会按配置发送相应的数据库通知。



#### 		2. 设置过期时间

​		Redis有四种不同的方式设置过期时间

* EXPIRE key seconds: 为给定 `key` 设置生存时间，当 `key` 过期时(生存时间为 `0` )，它会被自动删除
* EXPIREAT key timestamp: `EXPIREAT` 命令接受的时间参数是 UNIX 时间戳(unix timestamp)。
* PEXPIRE key milliseconds: 这个命令和 `EXPIRE` 命令的作用类似，但是它以毫秒为单位设置 `key` 的生存时间
* PEXPIREAT key milliseconds-timestamp: 这个命令和 `expireat` 命令类似，但它以毫秒为单位设置 `key` 的过期 unix 时间戳。



虽然有多种不同单位和不同形式的设置命令，但是前面三种都会转换为使用`pexpireat` 命令来实现的。

reidsDb的数据结构的expires字典保存了数据库键的所有过期时间，我们称这个字典为过期字典

`PERSIST key`命令可以移除key的过期时间：

移除给定 `key` 的生存时间，将这个 `key` 从“易失的”(带生存时间 `key` )转换成“持久的”(一个不带生存时间、永不过期的 `key` )。

可以用`TTL`命令和`PTTL`来计算key的剩余生存空间。

过期键的判定： 

​	1）判断给定键是否存在于过期字典：如果存在，那么取得键的过期时间。

​	2）检查当前UNIX时间戳是否大于键的过期时间：如果是的话，那么键已经过期；否则的话，键没有过期



#### 		3. 过期键删除策略

* 定时删除：在设置键的过期时间的同时，创建一个timer，让定时器在键的过期时间到达时，立即执行对键的删除操作。（主动删除）
  对内存友好，但是对cpu时间不友好，有较多过期键的而情况下，删除过期键会占用相当一部分cpu时间。

* 惰性删除：放任过期键不管，但是每次从键空间中获取键时，都检查取到的键是否过去，如果过期就删除，如果没过期就返回该键。（被动删除）
  对cpu时间友好，程序只会在取出键的时候才会对键进行过期检查，这不会在删除其他无关过期键上花费任何cpu时间，但是如果一个键已经过期，而这个键又保留在数据库中，那么只要这个过期键不被删除，他所占用的内存就不会释放，对内存不友好。

* 定期删除：每隔一段时间就对数据库进行一次检查，删除里面的过期键。（主动删除）
  采用对内存和cpu时间折中的方法，每个一段时间执行一次删除过期键操作，并通过限制操作执行的时长和频率来减少对cpu时间的影响。难点在于，选择一个好的策略来设置删除操作的时长和执行频率。



Redis服务器实际上使用的是惰性删除和定期删除两种策略，通过配合使用这两种删除策略，服务器可以很好地在合理使用CPU时间和避免浪费内存空间之间取得平衡。











[redis中文注释版源码](https://github.com/huangz1990/redis-3.0-annotated)

