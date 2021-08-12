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
//0.5+0.5+3+8=16字节  即redisObject固定占16个字节
typedef struct redisObject {

    // 类型
    unsigned type:4; //4位  0.5字节

    // 编码
    unsigned encoding:4; //4位  0.5字节

    // 对象最后一次被访问的时间
    unsigned lru:REDIS_LRU_BITS; /* lru time (relative to server.lruclock) 24位 3字节 */

    // 引用计数
    int refcount; //32位  4字节

    // 指向实际值的指针  如sds等  8字节
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

> - `int` 编码
>   当我们用字符串对象存储的是整型，且能用 `8` 个字节的 `long` 类型进行表示（即 `2` 的 `63` 次方减 `1`），则 `Redis` 会选择使用 `int` 编码来存储，此时 `redisObject` 对象中的 `ptr` 指针直接替换为 `long` 类型。我们想想 `8` 个字节如果用字符串来存储只能存 `8` 位，也就是千万级别的数字，远远达不到 `2` 的 `63` 次方减 `1` 这个级别，所以如果都是数字，用 `long` 类型会更节省空间。
> - `embstr` 编码
>   当字符串对象中存储的是字符串，且长度小于 `44` （`Redis 3.2` 版本之前是 `39`）时，`Redis` 会选择使用 `embstr` 编码来存储。
> - `raw` 编码
>   当字符串对象中存储的是字符串，且长度大于 `44` 时，`Redis` 会选择使用 `raw` 编码来存储。
>
> ### embstr 编码为什么从 39 位修改为 44 位
>
> `embstr` 编码中，`redisObject` 和 `sds` 是连续的一块内存空间，这块内存空间 `Redis` 限制为了 `64` 个字节，而`redisObject` 固定占了16字节（上面定义中有标注），`Redis 3.2` 版本之前的 `sds` 占了 `8` 个字节，再加上字符串末尾 `\0` 占用了 `1` 个字节，所以：`64-16-8-1=39` 字节。
>
> `Redis 3.2` 版本之后 `sds` 做了优化，对于 `embstr` 编码会采用 `sdshdr8` 来存储，而 `sdshdr8` 占用的空间只有 `24` 位：`3` 字节（len+alloc+flag）+ `\0` 字符（1字节），所以最后就剩下了：`64-16-3-1=44` 字节。

​		embstr编码是专门用于保存短字符串的一种编码，它的底层实现和`raw`一样，都是使用redisObject结构和sdshdr结构来表示字符串对象，但不一样的是row编码会调用两次内存分配函数来分别创建redisObject和sdshdr结构，而embstr编码则通过调用一次内存分配函数来分配一块连续的空间，空间中依次包含redisObject和sdshdr两个结构（内存释放的时候同样如此）。还有要注意的是，**给embstr编码的字符串作修改操作时，会转变成`raw`编码，相当于embstr编码是只读的，因为Redis没有为embstr编码的字符串对象编写任何相应的修改程序**

​		同样，如果我们对int编码的字符串对象执行一些修改使得这个对象保存的不再是long类型的值，也会转为`raw`编码。

> ### embstr 编码和 raw 编码的区别
>
> `embstr` 编码是一种优化的存储方式，其在申请空间的时候因为 `redisObject` 和 `sds` 两个对象是一个连续空间，所以**「只需要申请 `1` 次空间（同样的，释放内存也只需要 `1` 次）」**，而 `raw` 编码因为 `redisObject` 和 `sds` 两个对象的空间是不连续的，所以使用的时候**「需要申请 `2` 次空间（同样的，释放内存也需要 `2` 次）」**。但是使用 `embstr` 编码时，假如需要修改字符串，那么因为 `redisObject` 和 `sds` 是在一起的，所以两个对象都需要重新申请空间，为了避免这种情况发生，**「`embstr` 编码的字符串是只读的，不允许修改」**。



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

​		Redis对象系统带有引用计数的实现的内存回收机制，当一个对象不被使用时，该对象所占用的内存就会自动释放。

​		Redis对象会共享0~9999字符串对象（服务启动时就会自动加载）

​		Redis对象会记录自己最后一次被访问的时间，这个值可以用来计算空转时间，表示对象是否活跃，用命令`OBJECT IDLETIME`打印key的空转时间。



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

* 读取一个键之后，服务器会根据键是否存在来更新服务器的键空间命中（hit）次数或键空间的不命中次数（miss）次数，这两个值可以在INFO stats命令的`keyspace_hits`属性和`keyspace_miss`属性中查看。
* 在读取一个键之后，服务器会更新键的LRU（最近最后一次使用时间），可以值可以用来计算键的闲置时间，使用OBJECT idletime <key>命令可以查看key的闲置时间（空转时间）。
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



​	Redis服务器实际上使用的是惰性删除和定期删除两种策略，通过配合使用这两种删除策略，服务器可以很好地在合理使用CPU时间和避免浪费内存空间之间取得平衡。



#### 4. 数据库通知

​	数据库通知是Redis 2.8新增加的功能，客户端通过订阅给定的频道或者模式，来获知数据库中键的变化，以及数据库中命令的执行情况

​		命令分为两种：

* 键空间通知：指的是某个键执行了什么命令。
* 键事件通知：指的是某个命令被什么键执行了。

​	服务器配置的`notify-keyspace-events`选项决定了服务器发送通知的类型。可以选择配置只发送键空间通知或者只发送键事件通知或者都发送。





### 四. 事件  

​	Redis服务器是一个事件驱动程序，服务器需要处理两类事件

* 文件事件: Redis服务器通过套接字与客户端进行连接，而文件事件就是服务器对套接字操作的抽象。服务器与客户端的通信会产生相应的文件事件，而服务器则通过监听并处理事件来完成一系列网络通信操作
* 时间事件: Redis服务器中的一些操作（比如serverCorn函数）需要在给定的时间点执行，而时间事件就是对这类定时操作的抽象。

#### 1. 文件事件

​		Redis基于Reactor模式开发了自己的网络事件处理器：这个处理器被称为文件事件处理器(file event handler),文件事件处理器虽然是单线程方式运行，但通过I/O多路复用机制（高性能的网络通信模型）可以监听多个套接字。并且可以很好的与Redis中的其他单线程模块对接。保持了Redis内部单线程设计的简单性

* 文件事件处理器采用了I/O多路复用程序来同时监听多个套接字，并且根据套接字目前执行的任务来为套接字关联不同的事件处理器

* 当被监听的套接字准备好执行链接应答(accept)、读取(read)、写入(write)、关闭(close)、等操作时，与操作相对应的文件事件就会产生，这时文件事件处理器就会调用套接字之前关联好的事件处理器来处理这些事件。

  **文件事件处理器的构成：**

  ![文件事件处理器的构成.png](http://ww1.sinaimg.cn/large/0072fULUgy1gqlmkld728j30c909gjs8.jpg)

  

  

​		**文件事件处理器由四个部分构成：套接字、I/O多路复用程序、文件事件分派器(dispatcher)以及事件处理器。**

​		I/O多路复用程序负责监听多个套接字，并向文件事件分派器派送产生了事件的套接字。I/O多路复用程序会将所有产生事件的套接字放到一个队列里，然后通过这个队列，以有序、同步、每次一个套接字的方式向文件事件分派器传送套接字。当上一个套接字产生的事件被处理完毕后(被套接字为事件管理的事件处理器执行完毕)，I/O多路复用程序才会继续向文件事件分派器传送下一个套接字。

![多路复用程序传送套接字.png](http://ww1.sinaimg.cn/large/0072fULUgy1gqlmt4t9ltj30ig03it92.jpg)

​		文件事件分派器接受I/O多路复用程序传来的套接字，并根据套接字产生的事件的类型，调用相应的事件处理器。

​		服务器会为执行不同任务的套接字关联不同的事件处理器，这些处理器是一个一个函数。它们定义了某个事件的发生服务器应该执行的动作。



​		I/O多路复用程序可以监听多个套接字的`ae.h/AE_READABLE`事件和`ae.h/AE_WRITEABLE`事件。如果一个套接字同时产生了两种事件，文件事件分派器会优先处理AE_READABLE事件，处理完后再处理AE_WRITEABLE事件。也就是说一个套接字又可读又可写的话，那么服务器将先读套接字，后写套接字。

* 当套接字变得可读时（客户端对套接字执行write操作，或者close操作，或者有新的可应答accept操作）出现时，套接字产生AE_READABLE事件
* 当套接字变得可写时（客户端对套接字执行read操作），套接字产生AE_WRITEABLE事件。



##### **Reids的三种事件处理器**

* 连接应答处理器：`networking.c/acceptTcpHandler`函数是Redis的应答处理器，用于对连接服务器监听套接字的客户端进行应答。具体实现为`sys/socket.h/accpet`函数的包装。
* 命令请求处理器：`networking.c/readQueryFromClient`函数是Redis的命令请求处理器，这个处理器负责从套接字中读入客户端发送的命令请求内容，具体实现为`unistd.h/read`函数的包装。
* 命令回复处理器：`networking.c/sendReplyToClient`函数是Redis的命令回复处理器，这个处理器负责将服务器执行命令后得到的命令回复通过套接字返回给客户端，具体实现为`unistd/write`函数的包装。



##### **一次完整的客户端到服务器链接实例**

* redis sever 启动时，服务器的监听套接字会把 `AE_READABLE` 事件关联至 `acceptTcpHandler` 方法（监听套接字绑定连接应答处理器），向eventLoop注册。
* 当client连接server时，会触发redis sever的AE_READABLE事件为就绪状态。此时事件处理器为连接应答处理器。
* 当AE_READABLE事件为就绪态时，会在aeMain中对其进行处理，并执行绑定的acceptTcpHandler方法。在acceptTcpHandler方法中，会创建client实例（创建客户端套接字），并将client的AE_READABLE事件和readQueryFromClient方法绑定（客户端套接字绑定命令请求处理器），向eventLoop注册。
* client向server发送命令，触发client的AE_READABLE事件变为就绪态。此时事件处理器为命令请求处理器。
* 在aeMain中对AE_READABLE变为就绪状态的事件进行处理。执行绑定的readQueryFromClient方法，并执行相应的命令。在命令执行过后准备发送结果给client之前，会把client的AE_WRITEABLE事件和sendReplyToClient方法绑定（命令回复处理器）， 向eventLoop注册，同时发送命令，触发AE_WRITEABLE事件。
* 在aeMain中对AE_WRITEABLE的事件进行处理，执行绑定的sendReplyToClient方法，把命令发送给client，同时删除向eventLoop注册的AE_WRITEABLE事件。



#### 2. 时间事件

​		Redis时间事件主要由id,when,timeProc三个属性组成， id为全局唯一id，从小到大递增，when为毫秒精度的UNIX时间戳，记录了事件到达的事件，timeProc为时间事件处理器，一个函数，当时间事件到达时，服务器就会调用相应的处理器来处理事件。时间事件主要分为两类：

* 定时事件：当前时间的n毫秒后执行
* 周期性事件：每隔n毫秒后执行

​	   判断时间事件的类型主要通过事件处理器的返回值来判断返回`ae.h/AE_NOMORE`，为定时事件，事件到达一次之后删除，之后不再到达，返回其他为周期性事件。**目前Redis只使用周期性事件**。正常模式下的Redis只使用一个`serverCorn`一个时间事件

​		Redis将所有的时间事件放到一个无序列表中，时间事件执行器运气时遍历整个链表，查找所有已到达的时间事件，并调用相应的事件处理器。无序指的是不按when属性排序，链表采用头插法，所以id大的在前面。

##### 时间事件应用实例：serverCorn函数

​		Redis服务器以周期性的事件来运行serverCorn函数，在服务器运行期间，每隔一段时间，serverCorn就会执行一次，知道服务器关闭为止。Redis 2.6版本，服务器默认规定serverCorn每秒运行10次，也就是间隔100ms执行一次。从2.8版本开始，用户可以通过修改hz选项来调整serverCorn的每秒执行次数。具体查看redis.conf的hz

* 更新系统的各类统计信息，比如时间、内存占用、数据库占用情况等。
* 清理数据库中的过期键值对
* 关闭和清理链接失效的客户端
* 尝试进行AOF或RDB持久化操作
* 如果服务器是主服务器，那么对从服务器进行定期同步
* 如果处于集群模式，对集群进行定期同步和连接测试



### 五. Redis客户端

​		每个与Redis服务器建立了连接的客户端，服务器都为这些客户端建立了相应的`redis.h/redisClient`结构，这个结构保存了客户端当前的信息，以及执行相关功能时所需要用到的数据结构。

​		可以使用`client list`命令列出目前服务器所有连接的客户端

```c
/* With multiplexing we need to take per-client state.
 * Clients are taken in a liked list.
 *
 * 因为 I/O 复用的缘故，需要为每个客户端维持一个状态。
 *
 * 多个客户端状态被服务器用链表连接起来。
 */
typedef struct redisClient {

    // 套接字描述符
    //伪客户端为-1，代表不进行套接字连接的客户端，目前载入AOF文件或者执行LUA脚本中的Redis命令用到
    //普通客户端为大于-1的整数
    int fd;

    // 当前正在使用的数据库
    redisDb *db;

    // 当前正在使用的数据库的 id （号码）
    int dictid;

    // 客户端的名字
    robj *name;             /* As set by CLIENT SETNAME */

    // 查询缓冲区  用于保存客户端发送的命令请求。
    sds querybuf;

    // 查询缓冲区长度峰值
    size_t querybuf_peak;   /* Recent (100ms or more) peak of querybuf size */

    // 参数数量  将命令保存到querybuf后会对命令进行解析，并且将命令的参数和参数个数保存下来
    int argc;

    // 参数对象数组
    robj **argv;

    // 记录被客户端执行的命令？  命令表? 根据解析出来的argv[0]查找对应的命令实现函数？
    struct redisCommand *cmd, *lastcmd;

    // 请求的类型：内联命令还是多条命令
    int reqtype;

    // 剩余未读取的命令内容数量
    int multibulklen;       /* number of multi bulk arguments left to read */

    // 命令内容的长度
    long bulklen;           /* length of bulk argument in multi bulk request */

    // 回复链表  当char buf[REDIS_REPLY_CHUNK_BYTES]固定缓冲区已经用完服务器就会开始使用可变大小缓冲区reply
    list *reply;

    // 回复链表中对象的总大小
    unsigned long reply_bytes; /* Tot bytes of objects in reply list */

    // 已发送字节，处理 short write 用
    int sentlen;            /* Amount of bytes already sent in the current
                               buffer or object being sent. */

    // 创建客户端的时间
    time_t ctime;           /* Client creation time */

    // 客户端最后一次和服务器互动的时间
    time_t lastinteraction; /* time of the last interaction, used for timeout */

    // 客户端的输出缓冲区超过软性限制的时间
    time_t obuf_soft_limit_reached_time;

    // 客户端状态标志
    int flags;              /* REDIS_SLAVE | REDIS_MONITOR | REDIS_MULTI ... */

    // 当 server.requirepass 不为 NULL 时
    // 代表认证的状态
    // 0 代表未认证， 1 代表已认证
    int authenticated;      /* when requirepass is non-NULL */

    // 复制状态
    int replstate;          /* replication state if this is a slave */
    // 用于保存主服务器传来的 RDB 文件的文件描述符
    int repldbfd;           /* replication DB file descriptor */

    // 读取主服务器传来的 RDB 文件的偏移量
    off_t repldboff;        /* replication DB file offset */
    // 主服务器传来的 RDB 文件的大小
    off_t repldbsize;       /* replication DB file size */
    
    sds replpreamble;       /* replication DB preamble. */

    // 主服务器的复制偏移量
    long long reploff;      /* replication offset if this is our master */
    // 从服务器最后一次发送 REPLCONF ACK 时的偏移量
    long long repl_ack_off; /* replication ack offset, if this is a slave */
    // 从服务器最后一次发送 REPLCONF ACK 的时间
    long long repl_ack_time;/* replication ack time, if this is a slave */
    // 主服务器的 master run ID
    // 保存在客户端，用于执行部分重同步
    char replrunid[REDIS_RUN_ID_SIZE+1]; /* master run id if this is a master */
    // 从服务器的监听端口号
    int slave_listening_port; /* As configured with: SLAVECONF listening-port */

    // 事务状态
    multiState mstate;      /* MULTI/EXEC state */

    // 阻塞类型
    int btype;              /* Type of blocking op if REDIS_BLOCKED. */
    // 阻塞状态
    blockingState bpop;     /* blocking state */

    // 最后被写入的全局复制偏移量
    long long woff;         /* Last write global replication offset. */

    // 被监视的键
    list *watched_keys;     /* Keys WATCHED for MULTI/EXEC CAS */

    // 这个字典记录了客户端所有订阅的频道
    // 键为频道名字，值为 NULL
    // 也即是，一个频道的集合
    dict *pubsub_channels;  /* channels a client is interested in (SUBSCRIBE) */

    // 链表，包含多个 pubsubPattern 结构
    // 记录了所有订阅频道的客户端的信息
    // 新 pubsubPattern 结构总是被添加到表尾
    list *pubsub_patterns;  /* patterns a client is interested in (SUBSCRIBE) */
    sds peerid;             /* Cached peer ID. */

    /* Response buffer */
    // 回复偏移量
    int bufpos;
    // 回复缓冲区 REDIS_REPLY_CHUNK_BYTES  16*1024  16KB
    char buf[REDIS_REPLY_CHUNK_BYTES];

} redisClient;
```



#### 1. 客户端被关闭的原因

* 客户端进程退出或者被杀死

* 客户端向服务器发送了带有不符合协议格式的命令请求，那么这个客户端也会被服务器关闭

* 如果客户端成为了CLIENT KILL命令的目标，那么它也会被关闭

* 如果用户为服务器设置了timeout配置选项，那么当客户端的空转时间超过了timeout选项配置的值的话，客户端将被关闭。特殊情况除外（客户端是主服务器，从服务器正在被BLPOP命令阻塞，或者正在执行  SUBSCRIBE、PSUBSCRIBE等订阅命令）

* 客户端发送的命令大小超出了出入缓冲区的大小限制（1GB）

* 要发回给客户端命令的回复的大小超出了输出缓冲区的限制大小。（虽然回复过大会使用可变大小缓冲区，但为了避免回复过大占用服务器资源，服务器会时刻检查并执行限制操作）

  * 硬性限制：超过了硬性限制所设置的大小，服务器立即关闭客户端

  * 软性限制：超过了软性限制的大小但是没有超过硬性限制的大小，服务端会使用redisClient结构的obuf_soft_limit_reached_time来记录时间，如果输出缓冲区一直超过软性限制，并且持续时间超过服务器设定的时长，那么服务器将关闭客户端；如果在规定时间内不再超出限制，客户端不会被关闭，并且obuf_soft_limit_reached_time清零。使用`client-output-buffer-limit`选项可以为普通客户端、从服务器客户端执行发布与订阅功能的客户端分别设置不同的软性限制和硬性限制。该选项格式为：

    `client-output-buffer-limit <class> <hard limit><soft limit><soft seconds>`

    设置示例

    `client-output-buffer-limit normal 0 0 0`

    `client-output-buffer-limit slave 256mb 64mb 60`

    `client-output-buffer-limit pubsub 32mb 8mb 60`



#### 2. 执行LUA脚本的伪客户端

​		服务器会在初始化的时候创建负责执行Lua脚本中包含Redis命令的伪客户端，并将这个伪客户端关联在服务器状态结构的lua_client属性中。

​		lua_client伪客户端在服务器运行的整个生命周期中会一直存在，只有服务器关闭，客户端才会被关闭

#### 3. 载入AOF文件的伪客户端

​		服务器在载入AOF文件时，会创建用于执行AOF文件包含的Redis命令的伪客户端，并在载入完成后，关闭这个伪客户端。



### 六. 服务端

​		Redis服务器负责与多个客户端建立网络连接，处理客户端发送的命令，在数据库中保存客户端执行的命令所产生的数据，并通过资源管理器来维持服务器自身的运转。



#### 1. 命令请求的执行过程

​		一个命令请求从发送到回复的过程中，客户端和服务器需要完成一系列操作。如果客户端执行以下命令：

```bash
redis> SET KEY VALUE
```

​		那么客户端发送命令到收到回复期间，客户端和服务器需要执行以下操作：

* 客户端向服务器发送命令请求`SET KEY VALUE`

> 当用户在客户端键入一个命令后，客户端会将这个命令请求转换成协议格式，然后连接到服务器的套接字，将协议格式的命令请求发送给服务器。
>

* 服务器接受并处理客户端发来的命令请求`SET KEY VALUE`，在数据库中进行设置操作，并产生命令返回回复

> 当客户端与服务器之间的连接套接字因为客户端的写入状态变为可读时，服务器将调用命令请求处理器来执行以下操作：
>
> ​	1）读取套接字中协议格式的命令请求，并将其保存在客户端状态`redisClient`的输入缓冲区`sds querybuf`里面。
>
> ​	2）对输入缓冲区中的命令请求进行分析，提取出命令请求中包含的命令参数，以及命令参数的个数，然后分别将参数和参数个数保存到客户端状态的argv属性和argc属性里面.
>
> ​	3）调用命令执行器，执行客户端指定的命令

![客户端状态中的命令请求.png](http://ww1.sinaimg.cn/large/0072fULUgy1gqr6mebamgj30qj078jrk.jpg)

![客户端状态的argv属性.png](http://ww1.sinaimg.cn/large/0072fULUgy1gqr6rew5x1j30la05wt8x.jpg)

> 命令执行器：
>
> ​	1）查找命令实现：根据客户端状态的argv[0]参数在命令表（command table）中查找参数所指定的命令，并将找到的命令保存到客户端状态的cmd属性里面。命令表是一个字典，键是一个个字典的名字；字典的值是一个个redisCommand结构，每个RedisCommand结构记录了一个Redis命令的实现信息
>
> ​	2）执行预备操作：检查客户端状态的cmd指针，检查客户端是否通过了身份校验等
>
> ​	3）调用命令的函数：之前解析了参数和命令到客户端状态中，被调用的命令实现函数执行指定的操作，会产生相应的命令回复，这些回复会被保存到客户端状态的输出缓冲区里面（buf属性和reply属性）之后实现函数还会为客户端的套接字关联命令回复处理器，这个处理器负责将命令回复给客户端。
>
> ​	4）执行后续工作：服务器是否开了慢查询的日志，是否要为刚刚执行的命令记录；更新redisCommand结构的millseconds属性，并将命令的redisCommand结构的calls计数器的值增一；如果服务器开了AOF持久化的功能，AOF持久化模块会将刚刚执行的命令请求写入到AOF缓冲区里面；如果有其他服务器正在复制当前这个服务器，那么服务器会将刚刚执行的命令传播给所有服务器。

* 服务器将命令回复发送给客户端

> 之前说过命令执行函数会将回复保存到客户端状态的输出缓冲区里面，并且关联命令回复处理器，当客户端连接套接字变为可写状态时，服务器就会执行命令回复处理器，将保存在客户端输出缓冲区中的命令回复发送给客户端。当命令回复发送完毕后，回复处理器会清空客户端状态的输出缓冲区，为处理下一个命令请求做好准备。

* 客户端接受回复，并且打印给用户

> 客户端接受到协议格式的命令回复之后，会将这些命令转变为人类可读的格式，并且打印给用户看。



#### 2. serverCorn函数

​		Redis服务器以周期性的事件来运行serverCorn函数Redis 2.6版本，服务器默认规定serverCorn每秒运行10次，也就是间隔100ms执行一次。从2.8版本开始，用户可以通过修改hz选项来调整serverCorn的每秒执行次数。具体查看redis.conf的hz。

* 更新服务器时间的缓存

> RedisServer中的`unixtime`属性（秒级精度的当前系统UNIX时间戳）和`mstime`属性（毫秒级）作为服务器时间的缓存

* 更新LRU时钟

> RdeisServer中的`lrulock`属性保存了服务器的LRU时钟，和上面的属性一样，都是时间缓存的一种。默认每10秒更新一次用于，计算键的空转时长(idle)时长

* 更新服务器每秒执行命令次数

> `traceOperationPerSecond`函数会以每100ms一次的频率执行，这个函数的功能是以抽样计算的方式，估算并记录服务器在最近一秒钟处理的命令请求数量。
>
> 这个值可以通过INFO status命令的`instantaneous_ops_per_sec`域查看

* 更新服务器内存峰值记录

> 服务器状态的`stat_peak_memory`属性记录了服务器的内存峰值大小；每次serverCorn函数执行时，程序都会查看当前服务器使用的内存数量，并与这个值比较，如果要更大的化就更新`stat_peak_memory`的值
>
> INFO memory命令的`used_memory_peak`和`used_memory_peak_human`两个域分别以两种格式记录了服务器的内存峰值。

* 处理SIGTERM信号

> 在服务器启动时，Redis会为服务器进程的SIGTERM信号关联处理器sigtermHandler函数，这个信号处理器负责在服务器接到SIGTERM信号时，打开服务器状态的shutdown_asap标识

* 管理客户端资源

> 如果客户端与服务器之间的连接已经超时，那么程序会释放这个客户端
>
> 如果客户端在上一次执行命令请求之后，输入缓冲区的大小超过了一定的长度，那么程序h会释放客户端当前的输入缓冲区，并重新创建一个默认大小的输入缓冲区，从而防止客户端的输入缓冲区耗费了过多的内存。

* 管理数据库资源

> serverCorn函数每次执行都会调用databasesCorn函数，这个函数会对服务器中的一部分数据库进行检查，删除其中的过期键，并在有需要时，对字典进行收缩操作。

* 执行被延迟的BGREWRITEAOF

> 在服务器执行BGSAVE命令期间，如果客户端向服务器发来BGREWRITEAOF命令，那么服务器会将BGREWRITEAOF延迟到BGSAVE命令之后执行。RedisService的 `aof_rewrite_scheduled`表示记录了服务器是否延迟了BGREWRITEAOF命令。（如果值为1则代表被延迟了）

* 检查持久化操作的运行状态

> RedisServer使用`rdb_child_pid`和`aof_child_pid`属性记录执行BGSAVE命令和执行BGREWRITEAOF命令的子进程ID，这两个属性也可以用来检查BGSAVE、BGREWRITEAOF命令是否在执行。包括检查是否满足配置的RDB持久化配置还有AOF重写条件是否满足

![判断是否需要执行持久化操作.png](http://ww1.sinaimg.cn/large/0072fULUgy1gqra29r68aj30p10b6wf7.jpg)

* 将AOF缓冲区中的内容写入AOF文件

> 如果服务器开启了AOF持久化功能，并且AOF缓冲区里面还有待写入的数据，那么serverCorn函数会调用相应的程序，将AOF缓冲区中的内容写入到AOF文件里面。

* 关闭异步客户端

> 服务器会关闭那些输出缓冲区大小超出限制的客户端

* 增加cronloops计数器的值

> redisServer中的cronloops属性记录了serverCorn函数执行的次数



#### 3. 服务器启动流程

​		Redis服务器从启动到能够处理客户端的命令请求需要执行以下步骤：

* 初始化服务器状态
* 载入服务器配置
* 初始化服务器数据结构
* 还原数据库状态
* 执行事件循环



### 七. 主从复制

​		Redis可以通过SLAVEOF命令或者设置slaveof选项，让一个服务器（从）去复制另一个服务器（主）。进行复制的主从服务器双方保持的数据库保存相同的数据，我们称这种状态为数据库状态一致，或者一致。

#### 1. SYNC的实现

​		Redis复制分为同步sync和命令传播command propagate两个操作。

​		Redis同步主要通过从服务器向主服务器发送SYNC命令来完成。（Redis 2.8之前）

> 1.从服务器向主服务器发送SYNC命令。
>
> 2.主服务器搜到SYNC命令，执行BGSAVE，在后台生成一个RDB文件，并且使用一个缓冲区replication buffer记录现在开始执行的所有命令。
>
> 3.主服务器执行完BGSAVE后，将RDB文件发送给从服务器，从服务器删除自己之前的数据，并且加载RDB文件，将自己的数据库状态更新至主服务器执行BGSAVE时的服务器状态。
>
> 4.从服务器载入完RDB文件后，主服务器将缓冲区中的内容发送给从服务器执行，从服务器执行完毕后，将自己的服务器状态更新至主服务器目前的状态。

​		同步操作完成后，主从达到一致，主服务器会对从服务器执行命令传播操作，保证主从一直保持一致。

​		在Redis 2.8之前，主从每次断开后从服务器都需要重新发送SYNC命令来保证主从一致，但是SYNC是一个非常消耗资源的操作。

![sync命令.png](http://ww1.sinaimg.cn/large/0072fULUgy1gqsqbkjr3uj30tg0c30wk.jpg)

​		从Redis 2.8开始，解决了断线复制的问题，使用PSYNC命令代替了SYNC。

​		PSYNC有两种模式，一种是全量复制，一种是增量复制；当进行全量复制的时候，步骤和执行SYNC命令一样。而增量复制则用于处理短线后复制的情况。即只发送断线期间没同步的命令。



	#### 2. PSYNC实现

​		增量同步主要由三个部分构成：

* 主服务器的偏移量（replication offset）和从服务器的复制偏移量

> 执行复制的双方各自都会维护一个偏移量，主服务器每次传播N个字节的数据，偏移量就增加N，从服务器每次收到N个字节的数据，偏移量也增加N，通过对比偏移量，可以很容易的知道主从是否一致，或者缺少哪一部分数据。

* 主服务器的复制积压缓冲区（replication backlog buffer）

> replication backlog buffer是一个主服务器维护的一个固定长度先进先出的队列（环形？所以超过长度的命令会丢失）默认大小1MB。当主服务器进行命令传播时，不仅将写命令发送给所有从服务器，也会写到复制积压缓冲区。

* 服务器的运行id（run Id）

> 每个Redis服务器，不论主从，都会有自己的运行ID。在服务器启动的时候自动生成，40个随机的十六进制字符组成

​	知道这三个部分，我们就能想到增量同步的原理了，断线重连后，从服务器只要执行自身offset到主服务器offset之间的差值就可以回到主从一致的状态了。

​	PSYNC执行流程：

![PSYNC执行流程.png](http://ww1.sinaimg.cn/large/0072fULUgy1gqsqs06dpij30r90fl77b.jpg)

​		其实这样看这个流程就很简单了，如果是第一次同步直接进行全量复制，如果是断线后重连，从服务器向主服务器发送runid和offset，主服务器首先判断runid是否相同，不同执行全量同步；相同继续判断offset，之前我们说过backlog buffer是一个环形队列，断线太久可能导致前面的命令被覆盖，如果offset不存在队列里面，也只能进行全量同步，如果runid相同，offset也在队列中，则执行增量同步。

​		所以这里我们其实可以知道一个Redis运维的知识点，Replication backlog buffer的大小很关键，设置合理的大小可以减少全量同步的次数。

> ​	一般而言，我们可以调整 repl_backlog_size 这个参数。这个参数和所需的缓冲空间大小有关。缓冲空间的计算公式是：缓冲空间大小 = 主库写入命令速度 * 操作大小 - 主从库间网络传输命令速度 * 操作大小。在实际应用中，考虑到可能存在一些突发的请求压力，我们通常需要把这个缓冲空间扩大一倍，即 repl_backlog_size = 缓冲空间大小 * 2，这也就是 repl_backlog_size 的最终值。
>
> ​	举个例子，如果主库每秒写入 2000 个操作，每个操作的大小为 2KB，网络每秒能传输 1000 个操作，那么，有 1000 个操作需要缓冲起来，这就至少需要 2MB 的缓冲空间。否则，新写的命令就会覆盖掉旧操作了。为了应对可能的突发压力，我们最终把 repl_backlog_size 设为 4MB。



​	PSYNC第一次同步流程：

![PSYNC第一次同步流程.png](http://ww1.sinaimg.cn/large/0072fULUgy1gqsqo6yrdwj30kt0a0wg5.jpg)









[redis中文注释版源码](https://github.com/huangz1990/redis-3.0-annotated)

