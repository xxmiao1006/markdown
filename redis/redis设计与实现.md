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



#### 4.跳跃表

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



​	

​		



### 二. redis数据库

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

