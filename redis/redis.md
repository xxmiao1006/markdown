redis

docker	启动redis并配置密码

```bash
docker pull redis:latest
docker run --name redis-tensquare -p 6379:6379 -d --restart=always redis:latest redis-server --appendonly yes --requirepass "sUlnkfBOQ3MglYN1"

```



## centos 安装redis

```bash
wget http://download.redis.io/releases/redis-4.0.11.tar.gz
tar xzf redis-6.0.6.tar.gz
cd redis-6.0.6
make
make install
```





## 单线程

redis的核心命令执行模块是单线程，其他模块还是有它各自的模块的线程模型

一般来说 Redis 的瓶颈并不在 CPU，而在内存和网络。如果要使用 CPU 多核，可以搭建多个 Redis 实例来解决

其实，Redis 4.0 开始就有多线程的概念了，比如 Redis 通过多线程方式在后台删除对象、以及通过 Redis 模块实现的阻塞命令等。

 Redis 6 正式发布了，其中有一个是被说了很久的多线程IO

这个 Theaded IO 指的是在网络 IO 处理方面上了多线程，如网络数据的读写和协议解析等，需要注意的是，执行命令的核心模块还是单线程的。

之前的段落说了，Redis 的瓶颈并不在 CPU，而在内存和网络。

内存不够的话，可以加内存或者做数据结构优化和其他优化等，但网络的性能优化才是大头，网络 IO 的读写在 Redis 整个执行期间占用了大部分的 CPU 时间，如果把网络处理这部分做成多线程处理方式，那对整个 Redis 的性能会有很大的提升。

最后，目前最新的 6.0 版本中，IO 多线程处理模式默认是不开启的，需要去配置文件中开启并配置线程数





## redis高可用集群

安装gcc

```bash
yum install gcc
```

在/usr/local下安装redis

```bash
wget https://download.redis.io/releases/redis-5.0.2.tar.gz
tar xzf redis-5.0.2.tar.gz
cd redis-5.0.2
make & make install
```

然后在/usr/local下 创建8001~8006的文件夹，把redis的配置文件拷贝到8001下面

修改8001下的配置文件

```bash
daemonize yes    #后台运行
port 8001        #端口
logfile 8001.log  #日志文件
dir /usr/local/redis-cluster/8001   #数据文件路径
slowlog-log-slower-than 10000
#bind 192.168.250.129 127.0.0.1   #关掉指定 ip访问

cluster-enabled yes    #启动集群模式
cluster-config-file nodes_8001.conf   #集群信息节点文件
cluster-node-timeout 15000

protected-mode no

appendonly yes
appendfilename aof-8001.aof
appendfsync everysec
no-appendfsync-on-rewrite yes
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

#密码
#requirepass 123456
#masterauth 123456

```

redis.config

```properties
# Redis configuration file example.
#
# Note that in order to read the configuration file, Redis must be
# started with the file path as first argument:
#
# ./redis-server /path/to/redis.conf

# Note on units: when memory size is needed, it is possible to specify
# it in the usual form of 1k 5GB 4M and so forth:
#
# 1k => 1000 bytes
# 1kb => 1024 bytes
# 1m => 1000000 bytes
# 1mb => 1024*1024 bytes
# 1g => 1000000000 bytes
# 1gb => 1024*1024*1024 bytes
#
# units are case insensitive so 1GB 1Gb 1gB are all the same.

################################## INCLUDES ###################################

# Include one or more other config files here.  This is useful if you
# have a standard template that goes to all Redis servers but also need
# to customize a few per-server settings.  Include files can include
# other files, so use this wisely.
#
# Notice option "include" won't be rewritten by command "CONFIG REWRITE"
# from admin or Redis Sentinel. Since Redis always uses the last processed
# line as value of a configuration directive, you'd better put includes
# at the beginning of this file to avoid overwriting config change at runtime.
#
# If instead you are interested in using includes to override configuration
# options, it is better to use include as the last line.
#
# include /path/to/local.conf
# include /path/to/other.conf

################################## MODULES #####################################

# Load modules at startup. If the server is not able to load modules
# it will abort. It is possible to use multiple loadmodule directives.
#
# loadmodule /path/to/my_module.so
# loadmodule /path/to/other_module.so

################################## NETWORK #####################################

# By default, if no "bind" configuration directive is specified, Redis listens
# for connections from all the network interfaces available on the server.
# It is possible to listen to just one or multiple selected interfaces using
# the "bind" configuration directive, followed by one or more IP addresses.
#
# Examples:
#
# bind 192.168.1.100 10.0.0.1
# bind 127.0.0.1 ::1
#
# ~~~ WARNING ~~~ If the computer running Redis is directly exposed to the
# internet, binding to all the interfaces is dangerous and will expose the
# instance to everybody on the internet. So by default we uncomment the
# following bind directive, that will force Redis to listen only into
# the IPv4 loopback interface address (this means Redis will be able to
# accept connections only from clients running into the same computer it
# is running).
#
# IF YOU ARE SURE YOU WANT YOUR INSTANCE TO LISTEN TO ALL THE INTERFACES
# JUST COMMENT THE FOLLOWING LINE.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#bind 127.0.0.1

# Protected mode is a layer of security protection, in order to avoid that
# Redis instances left open on the internet are accessed and exploited.
#
# When protected mode is on and if:
#
# 1) The server is not binding explicitly to a set of addresses using the
#    "bind" directive.
# 2) No password is configured.
#
# The server only accepts connections from clients connecting from the
# IPv4 and IPv6 loopback addresses 127.0.0.1 and ::1, and from Unix domain
# sockets.
#
# By default protected mode is enabled. You should disable it only if
# you are sure you want clients from other hosts to connect to Redis
# even if no authentication is configured, nor a specific set of interfaces
# are explicitly listed using the "bind" directive.
protected-mode no

# Accept connections on the specified port, default is 6379 (IANA #815344).
# If port 0 is specified Redis will not listen on a TCP socket.
port 8001

# TCP listen() backlog.
#
# In high requests-per-second environments you need an high backlog in order
# to avoid slow clients connections issues. Note that the Linux kernel
# will silently truncate it to the value of /proc/sys/net/core/somaxconn so
# make sure to raise both the value of somaxconn and tcp_max_syn_backlog
# in order to get the desired effect.
tcp-backlog 511

# Unix socket.
#
# Specify the path for the Unix socket that will be used to listen for
# incoming connections. There is no default, so Redis will not listen
# on a unix socket when not specified.
#
# unixsocket /tmp/redis.sock
# unixsocketperm 700

# Close the connection after a client is idle for N seconds (0 to disable)
timeout 0

# TCP keepalive.
#
# If non-zero, use SO_KEEPALIVE to send TCP ACKs to clients in absence
# of communication. This is useful for two reasons:
#
# 1) Detect dead peers.
# 2) Take the connection alive from the point of view of network
#    equipment in the middle.
#
# On Linux, the specified value (in seconds) is the period used to send ACKs.
# Note that to close the connection the double of the time is needed.
# On other kernels the period depends on the kernel configuration.
#
# A reasonable value for this option is 300 seconds, which is the new
# Redis default starting with Redis 3.2.1.
tcp-keepalive 300

################################# GENERAL #####################################

# By default Redis does not run as a daemon. Use 'yes' if you need it.
# Note that Redis will write a pid file in /var/run/redis.pid when daemonized.
daemonize yes

# If you run Redis from upstart or systemd, Redis can interact with your
# supervision tree. Options:
#   supervised no      - no supervision interaction
#   supervised upstart - signal upstart by putting Redis into SIGSTOP mode
#   supervised systemd - signal systemd by writing READY=1 to $NOTIFY_SOCKET
#   supervised auto    - detect upstart or systemd method based on
#                        UPSTART_JOB or NOTIFY_SOCKET environment variables
# Note: these supervision methods only signal "process is ready."
#       They do not enable continuous liveness pings back to your supervisor.
supervised no

# If a pid file is specified, Redis writes it where specified at startup
# and removes it at exit.
#
# When the server runs non daemonized, no pid file is created if none is
# specified in the configuration. When the server is daemonized, the pid file
# is used even if not specified, defaulting to "/var/run/redis.pid".
#
# Creating a pid file is best effort: if Redis is not able to create it
# nothing bad happens, the server will start and run normally.
pidfile /var/run/redis_6379.pid

# Specify the server verbosity level.
# This can be one of:
# debug (a lot of information, useful for development/testing)
# verbose (many rarely useful info, but not a mess like the debug level)
# notice (moderately verbose, what you want in production probably)
# warning (only very important / critical messages are logged)
loglevel notice

# Specify the log file name. Also the empty string can be used to force
# Redis to log on the standard output. Note that if you use standard
# output for logging but daemonize, logs will be sent to /dev/null
logfile "8001.log"

# To enable logging to the system logger, just set 'syslog-enabled' to yes,
# and optionally update the other syslog parameters to suit your needs.
# syslog-enabled no

# Specify the syslog identity.
# syslog-ident redis

# Specify the syslog facility. Must be USER or between LOCAL0-LOCAL7.
# syslog-facility local0

# Set the number of databases. The default database is DB 0, you can select
# a different one on a per-connection basis using SELECT <dbid> where
# dbid is a number between 0 and 'databases'-1
databases 16

# By default Redis shows an ASCII art logo only when started to log to the
# standard output and if the standard output is a TTY. Basically this means
# that normally a logo is displayed only in interactive sessions.
#
# However it is possible to force the pre-4.0 behavior and always show a
# ASCII art logo in startup logs by setting the following option to yes.
always-show-logo yes

################################ SNAPSHOTTING  ################################
#
# Save the DB on disk:
#
#   save <seconds> <changes>
#
#   Will save the DB if both the given number of seconds and the given
#   number of write operations against the DB occurred.
#
#   In the example below the behaviour will be to save:
#   after 900 sec (15 min) if at least 1 key changed
#   after 300 sec (5 min) if at least 10 keys changed
#   after 60 sec if at least 10000 keys changed
#
#   Note: you can disable saving completely by commenting out all "save" lines.
#
#   It is also possible to remove all the previously configured save
#   points by adding a save directive with a single empty string argument
#   like in the following example:
#
save ""

#save 900 1
#save 300 10
#save 60 10000

# By default Redis will stop accepting writes if RDB snapshots are enabled
# (at least one save point) and the latest background save failed.
# This will make the user aware (in a hard way) that data is not persisting
# on disk properly, otherwise chances are that no one will notice and some
# disaster will happen.
#
# If the background saving process will start working again Redis will
# automatically allow writes again.
#
# However if you have setup your proper monitoring of the Redis server
# and persistence, you may want to disable this feature so that Redis will
# continue to work as usual even if there are problems with disk,
# permissions, and so forth.
stop-writes-on-bgsave-error yes

# Compress string objects using LZF when dump .rdb databases?
# For default that's set to 'yes' as it's almost always a win.
# If you want to save some CPU in the saving child set it to 'no' but
# the dataset will likely be bigger if you have compressible values or keys.
rdbcompression yes

# Since version 5 of RDB a CRC64 checksum is placed at the end of the file.
# This makes the format more resistant to corruption but there is a performance
# hit to pay (around 10%) when saving and loading RDB files, so you can disable it
# for maximum performances.
#
# RDB files created with checksum disabled have a checksum of zero that will
# tell the loading code to skip the check.
rdbchecksum yes

# The filename where to dump the DB
dbfilename dump.rdb

# The working directory.
#
# The DB will be written inside this directory, with the filename specified
# above using the 'dbfilename' configuration directive.
#
# The Append Only File will also be created inside this directory.
#
# Note that you must specify a directory here, not a file name.
dir /usr/local/redis-cluster/8001

################################# REPLICATION #################################

# Master-Replica replication. Use replicaof to make a Redis instance a copy of
# another Redis server. A few things to understand ASAP about Redis replication.
#
#   +------------------+      +---------------+
#   |      Master      | ---> |    Replica    |
#   | (receive writes) |      |  (exact copy) |
#   +------------------+      +---------------+
#
# 1) Redis replication is asynchronous, but you can configure a master to
#    stop accepting writes if it appears to be not connected with at least
#    a given number of replicas.
# 2) Redis replicas are able to perform a partial resynchronization with the
#    master if the replication link is lost for a relatively small amount of
#    time. You may want to configure the replication backlog size (see the next
#    sections of this file) with a sensible value depending on your needs.
# 3) Replication is automatic and does not need user intervention. After a
#    network partition replicas automatically try to reconnect to masters
#    and resynchronize with them.
#
# replicaof <masterip> <masterport>

# If the master is password protected (using the "requirepass" configuration
# directive below) it is possible to tell the replica to authenticate before
# starting the replication synchronization process, otherwise the master will
# refuse the replica request.
#
# masterauth <master-password>

# When a replica loses its connection with the master, or when the replication
# is still in progress, the replica can act in two different ways:
#
# 1) if replica-serve-stale-data is set to 'yes' (the default) the replica will
#    still reply to client requests, possibly with out of date data, or the
#    data set may just be empty if this is the first synchronization.
#
# 2) if replica-serve-stale-data is set to 'no' the replica will reply with
#    an error "SYNC with master in progress" to all the kind of commands
#    but to INFO, replicaOF, AUTH, PING, SHUTDOWN, REPLCONF, ROLE, CONFIG,
#    SUBSCRIBE, UNSUBSCRIBE, PSUBSCRIBE, PUNSUBSCRIBE, PUBLISH, PUBSUB,
#    COMMAND, POST, HOST: and LATENCY.
#
replica-serve-stale-data yes

# You can configure a replica instance to accept writes or not. Writing against
# a replica instance may be useful to store some ephemeral data (because data
# written on a replica will be easily deleted after resync with the master) but
# may also cause problems if clients are writing to it because of a
# misconfiguration.
#
# Since Redis 2.6 by default replicas are read-only.
#
# Note: read only replicas are not designed to be exposed to untrusted clients
# on the internet. It's just a protection layer against misuse of the instance.
# Still a read only replica exports by default all the administrative commands
# such as CONFIG, DEBUG, and so forth. To a limited extent you can improve
# security of read only replicas using 'rename-command' to shadow all the
# administrative / dangerous commands.
replica-read-only yes

# Replication SYNC strategy: disk or socket.
#
# -------------------------------------------------------
# WARNING: DISKLESS REPLICATION IS EXPERIMENTAL CURRENTLY
# -------------------------------------------------------
#
# New replicas and reconnecting replicas that are not able to continue the replication
# process just receiving differences, need to do what is called a "full
# synchronization". An RDB file is transmitted from the master to the replicas.
# The transmission can happen in two different ways:
#
# 1) Disk-backed: The Redis master creates a new process that writes the RDB
#                 file on disk. Later the file is transferred by the parent
#                 process to the replicas incrementally.
# 2) Diskless: The Redis master creates a new process that directly writes the
#              RDB file to replica sockets, without touching the disk at all.
#
# With disk-backed replication, while the RDB file is generated, more replicas
# can be queued and served with the RDB file as soon as the current child producing
# the RDB file finishes its work. With diskless replication instead once
# the transfer starts, new replicas arriving will be queued and a new transfer
# will start when the current one terminates.
#
# When diskless replication is used, the master waits a configurable amount of
# time (in seconds) before starting the transfer in the hope that multiple replicas
# will arrive and the transfer can be parallelized.
#
# With slow disks and fast (large bandwidth) networks, diskless replication
# works better.
repl-diskless-sync no

# When diskless replication is enabled, it is possible to configure the delay
# the server waits in order to spawn the child that transfers the RDB via socket
# to the replicas.
#
# This is important since once the transfer starts, it is not possible to serve
# new replicas arriving, that will be queued for the next RDB transfer, so the server
# waits a delay in order to let more replicas arrive.
#
# The delay is specified in seconds, and by default is 5 seconds. To disable
# it entirely just set it to 0 seconds and the transfer will start ASAP.
repl-diskless-sync-delay 5

# Replicas send PINGs to server in a predefined interval. It's possible to change
# this interval with the repl_ping_replica_period option. The default value is 10
# seconds.
#
# repl-ping-replica-period 10

# The following option sets the replication timeout for:
#
# 1) Bulk transfer I/O during SYNC, from the point of view of replica.
# 2) Master timeout from the point of view of replicas (data, pings).
# 3) Replica timeout from the point of view of masters (REPLCONF ACK pings).
#
# It is important to make sure that this value is greater than the value
# specified for repl-ping-replica-period otherwise a timeout will be detected
# every time there is low traffic between the master and the replica.
#
# repl-timeout 60

# Disable TCP_NODELAY on the replica socket after SYNC?
#
# If you select "yes" Redis will use a smaller number of TCP packets and
# less bandwidth to send data to replicas. But this can add a delay for
# the data to appear on the replica side, up to 40 milliseconds with
# Linux kernels using a default configuration.
#
# If you select "no" the delay for data to appear on the replica side will
# be reduced but more bandwidth will be used for replication.
#
# By default we optimize for low latency, but in very high traffic conditions
# or when the master and replicas are many hops away, turning this to "yes" may
# be a good idea.
repl-disable-tcp-nodelay no

# Set the replication backlog size. The backlog is a buffer that accumulates
# replica data when replicas are disconnected for some time, so that when a replica
# wants to reconnect again, often a full resync is not needed, but a partial
# resync is enough, just passing the portion of data the replica missed while
# disconnected.
#
# The bigger the replication backlog, the longer the time the replica can be
# disconnected and later be able to perform a partial resynchronization.
#
# The backlog is only allocated once there is at least a replica connected.
#
# repl-backlog-size 1mb

# After a master has no longer connected replicas for some time, the backlog
# will be freed. The following option configures the amount of seconds that
# need to elapse, starting from the time the last replica disconnected, for
# the backlog buffer to be freed.
#
# Note that replicas never free the backlog for timeout, since they may be
# promoted to masters later, and should be able to correctly "partially
# resynchronize" with the replicas: hence they should always accumulate backlog.
#
# A value of 0 means to never release the backlog.
#
# repl-backlog-ttl 3600

# The replica priority is an integer number published by Redis in the INFO output.
# It is used by Redis Sentinel in order to select a replica to promote into a
# master if the master is no longer working correctly.
#
# A replica with a low priority number is considered better for promotion, so
# for instance if there are three replicas with priority 10, 100, 25 Sentinel will
# pick the one with priority 10, that is the lowest.
#
# However a special priority of 0 marks the replica as not able to perform the
# role of master, so a replica with priority of 0 will never be selected by
# Redis Sentinel for promotion.
#
# By default the priority is 100.
replica-priority 100

# It is possible for a master to stop accepting writes if there are less than
# N replicas connected, having a lag less or equal than M seconds.
#
# The N replicas need to be in "online" state.
#
# The lag in seconds, that must be <= the specified value, is calculated from
# the last ping received from the replica, that is usually sent every second.
#
# This option does not GUARANTEE that N replicas will accept the write, but
# will limit the window of exposure for lost writes in case not enough replicas
# are available, to the specified number of seconds.
#
# For example to require at least 3 replicas with a lag <= 10 seconds use:
#
# min-replicas-to-write 3
# min-replicas-max-lag 10
#
# Setting one or the other to 0 disables the feature.
#
# By default min-replicas-to-write is set to 0 (feature disabled) and
# min-replicas-max-lag is set to 10.

# A Redis master is able to list the address and port of the attached
# replicas in different ways. For example the "INFO replication" section
# offers this information, which is used, among other tools, by
# Redis Sentinel in order to discover replica instances.
# Another place where this info is available is in the output of the
# "ROLE" command of a master.
#
# The listed IP and address normally reported by a replica is obtained
# in the following way:
#
#   IP: The address is auto detected by checking the peer address
#   of the socket used by the replica to connect with the master.
#
#   Port: The port is communicated by the replica during the replication
#   handshake, and is normally the port that the replica is using to
#   listen for connections.
#
# However when port forwarding or Network Address Translation (NAT) is
# used, the replica may be actually reachable via different IP and port
# pairs. The following two options can be used by a replica in order to
# report to its master a specific set of IP and port, so that both INFO
# and ROLE will report those values.
#
# There is no need to use both the options if you need to override just
# the port or the IP address.
#
# replica-announce-ip 5.5.5.5
# replica-announce-port 1234

################################## SECURITY ###################################

# Require clients to issue AUTH <PASSWORD> before processing any other
# commands.  This might be useful in environments in which you do not trust
# others with access to the host running redis-server.
#
# This should stay commented out for backward compatibility and because most
# people do not need auth (e.g. they run their own servers).
#
# Warning: since Redis is pretty fast an outside user can try up to
# 150k passwords per second against a good box. This means that you should
# use a very strong password otherwise it will be very easy to break.
#
# requirepass foobared

# Command renaming.
#
# It is possible to change the name of dangerous commands in a shared
# environment. For instance the CONFIG command may be renamed into something
# hard to guess so that it will still be available for internal-use tools
# but not available for general clients.
#
# Example:
#
# rename-command CONFIG b840fc02d524045429941cc15f59e41cb7be6c52
#
# It is also possible to completely kill a command by renaming it into
# an empty string:
#
# rename-command CONFIG ""
#
# Please note that changing the name of commands that are logged into the
# AOF file or transmitted to replicas may cause problems.

################################### CLIENTS ####################################

# Set the max number of connected clients at the same time. By default
# this limit is set to 10000 clients, however if the Redis server is not
# able to configure the process file limit to allow for the specified limit
# the max number of allowed clients is set to the current file limit
# minus 32 (as Redis reserves a few file descriptors for internal uses).
#
# Once the limit is reached Redis will close all the new connections sending
# an error 'max number of clients reached'.
#
# maxclients 10000

############################## MEMORY MANAGEMENT ################################

# Set a memory usage limit to the specified amount of bytes.
# When the memory limit is reached Redis will try to remove keys
# according to the eviction policy selected (see maxmemory-policy).
#
# If Redis can't remove keys according to the policy, or if the policy is
# set to 'noeviction', Redis will start to reply with errors to commands
# that would use more memory, like SET, LPUSH, and so on, and will continue
# to reply to read-only commands like GET.
#
# This option is usually useful when using Redis as an LRU or LFU cache, or to
# set a hard memory limit for an instance (using the 'noeviction' policy).
#
# WARNING: If you have replicas attached to an instance with maxmemory on,
# the size of the output buffers needed to feed the replicas are subtracted
# from the used memory count, so that network problems / resyncs will
# not trigger a loop where keys are evicted, and in turn the output
# buffer of replicas is full with DELs of keys evicted triggering the deletion
# of more keys, and so forth until the database is completely emptied.
#
# In short... if you have replicas attached it is suggested that you set a lower
# limit for maxmemory so that there is some free RAM on the system for replica
# output buffers (but this is not needed if the policy is 'noeviction').
#
# maxmemory <bytes>

# MAXMEMORY POLICY: how Redis will select what to remove when maxmemory
# is reached. You can select among five behaviors:
#
# volatile-lru -> Evict using approximated LRU among the keys with an expire set.
# allkeys-lru -> Evict any key using approximated LRU.
# volatile-lfu -> Evict using approximated LFU among the keys with an expire set.
# allkeys-lfu -> Evict any key using approximated LFU.
# volatile-random -> Remove a random key among the ones with an expire set.
# allkeys-random -> Remove a random key, any key.
# volatile-ttl -> Remove the key with the nearest expire time (minor TTL)
# noeviction -> Don't evict anything, just return an error on write operations.
#
# LRU means Least Recently Used
# LFU means Least Frequently Used
#
# Both LRU, LFU and volatile-ttl are implemented using approximated
# randomized algorithms.
#
# Note: with any of the above policies, Redis will return an error on write
#       operations, when there are no suitable keys for eviction.
#
#       At the date of writing these commands are: set setnx setex append
#       incr decr rpush lpush rpushx lpushx linsert lset rpoplpush sadd
#       sinter sinterstore sunion sunionstore sdiff sdiffstore zadd zincrby
#       zunionstore zinterstore hset hsetnx hmset hincrby incrby decrby
#       getset mset msetnx exec sort
#
# The default is:
#
# maxmemory-policy noeviction

# LRU, LFU and minimal TTL algorithms are not precise algorithms but approximated
# algorithms (in order to save memory), so you can tune it for speed or
# accuracy. For default Redis will check five keys and pick the one that was
# used less recently, you can change the sample size using the following
# configuration directive.
#
# The default of 5 produces good enough results. 10 Approximates very closely
# true LRU but costs more CPU. 3 is faster but not very accurate.
#
# maxmemory-samples 5

# Starting from Redis 5, by default a replica will ignore its maxmemory setting
# (unless it is promoted to master after a failover or manually). It means
# that the eviction of keys will be just handled by the master, sending the
# DEL commands to the replica as keys evict in the master side.
#
# This behavior ensures that masters and replicas stay consistent, and is usually
# what you want, however if your replica is writable, or you want the replica to have
# a different memory setting, and you are sure all the writes performed to the
# replica are idempotent, then you may change this default (but be sure to understand
# what you are doing).
#
# Note that since the replica by default does not evict, it may end using more
# memory than the one set via maxmemory (there are certain buffers that may
# be larger on the replica, or data structures may sometimes take more memory and so
# forth). So make sure you monitor your replicas and make sure they have enough
# memory to never hit a real out-of-memory condition before the master hits
# the configured maxmemory setting.
#
# replica-ignore-maxmemory yes

############################# LAZY FREEING ####################################

# Redis has two primitives to delete keys. One is called DEL and is a blocking
# deletion of the object. It means that the server stops processing new commands
# in order to reclaim all the memory associated with an object in a synchronous
# way. If the key deleted is associated with a small object, the time needed
# in order to execute the DEL command is very small and comparable to most other
# O(1) or O(log_N) commands in Redis. However if the key is associated with an
# aggregated value containing millions of elements, the server can block for
# a long time (even seconds) in order to complete the operation.
#
# For the above reasons Redis also offers non blocking deletion primitives
# such as UNLINK (non blocking DEL) and the ASYNC option of FLUSHALL and
# FLUSHDB commands, in order to reclaim memory in background. Those commands
# are executed in constant time. Another thread will incrementally free the
# object in the background as fast as possible.
#
# DEL, UNLINK and ASYNC option of FLUSHALL and FLUSHDB are user-controlled.
# It's up to the design of the application to understand when it is a good
# idea to use one or the other. However the Redis server sometimes has to
# delete keys or flush the whole database as a side effect of other operations.
# Specifically Redis deletes objects independently of a user call in the
# following scenarios:
#
# 1) On eviction, because of the maxmemory and maxmemory policy configurations,
#    in order to make room for new data, without going over the specified
#    memory limit.
# 2) Because of expire: when a key with an associated time to live (see the
#    EXPIRE command) must be deleted from memory.
# 3) Because of a side effect of a command that stores data on a key that may
#    already exist. For example the RENAME command may delete the old key
#    content when it is replaced with another one. Similarly SUNIONSTORE
#    or SORT with STORE option may delete existing keys. The SET command
#    itself removes any old content of the specified key in order to replace
#    it with the specified string.
# 4) During replication, when a replica performs a full resynchronization with
#    its master, the content of the whole database is removed in order to
#    load the RDB file just transferred.
#
# In all the above cases the default is to delete objects in a blocking way,
# like if DEL was called. However you can configure each case specifically
# in order to instead release memory in a non-blocking way like if UNLINK
# was called, using the following configuration directives:

lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no

############################## APPEND ONLY MODE ###############################

# By default Redis asynchronously dumps the dataset on disk. This mode is
# good enough in many applications, but an issue with the Redis process or
# a power outage may result into a few minutes of writes lost (depending on
# the configured save points).
#
# The Append Only File is an alternative persistence mode that provides
# much better durability. For instance using the default data fsync policy
# (see later in the config file) Redis can lose just one second of writes in a
# dramatic event like a server power outage, or a single write if something
# wrong with the Redis process itself happens, but the operating system is
# still running correctly.
#
# AOF and RDB persistence can be enabled at the same time without problems.
# If the AOF is enabled on startup Redis will load the AOF, that is the file
# with the better durability guarantees.
#
# Please check http://redis.io/topics/persistence for more information.

appendonly yes

# The name of the append only file (default: "appendonly.aof")

appendfilename "aof-8001.aof"

# The fsync() call tells the Operating System to actually write data on disk
# instead of waiting for more data in the output buffer. Some OS will really flush
# data on disk, some other OS will just try to do it ASAP.
#
# Redis supports three different modes:
#
# no: don't fsync, just let the OS flush the data when it wants. Faster.
# always: fsync after every write to the append only log. Slow, Safest.
# everysec: fsync only one time every second. Compromise.
#
# The default is "everysec", as that's usually the right compromise between
# speed and data safety. It's up to you to understand if you can relax this to
# "no" that will let the operating system flush the output buffer when
# it wants, for better performances (but if you can live with the idea of
# some data loss consider the default persistence mode that's snapshotting),
# or on the contrary, use "always" that's very slow but a bit safer than
# everysec.
#
# More details please check the following article:
# http://antirez.com/post/redis-persistence-demystified.html
#
# If unsure, use "everysec".

# appendfsync always
appendfsync everysec
# appendfsync no

# When the AOF fsync policy is set to always or everysec, and a background
# saving process (a background save or AOF log background rewriting) is
# performing a lot of I/O against the disk, in some Linux configurations
# Redis may block too long on the fsync() call. Note that there is no fix for
# this currently, as even performing fsync in a different thread will block
# our synchronous write(2) call.
#
# In order to mitigate this problem it's possible to use the following option
# that will prevent fsync() from being called in the main process while a
# BGSAVE or BGREWRITEAOF is in progress.
#
# This means that while another child is saving, the durability of Redis is
# the same as "appendfsync none". In practical terms, this means that it is
# possible to lose up to 30 seconds of log in the worst scenario (with the
# default Linux settings).
#
# If you have latency problems turn this to "yes". Otherwise leave it as
# "no" that is the safest pick from the point of view of durability.

no-appendfsync-on-rewrite yes

# Automatic rewrite of the append only file.
# Redis is able to automatically rewrite the log file implicitly calling
# BGREWRITEAOF when the AOF log size grows by the specified percentage.
#
# This is how it works: Redis remembers the size of the AOF file after the
# latest rewrite (if no rewrite has happened since the restart, the size of
# the AOF at startup is used).
#
# This base size is compared to the current size. If the current size is
# bigger than the specified percentage, the rewrite is triggered. Also
# you need to specify a minimal size for the AOF file to be rewritten, this
# is useful to avoid rewriting the AOF file even if the percentage increase
# is reached but it is still pretty small.
#
# Specify a percentage of zero in order to disable the automatic AOF
# rewrite feature.

auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# An AOF file may be found to be truncated at the end during the Redis
# startup process, when the AOF data gets loaded back into memory.
# This may happen when the system where Redis is running
# crashes, especially when an ext4 filesystem is mounted without the
# data=ordered option (however this can't happen when Redis itself
# crashes or aborts but the operating system still works correctly).
#
# Redis can either exit with an error when this happens, or load as much
# data as possible (the default now) and start if the AOF file is found
# to be truncated at the end. The following option controls this behavior.
#
# If aof-load-truncated is set to yes, a truncated AOF file is loaded and
# the Redis server starts emitting a log to inform the user of the event.
# Otherwise if the option is set to no, the server aborts with an error
# and refuses to start. When the option is set to no, the user requires
# to fix the AOF file using the "redis-check-aof" utility before to restart
# the server.
#
# Note that if the AOF file will be found to be corrupted in the middle
# the server will still exit with an error. This option only applies when
# Redis will try to read more data from the AOF file but not enough bytes
# will be found.
aof-load-truncated yes

# When rewriting the AOF file, Redis is able to use an RDB preamble in the
# AOF file for faster rewrites and recoveries. When this option is turned
# on the rewritten AOF file is composed of two different stanzas:
#
#   [RDB file][AOF tail]
#
# When loading Redis recognizes that the AOF file starts with the "REDIS"
# string and loads the prefixed RDB file, and continues loading the AOF
# tail.
aof-use-rdb-preamble yes

################################ LUA SCRIPTING  ###############################

# Max execution time of a Lua script in milliseconds.
#
# If the maximum execution time is reached Redis will log that a script is
# still in execution after the maximum allowed time and will start to
# reply to queries with an error.
#
# When a long running script exceeds the maximum execution time only the
# SCRIPT KILL and SHUTDOWN NOSAVE commands are available. The first can be
# used to stop a script that did not yet called write commands. The second
# is the only way to shut down the server in the case a write command was
# already issued by the script but the user doesn't want to wait for the natural
# termination of the script.
#
# Set it to 0 or a negative value for unlimited execution without warnings.
lua-time-limit 5000

################################ REDIS CLUSTER  ###############################
#
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# WARNING EXPERIMENTAL: Redis Cluster is considered to be stable code, however
# in order to mark it as "mature" we need to wait for a non trivial percentage
# of users to deploy it in production.
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
# Normal Redis instances can't be part of a Redis Cluster; only nodes that are
# started as cluster nodes can. In order to start a Redis instance as a
# cluster node enable the cluster support uncommenting the following:
#
cluster-enabled yes

# Every cluster node has a cluster configuration file. This file is not
# intended to be edited by hand. It is created and updated by Redis nodes.
# Every Redis Cluster node requires a different cluster configuration file.
# Make sure that instances running in the same system do not have
# overlapping cluster configuration file names.
#
cluster-config-file nodes-8001.conf

# Cluster node timeout is the amount of milliseconds a node must be unreachable
# for it to be considered in failure state.
# Most other internal time limits are multiple of the node timeout.
#
cluster-node-timeout 15000

# A replica of a failing master will avoid to start a failover if its data
# looks too old.
#
# There is no simple way for a replica to actually have an exact measure of
# its "data age", so the following two checks are performed:
#
# 1) If there are multiple replicas able to failover, they exchange messages
#    in order to try to give an advantage to the replica with the best
#    replication offset (more data from the master processed).
#    Replicas will try to get their rank by offset, and apply to the start
#    of the failover a delay proportional to their rank.
#
# 2) Every single replica computes the time of the last interaction with
#    its master. This can be the last ping or command received (if the master
#    is still in the "connected" state), or the time that elapsed since the
#    disconnection with the master (if the replication link is currently down).
#    If the last interaction is too old, the replica will not try to failover
#    at all.
#
# The point "2" can be tuned by user. Specifically a replica will not perform
# the failover if, since the last interaction with the master, the time
# elapsed is greater than:
#
#   (node-timeout * replica-validity-factor) + repl-ping-replica-period
#
# So for example if node-timeout is 30 seconds, and the replica-validity-factor
# is 10, and assuming a default repl-ping-replica-period of 10 seconds, the
# replica will not try to failover if it was not able to talk with the master
# for longer than 310 seconds.
#
# A large replica-validity-factor may allow replicas with too old data to failover
# a master, while a too small value may prevent the cluster from being able to
# elect a replica at all.
#
# For maximum availability, it is possible to set the replica-validity-factor
# to a value of 0, which means, that replicas will always try to failover the
# master regardless of the last time they interacted with the master.
# (However they'll always try to apply a delay proportional to their
# offset rank).
#
# Zero is the only value able to guarantee that when all the partitions heal
# the cluster will always be able to continue.
#
# cluster-replica-validity-factor 10

# Cluster replicas are able to migrate to orphaned masters, that are masters
# that are left without working replicas. This improves the cluster ability
# to resist to failures as otherwise an orphaned master can't be failed over
# in case of failure if it has no working replicas.
#
# Replicas migrate to orphaned masters only if there are still at least a
# given number of other working replicas for their old master. This number
# is the "migration barrier". A migration barrier of 1 means that a replica
# will migrate only if there is at least 1 other working replica for its master
# and so forth. It usually reflects the number of replicas you want for every
# master in your cluster.
#
# Default is 1 (replicas migrate only if their masters remain with at least
# one replica). To disable migration just set it to a very large value.
# A value of 0 can be set but is useful only for debugging and dangerous
# in production.
#
# cluster-migration-barrier 1

# By default Redis Cluster nodes stop accepting queries if they detect there
# is at least an hash slot uncovered (no available node is serving it).
# This way if the cluster is partially down (for example a range of hash slots
# are no longer covered) all the cluster becomes, eventually, unavailable.
# It automatically returns available as soon as all the slots are covered again.
#
# However sometimes you want the subset of the cluster which is working,
# to continue to accept queries for the part of the key space that is still
# covered. In order to do so, just set the cluster-require-full-coverage
# option to no.
#
# cluster-require-full-coverage yes

# This option, when set to yes, prevents replicas from trying to failover its
# master during master failures. However the master can still perform a
# manual failover, if forced to do so.
#
# This is useful in different scenarios, especially in the case of multiple
# data center operations, where we want one side to never be promoted if not
# in the case of a total DC failure.
#
# cluster-replica-no-failover no

# In order to setup your cluster make sure to read the documentation
# available at http://redis.io web site.

########################## CLUSTER DOCKER/NAT support  ########################

# In certain deployments, Redis Cluster nodes address discovery fails, because
# addresses are NAT-ted or because ports are forwarded (the typical case is
# Docker and other containers).
#
# In order to make Redis Cluster working in such environments, a static
# configuration where each node knows its public address is needed. The
# following two options are used for this scope, and are:
#
# * cluster-announce-ip
# * cluster-announce-port
# * cluster-announce-bus-port
#
# Each instruct the node about its address, client port, and cluster message
# bus port. The information is then published in the header of the bus packets
# so that other nodes will be able to correctly map the address of the node
# publishing the information.
#
# If the above options are not used, the normal Redis Cluster auto-detection
# will be used instead.
#
# Note that when remapped, the bus port may not be at the fixed offset of
# clients port + 10000, so you can specify any port and bus-port depending
# on how they get remapped. If the bus-port is not set, a fixed offset of
# 10000 will be used as usually.
#
# Example:
#
# cluster-announce-ip 10.1.1.5
# cluster-announce-port 6379
# cluster-announce-bus-port 6380

################################## SLOW LOG ###################################

# The Redis Slow Log is a system to log queries that exceeded a specified
# execution time. The execution time does not include the I/O operations
# like talking with the client, sending the reply and so forth,
# but just the time needed to actually execute the command (this is the only
# stage of command execution where the thread is blocked and can not serve
# other requests in the meantime).
#
# You can configure the slow log with two parameters: one tells Redis
# what is the execution time, in microseconds, to exceed in order for the
# command to get logged, and the other parameter is the length of the
# slow log. When a new command is logged the oldest one is removed from the
# queue of logged commands.

# The following time is expressed in microseconds, so 1000000 is equivalent
# to one second. Note that a negative number disables the slow log, while
# a value of zero forces the logging of every command.
slowlog-log-slower-than 10000

# There is no limit to this length. Just be aware that it will consume memory.
# You can reclaim memory used by the slow log with SLOWLOG RESET.
slowlog-max-len 128

################################ LATENCY MONITOR ##############################

# The Redis latency monitoring subsystem samples different operations
# at runtime in order to collect data related to possible sources of
# latency of a Redis instance.
#
# Via the LATENCY command this information is available to the user that can
# print graphs and obtain reports.
#
# The system only logs operations that were performed in a time equal or
# greater than the amount of milliseconds specified via the
# latency-monitor-threshold configuration directive. When its value is set
# to zero, the latency monitor is turned off.
#
# By default latency monitoring is disabled since it is mostly not needed
# if you don't have latency issues, and collecting data has a performance
# impact, that while very small, can be measured under big load. Latency
# monitoring can easily be enabled at runtime using the command
# "CONFIG SET latency-monitor-threshold <milliseconds>" if needed.
latency-monitor-threshold 0

############################# EVENT NOTIFICATION ##############################

# Redis can notify Pub/Sub clients about events happening in the key space.
# This feature is documented at http://redis.io/topics/notifications
#
# For instance if keyspace events notification is enabled, and a client
# performs a DEL operation on key "foo" stored in the Database 0, two
# messages will be published via Pub/Sub:
#
# PUBLISH __keyspace@0__:foo del
# PUBLISH __keyevent@0__:del foo
#
# It is possible to select the events that Redis will notify among a set
# of classes. Every class is identified by a single character:
#
#  K     Keyspace events, published with __keyspace@<db>__ prefix.
#  E     Keyevent events, published with __keyevent@<db>__ prefix.
#  g     Generic commands (non-type specific) like DEL, EXPIRE, RENAME, ...
#  $     String commands
#  l     List commands
#  s     Set commands
#  h     Hash commands
#  z     Sorted set commands
#  x     Expired events (events generated every time a key expires)
#  e     Evicted events (events generated when a key is evicted for maxmemory)
#  A     Alias for g$lshzxe, so that the "AKE" string means all the events.
#
#  The "notify-keyspace-events" takes as argument a string that is composed
#  of zero or multiple characters. The empty string means that notifications
#  are disabled.
#
#  Example: to enable list and generic events, from the point of view of the
#           event name, use:
#
#  notify-keyspace-events Elg
#
#  Example 2: to get the stream of the expired keys subscribing to channel
#             name __keyevent@0__:expired use:
#
#  notify-keyspace-events Ex
#
#  By default all notifications are disabled because most users don't need
#  this feature and the feature has some overhead. Note that if you don't
#  specify at least one of K or E, no events will be delivered.
notify-keyspace-events ""

############################### ADVANCED CONFIG ###############################

# Hashes are encoded using a memory efficient data structure when they have a
# small number of entries, and the biggest entry does not exceed a given
# threshold. These thresholds can be configured using the following directives.
hash-max-ziplist-entries 512
hash-max-ziplist-value 64

# Lists are also encoded in a special way to save a lot of space.
# The number of entries allowed per internal list node can be specified
# as a fixed maximum size or a maximum number of elements.
# For a fixed maximum size, use -5 through -1, meaning:
# -5: max size: 64 Kb  <-- not recommended for normal workloads
# -4: max size: 32 Kb  <-- not recommended
# -3: max size: 16 Kb  <-- probably not recommended
# -2: max size: 8 Kb   <-- good
# -1: max size: 4 Kb   <-- good
# Positive numbers mean store up to _exactly_ that number of elements
# per list node.
# The highest performing option is usually -2 (8 Kb size) or -1 (4 Kb size),
# but if your use case is unique, adjust the settings as necessary.
list-max-ziplist-size -2

# Lists may also be compressed.
# Compress depth is the number of quicklist ziplist nodes from *each* side of
# the list to *exclude* from compression.  The head and tail of the list
# are always uncompressed for fast push/pop operations.  Settings are:
# 0: disable all list compression
# 1: depth 1 means "don't start compressing until after 1 node into the list,
#    going from either the head or tail"
#    So: [head]->node->node->...->node->[tail]
#    [head], [tail] will always be uncompressed; inner nodes will compress.
# 2: [head]->[next]->node->node->...->node->[prev]->[tail]
#    2 here means: don't compress head or head->next or tail->prev or tail,
#    but compress all nodes between them.
# 3: [head]->[next]->[next]->node->node->...->node->[prev]->[prev]->[tail]
# etc.
list-compress-depth 0

# Sets have a special encoding in just one case: when a set is composed
# of just strings that happen to be integers in radix 10 in the range
# of 64 bit signed integers.
# The following configuration setting sets the limit in the size of the
# set in order to use this special memory saving encoding.
set-max-intset-entries 512

# Similarly to hashes and lists, sorted sets are also specially encoded in
# order to save a lot of space. This encoding is only used when the length and
# elements of a sorted set are below the following limits:
zset-max-ziplist-entries 128
zset-max-ziplist-value 64

# HyperLogLog sparse representation bytes limit. The limit includes the
# 16 bytes header. When an HyperLogLog using the sparse representation crosses
# this limit, it is converted into the dense representation.
#
# A value greater than 16000 is totally useless, since at that point the
# dense representation is more memory efficient.
#
# The suggested value is ~ 3000 in order to have the benefits of
# the space efficient encoding without slowing down too much PFADD,
# which is O(N) with the sparse encoding. The value can be raised to
# ~ 10000 when CPU is not a concern, but space is, and the data set is
# composed of many HyperLogLogs with cardinality in the 0 - 15000 range.
hll-sparse-max-bytes 3000

# Streams macro node max size / items. The stream data structure is a radix
# tree of big nodes that encode multiple items inside. Using this configuration
# it is possible to configure how big a single node can be in bytes, and the
# maximum number of items it may contain before switching to a new node when
# appending new stream entries. If any of the following settings are set to
# zero, the limit is ignored, so for instance it is possible to set just a
# max entires limit by setting max-bytes to 0 and max-entries to the desired
# value.
stream-node-max-bytes 4096
stream-node-max-entries 100

# Active rehashing uses 1 millisecond every 100 milliseconds of CPU time in
# order to help rehashing the main Redis hash table (the one mapping top-level
# keys to values). The hash table implementation Redis uses (see dict.c)
# performs a lazy rehashing: the more operation you run into a hash table
# that is rehashing, the more rehashing "steps" are performed, so if the
# server is idle the rehashing is never complete and some more memory is used
# by the hash table.
#
# The default is to use this millisecond 10 times every second in order to
# actively rehash the main dictionaries, freeing memory when possible.
#
# If unsure:
# use "activerehashing no" if you have hard latency requirements and it is
# not a good thing in your environment that Redis can reply from time to time
# to queries with 2 milliseconds delay.
#
# use "activerehashing yes" if you don't have such hard requirements but
# want to free memory asap when possible.
activerehashing yes

# The client output buffer limits can be used to force disconnection of clients
# that are not reading data from the server fast enough for some reason (a
# common reason is that a Pub/Sub client can't consume messages as fast as the
# publisher can produce them).
#
# The limit can be set differently for the three different classes of clients:
#
# normal -> normal clients including MONITOR clients
# replica  -> replica clients
# pubsub -> clients subscribed to at least one pubsub channel or pattern
#
# The syntax of every client-output-buffer-limit directive is the following:
#
# client-output-buffer-limit <class> <hard limit> <soft limit> <soft seconds>
#
# A client is immediately disconnected once the hard limit is reached, or if
# the soft limit is reached and remains reached for the specified number of
# seconds (continuously).
# So for instance if the hard limit is 32 megabytes and the soft limit is
# 16 megabytes / 10 seconds, the client will get disconnected immediately
# if the size of the output buffers reach 32 megabytes, but will also get
# disconnected if the client reaches 16 megabytes and continuously overcomes
# the limit for 10 seconds.
#
# By default normal clients are not limited because they don't receive data
# without asking (in a push way), but just after a request, so only
# asynchronous clients may create a scenario where data is requested faster
# than it can read.
#
# Instead there is a default limit for pubsub and replica clients, since
# subscribers and replicas receive data in a push fashion.
#
# Both the hard or the soft limit can be disabled by setting them to zero.
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

# Client query buffers accumulate new commands. They are limited to a fixed
# amount by default in order to avoid that a protocol desynchronization (for
# instance due to a bug in the client) will lead to unbound memory usage in
# the query buffer. However you can configure it here if you have very special
# needs, such us huge multi/exec requests or alike.
#
# client-query-buffer-limit 1gb

# In the Redis protocol, bulk requests, that are, elements representing single
# strings, are normally limited ot 512 mb. However you can change this limit
# here.
#
# proto-max-bulk-len 512mb

# Redis calls an internal function to perform many background tasks, like
# closing connections of clients in timeout, purging expired keys that are
# never requested, and so forth.
#
# Not all tasks are performed with the same frequency, but Redis checks for
# tasks to perform according to the specified "hz" value.
#
# By default "hz" is set to 10. Raising the value will use more CPU when
# Redis is idle, but at the same time will make Redis more responsive when
# there are many keys expiring at the same time, and timeouts may be
# handled with more precision.
#
# The range is between 1 and 500, however a value over 100 is usually not
# a good idea. Most users should use the default of 10 and raise this up to
# 100 only in environments where very low latency is required.
hz 10

# Normally it is useful to have an HZ value which is proportional to the
# number of clients connected. This is useful in order, for instance, to
# avoid too many clients are processed for each background task invocation
# in order to avoid latency spikes.
#
# Since the default HZ value by default is conservatively set to 10, Redis
# offers, and enables by default, the ability to use an adaptive HZ value
# which will temporary raise when there are many connected clients.
#
# When dynamic HZ is enabled, the actual configured HZ will be used as
# as a baseline, but multiples of the configured HZ value will be actually
# used as needed once more clients are connected. In this way an idle
# instance will use very little CPU time while a busy instance will be
# more responsive.
dynamic-hz yes

# When a child rewrites the AOF file, if the following option is enabled
# the file will be fsync-ed every 32 MB of data generated. This is useful
# in order to commit the file to the disk more incrementally and avoid
# big latency spikes.
aof-rewrite-incremental-fsync yes

# When redis saves RDB file, if the following option is enabled
# the file will be fsync-ed every 32 MB of data generated. This is useful
# in order to commit the file to the disk more incrementally and avoid
# big latency spikes.
rdb-save-incremental-fsync yes

# Redis LFU eviction (see maxmemory setting) can be tuned. However it is a good
# idea to start with the default settings and only change them after investigating
# how to improve the performances and how the keys LFU change over time, which
# is possible to inspect via the OBJECT FREQ command.
#
# There are two tunable parameters in the Redis LFU implementation: the
# counter logarithm factor and the counter decay time. It is important to
# understand what the two parameters mean before changing them.
#
# The LFU counter is just 8 bits per key, it's maximum value is 255, so Redis
# uses a probabilistic increment with logarithmic behavior. Given the value
# of the old counter, when a key is accessed, the counter is incremented in
# this way:
#
# 1. A random number R between 0 and 1 is extracted.
# 2. A probability P is calculated as 1/(old_value*lfu_log_factor+1).
# 3. The counter is incremented only if R < P.
#
# The default lfu-log-factor is 10. This is a table of how the frequency
# counter changes with a different number of accesses with different
# logarithmic factors:
#
# +--------+------------+------------+------------+------------+------------+
# | factor | 100 hits   | 1000 hits  | 100K hits  | 1M hits    | 10M hits   |
# +--------+------------+------------+------------+------------+------------+
# | 0      | 104        | 255        | 255        | 255        | 255        |
# +--------+------------+------------+------------+------------+------------+
# | 1      | 18         | 49         | 255        | 255        | 255        |
# +--------+------------+------------+------------+------------+------------+
# | 10     | 10         | 18         | 142        | 255        | 255        |
# +--------+------------+------------+------------+------------+------------+
# | 100    | 8          | 11         | 49         | 143        | 255        |
# +--------+------------+------------+------------+------------+------------+
#
# NOTE: The above table was obtained by running the following commands:
#
#   redis-benchmark -n 1000000 incr foo
#   redis-cli object freq foo
#
# NOTE 2: The counter initial value is 5 in order to give new objects a chance
# to accumulate hits.
#
# The counter decay time is the time, in minutes, that must elapse in order
# for the key counter to be divided by two (or decremented if it has a value
# less <= 10).
#
# The default value for the lfu-decay-time is 1. A Special value of 0 means to
# decay the counter every time it happens to be scanned.
#
# lfu-log-factor 10
# lfu-decay-time 1

########################### ACTIVE DEFRAGMENTATION #######################
#
# WARNING THIS FEATURE IS EXPERIMENTAL. However it was stress tested
# even in production and manually tested by multiple engineers for some
# time.
#
# What is active defragmentation?
# -------------------------------
#
# Active (online) defragmentation allows a Redis server to compact the
# spaces left between small allocations and deallocations of data in memory,
# thus allowing to reclaim back memory.
#
# Fragmentation is a natural process that happens with every allocator (but
# less so with Jemalloc, fortunately) and certain workloads. Normally a server
# restart is needed in order to lower the fragmentation, or at least to flush
# away all the data and create it again. However thanks to this feature
# implemented by Oran Agra for Redis 4.0 this process can happen at runtime
# in an "hot" way, while the server is running.
#
# Basically when the fragmentation is over a certain level (see the
# configuration options below) Redis will start to create new copies of the
# values in contiguous memory regions by exploiting certain specific Jemalloc
# features (in order to understand if an allocation is causing fragmentation
# and to allocate it in a better place), and at the same time, will release the
# old copies of the data. This process, repeated incrementally for all the keys
# will cause the fragmentation to drop back to normal values.
#
# Important things to understand:
#
# 1. This feature is disabled by default, and only works if you compiled Redis
#    to use the copy of Jemalloc we ship with the source code of Redis.
#    This is the default with Linux builds.
#
# 2. You never need to enable this feature if you don't have fragmentation
#    issues.
#
# 3. Once you experience fragmentation, you can enable this feature when
#    needed with the command "CONFIG SET activedefrag yes".
#
# The configuration parameters are able to fine tune the behavior of the
# defragmentation process. If you are not sure about what they mean it is
# a good idea to leave the defaults untouched.

# Enabled active defragmentation
# activedefrag yes

# Minimum amount of fragmentation waste to start active defrag
# active-defrag-ignore-bytes 100mb

# Minimum percentage of fragmentation to start active defrag
# active-defrag-threshold-lower 10

# Maximum percentage of fragmentation at which we use maximum effort
# active-defrag-threshold-upper 100

# Minimal effort for defrag in CPU percentage
# active-defrag-cycle-min 5

# Maximal effort for defrag in CPU percentage
# active-defrag-cycle-max 75

# Maximum number of set/hash/zset/list fields that will be processed from
# the main dictionary scan
# active-defrag-max-scan-fields 1000


```



把修改好的配置文件拷贝到8002到8005，可以用批量替换字符串替换掉端口

```bash
%s/源字符串/目标字符串/g
:%s/8001/8002/g
:%s/8001/8003/g
:%s/8001/8004/g
:%s/8001/8005/g
:%s/8001/8006/g
```

然后分别用这6个配置文件启动redis

```bash
/usr/local/redis-5.0.2/src/redis-server /usr/local/redis-cluster/8001/redis.conf


[root@node1 8006]# ps aux | grep redis
root     28229  0.1  0.0 153976  7688 ?        Ssl  10:00   0:00 /usr/local/redis-5.0.2/src/redis-server *:8001 [cluster]
root     28263  0.1  0.0 153976  7684 ?        Ssl  10:01   0:00 /usr/local/redis-5.0.2/src/redis-server *:8002 [cluster]
root     28278  0.1  0.0 153976  7684 ?        Ssl  10:01   0:00 /usr/local/redis-5.0.2/src/redis-server *:8003 [cluster]
root     28290  0.1  0.0 153976  7688 ?        Ssl  10:01   0:00 /usr/local/redis-5.0.2/src/redis-server *:8004 [cluster]
root     28299  0.1  0.0 153976  7688 ?        Ssl  10:01   0:00 /usr/local/redis-5.0.2/src/redis-server *:8005 [cluster]
root     28307  0.0  0.0 153976  7684 ?        Ssl  10:01   0:00 /usr/local/redis-5.0.2/src/redis-server *:8006 [cluster]
root     28316  0.0  0.0 112824   980 pts/0    S+   10:01   0:00 grep --color=auto redis

```

使用redis-cli创建集群，因为这里是一台机器搭建的伪分布式集群，所以会提示

`[WARNING] Some slaves are in the same host as their master`

但是创建集群是成功的。

```bash
[root@node1 8006]# /usr/local/redis-5.0.2/src/redis-cli --cluster create --cluster-replicas 1 192.168.1.175:8001 192.168.1.175:8002 192.168.1.175:8003 192.168.1.175:8004  192.168.1.175:8005 192.168.1.175:8006
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 192.168.1.175:8004 to 192.168.1.175:8001
Adding replica 192.168.1.175:8005 to 192.168.1.175:8002
Adding replica 192.168.1.175:8006 to 192.168.1.175:8003
>>> Trying to optimize slaves allocation for anti-affinity
[WARNING] Some slaves are in the same host as their master
M: b6b3c6f20f741becccfe19f47028662fdfe8cba9 192.168.1.175:8001
   slots:[0-5460] (5461 slots) master
M: a5147187663aeb91451a0fa07693c1b529d0ac7e 192.168.1.175:8002
   slots:[5461-10922] (5462 slots) master
M: 8f3cf662167ea0366256dbf98d1c7eff404706c6 192.168.1.175:8003
   slots:[10923-16383] (5461 slots) master
S: 9b31f7b1b9b21a78ed27a714294e86f6868d2f20 192.168.1.175:8004
   replicates 8f3cf662167ea0366256dbf98d1c7eff404706c6
S: ceda9c6aae52e22f7287c05b0f44ea0cc61712d0 192.168.1.175:8005
   replicates b6b3c6f20f741becccfe19f47028662fdfe8cba9
S: 639712ff8fd60afc95b8340730052e1f6f39b457 192.168.1.175:8006
   replicates a5147187663aeb91451a0fa07693c1b529d0ac7e
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
.......
>>> Performing Cluster Check (using node 192.168.1.175:8001)
M: b6b3c6f20f741becccfe19f47028662fdfe8cba9 192.168.1.175:8001
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
M: 8f3cf662167ea0366256dbf98d1c7eff404706c6 192.168.1.175:8003
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
M: a5147187663aeb91451a0fa07693c1b529d0ac7e 192.168.1.175:8002
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
S: ceda9c6aae52e22f7287c05b0f44ea0cc61712d0 192.168.1.175:8005
   slots: (0 slots) slave
   replicates b6b3c6f20f741becccfe19f47028662fdfe8cba9
S: 639712ff8fd60afc95b8340730052e1f6f39b457 192.168.1.175:8006
   slots: (0 slots) slave
   replicates a5147187663aeb91451a0fa07693c1b529d0ac7e
S: 9b31f7b1b9b21a78ed27a714294e86f6868d2f20 192.168.1.175:8004
   slots: (0 slots) slave
   replicates 8f3cf662167ea0366256dbf98d1c7eff404706c6
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

连接任意一台redis，使用`cluster info`,`cluster nodes`查看集群信息

```bash
/usr/local/redis-5.0.2/src/redis-cli -c -h 192.168.1.175 -p 8001
192.168.1.175:8001> cluster info
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:6
cluster_size:3
cluster_current_epoch:6
cluster_my_epoch:1
cluster_stats_messages_ping_sent:350
cluster_stats_messages_pong_sent:370
cluster_stats_messages_sent:720
cluster_stats_messages_ping_received:365
cluster_stats_messages_pong_received:350
cluster_stats_messages_meet_received:5
cluster_stats_messages_received:720
192.168.1.175:8001> cluster nodes
8f3cf662167ea0366256dbf98d1c7eff404706c6 192.168.1.175:8003@18003 master - 0 1617761584000 3 connected 10923-16383
a5147187663aeb91451a0fa07693c1b529d0ac7e 192.168.1.175:8002@18002 master - 0 1617761584208 2 connected 5461-10922
ceda9c6aae52e22f7287c05b0f44ea0cc61712d0 192.168.1.175:8005@18005 slave b6b3c6f20f741becccfe19f47028662fdfe8cba9 0 1617761582201 5 connected
639712ff8fd60afc95b8340730052e1f6f39b457 192.168.1.175:8006@18006 slave a5147187663aeb91451a0fa07693c1b529d0ac7e 0 1617761585211 6 connected
b6b3c6f20f741becccfe19f47028662fdfe8cba9 192.168.1.175:8001@18001 myself,master - 0 1617761583000 1 connected 0-5460
9b31f7b1b9b21a78ed27a714294e86f6868d2f20 192.168.1.175:8004@18004 slave 8f3cf662167ea0366256dbf98d1c7eff404706c6 0 1617761584000 4 connected

```

如果一个小集群主从挂了 将会导致整个cluster挂掉

(error) CLUSTERDOWN The cluster is down

![1617693162466](E:\git-markdown\markdown\images\redis\redis高可用集群.png)



![1617693422572](E:\git-markdown\markdown\images\redis\redis-1.png)







![1617693529218](E:\git-markdown\markdown\images\redis\redis-3.png)



:%s/8001/8002/g

​	 /usr/local/redis-5.0.2/src/redis-cli --cluster create --cluster-replicas 1 192.168.1.175:8001 192.168.1.175:8002 192.168.1.175:8003 192.168.1.175:8004  192.168.1.175:8005 192.168.1.175:8006





![1617694290277](E:\git-markdown\markdown\images\redis\redis-5.png)



![1617694318467](E:\git-markdown\markdown\images\redis\redis-7.png)



```bash
redis-cli --cluster help
Cluster Manager Commands:
  create         host1:port1 ... hostN:portN   #创建集群
                 --cluster-replicas <arg>      #从节点个数
  check          host:port                     #检查集群
                 --cluster-search-multiple-owners #检查是否有槽同时被分配给了多个节点
  info           host:port                     #查看集群状态
  fix            host:port                     #修复集群
                 --cluster-search-multiple-owners #修复槽的重复分配问题
  reshard        host:port                     #指定集群的任意一节点进行迁移slot，重新分slots
                 --cluster-from <arg>          #需要从哪些源节点上迁移slot，可从多个源节点完成迁移，以逗号隔开，传递的是节点的node id，还可以直接传递--from all，这样源节点就是集群的所有节点，不传递该参数的话，则会在迁移过程中提示用户输入
                 --cluster-to <arg>            #slot需要迁移的目的节点的node id，目的节点只能填写一个，不传递该参数的话，则会在迁移过程中提示用户输入
                 --cluster-slots <arg>         #需要迁移的slot数量，不传递该参数的话，则会在迁移过程中提示用户输入。
                 --cluster-yes                 #指定迁移时的确认输入
                 --cluster-timeout <arg>       #设置migrate命令的超时时间
                 --cluster-pipeline <arg>      #定义cluster getkeysinslot命令一次取出的key数量，不传的话使用默认值为10
                 --cluster-replace             #是否直接replace到目标节点
  rebalance      host:port                                      #指定集群的任意一节点进行平衡集群节点slot数量 
                 --cluster-weight <node1=w1...nodeN=wN>         #指定集群节点的权重
                 --cluster-use-empty-masters                    #设置可以让没有分配slot的主节点参与，默认不允许
                 --cluster-timeout <arg>                        #设置migrate命令的超时时间
                 --cluster-simulate                             #模拟rebalance操作，不会真正执行迁移操作
                 --cluster-pipeline <arg>                       #定义cluster getkeysinslot命令一次取出的key数量，默认值为10
                 --cluster-threshold <arg>                      #迁移的slot阈值超过threshold，执行rebalance操作
                 --cluster-replace                              #是否直接replace到目标节点
  add-node       new_host:new_port existing_host:existing_port  #添加节点，把新节点加入到指定的集群，默认添加主节点
                 --cluster-slave                                #新节点作为从节点，默认随机一个主节点
                 --cluster-master-id <arg>                      #给新节点指定主节点
  del-node       host:port node_id                              #删除给定的一个节点，成功后关闭该节点服务
  call           host:port command arg arg .. arg               #在集群的所有节点执行相关命令
  set-timeout    host:port milliseconds                         #设置cluster-node-timeout
  import         host:port                                      #将外部redis数据导入集群
                 --cluster-from <arg>                           #将指定实例的数据导入到集群
                 --cluster-copy                                 #migrate时指定copy
                 --cluster-replace                              #migrate时指定replace
  help           

For check, fix, reshard, del-node, set-timeout you can specify the host and port of any working node in the cluster.
```

[Redis 5.0 redis-cli --cluster help说明](https://www.cnblogs.com/zhoujinyi/p/11606935.html)



## 持久化

详情见redis设计与实现（第二版pdf122页）

### 一. AOF

​		AOF持久化是通过保存Redis服务器所执行的写命令来记录数据库状态的

​		AOF 日志是写后日志，“写后”的意思是 Redis 是先执行命令，把数据写入内存，然后才记录日志。那 AOF 为什么要先执行命令再记日志呢？为了避免额外的检查开销，Redis 在向 AOF 里面记录日志的时候，并不会先去对这些命令进行语法检查。所以，如果先记日志再执行命令的话，日志中就有可能记录了错误的命令，Redis 在使用日志恢复数据时，就可能会出错；除此之外，AOF 还有一个好处：它是在命令执行后才记录日志，所以不会阻塞当前的写操作。

#### **1. AOF的实现原理**

​		AOF持久化功能的实现可以分为命令追加(append)，文件写入，文件同步（sync）三个步骤

* 命令追加(append)：服务器在执行完一个命令后，会以协议格式将被执行的写命令追加到服务器状态的aof_buf缓冲区的末尾。
* 文件写入和同步：redies的服务器进程实际就是一个事件循环（loop），这个循环中的文件事件负责接受客户端的命令请求，以及向客户端回复，而时间事件就负责执行像serverCron函数（也是检查是否满足rdb持久化条件的函数）这样需要定时运行的函数。

```c
//伪代码
def eventloop():
	while true:
		//处理文件事件，接受命令请求以及发送命令回复
		//处理命令请求时可能会有新内容被追加到aof_buf缓冲区中
		processFileEvents();

		//处理时间事件
		processTimeEvents();
		
		//考虑是否将aof_buf缓冲区中的所有内容写入和保存到aof文件中
		//此函数的行为由服务器配置的appendfsync选项的值来决定
		flushAppendOnlyFile();
```



#### **2. AOF三种写盘策略**

* **Always**，同步写回：每个写命令执行完，立马同步地将日志写回磁盘；
* **Everysec**，每秒写回：每个写命令执行完，只是先把日志写到 AOF 文件的内存缓冲区，每隔一秒把缓冲区中的内容写入磁盘；
* **No**，操作系统控制的写回：每个写命令执行完，只是先把日志写到 AOF 文件的内存缓冲区，由操作系统决定何时将缓冲区内容写回磁盘。

针对避免主线程阻塞和减少数据丢失问题，这三种写回策略都无法做到两全其美。我们来分析下其中的原因。

“同步写回”可以做到基本不丢数据，但是它在每一个写命令后都有一个慢速的落盘操作，不可避免地会影响主线程性能；

虽然“操作系统控制的写回”在写完缓冲区后，就可以继续执行后续的命令，但是落盘的时机已经不在 Redis 手中了，只要 AOF 记录没有写回磁盘，一旦宕机对应的数据就丢失了；

“每秒写回”采用一秒写回一次的频率，避免了“同步写回”的性能开销，虽然减少了对系统性能的影响，但是如果发生宕机，上一秒内未落盘的命令操作仍然会丢失。所以，这只能算是，在避免影响主线程性能和避免数据丢失两者间取了个折中。



随着接收的写命令越来越多，AOF 文件会越来越大。这也就意味着，我们一定要小心 AOF 文件过大带来的性能问题。

这里的“性能问题”，主要在于以下三个方面：

* 一是，文件系统本身对文件大小有限制，无法保存过大的文件；

* 二是，如果文件太大，之后再往里面追加命令记录的话，效率也会变低；

* 三是，如果发生宕机，AOF 中记录的命令要一个个被重新执行，用于故障恢复，如果日志文件太大，整个恢复过程就会非常缓慢，这就会影响到 Redis 的正常使用。

所以有必要对’冗余‘的AOF文件进行优化，即AOF文件重写。



#### 3. AOF重写机制

​		AOF重写并不需要对原有AOF文件进行任何的读取，写入，分析等操作，这个功能是通过读取服务器当前的数据库状态来实现的。

```bash
# 假设服务器对键list执行了以下命令s;
127.0.0.1:6379> RPUSH list "A" "B"
(integer) 2
127.0.0.1:6379> RPUSH list "C"
(integer) 3
127.0.0.1:6379> RPUSH list "D" "E"
(integer) 5
127.0.0.1:6379> LPOP list
"A"
127.0.0.1:6379> LPOP list
"B"
127.0.0.1:6379> RPUSH list "F" "G"
(integer) 5
127.0.0.1:6379> LRANGE list 0 -1
1) "C"
2) "D"
3) "E"
4) "F"
5) "G"
127.0.0.1:6379>
```

当前列表键list在数据库中的值就为["C", "D", "E", "F", "G"]。要使用尽量少的命令来记录list键的状态，最简单的方式不是去读取和分析现有AOF文件的内容，，而是直接读取list键在数据库中的当前值，然后用一条RPUSH list "C" "D" "E" "F" "G"代替前面的6条命令。

##### **AOF重写功能的实现原理**

首先从数据库中读取键现在的值，然后用一条命令去记录键值对，代替之前记录该键值对的多个命令

```python
def AOF_REWRITE(tmp_tile_name):

  f = create(tmp_tile_name)

  # 遍历所有数据库
  for db in redisServer.db:

    # 如果数据库为空，那么跳过这个数据库
    if db.is_empty(): continue

    # 写入 SELECT 命令，用于切换数据库
    f.write_command("SELECT " + db.number)

    # 遍历所有键
    for key in db:

      # 如果键带有过期时间，并且已经过期，那么跳过这个键
      if key.have_expire_time() and key.is_expired(): continue

      if key.type == String:

        # 用 SET key value 命令来保存字符串键

        value = get_value_from_string(key)

        f.write_command("SET " + key + value)

      elif key.type == List:

        # 用 RPUSH key item1 item2 ... itemN 命令来保存列表键

        item1, item2, ..., itemN = get_item_from_list(key)

        f.write_command("RPUSH " + key + item1 + item2 + ... + itemN)

      elif key.type == Set:

        # 用 SADD key member1 member2 ... memberN 命令来保存集合键

        member1, member2, ..., memberN = get_member_from_set(key)

        f.write_command("SADD " + key + member1 + member2 + ... + memberN)

      elif key.type == Hash:

        # 用 HMSET key field1 value1 field2 value2 ... fieldN valueN 命令来保存哈希键

        field1, value1, field2, value2, ..., fieldN, valueN =\
        get_field_and_value_from_hash(key)

        f.write_command("HMSET " + key + field1 + value1 + field2 + value2 +\
                        ... + fieldN + valueN)

      elif key.type == SortedSet:

        # 用 ZADD key score1 member1 score2 member2 ... scoreN memberN
        # 命令来保存有序集键

        score1, member1, score2, member2, ..., scoreN, memberN = \
        get_score_and_member_from_sorted_set(key)

        f.write_command("ZADD " + key + score1 + member1 + score2 + member2 +\
                        ... + scoreN + memberN)

      else:

        raise_type_error()

      # 如果键带有过期时间，那么用 EXPIREAT key time 命令来保存键的过期时间
      if key.have_expire_time():
        f.write_command("EXPIREAT " + key + key.expire_time_in_unix_timestamp())

    # 关闭文件
    f.close()
```

​		实际为了避免执行命令时造成客户端输入缓冲区溢出，重写程序在处理list hash set zset时，会检查键所包含的元素的个数，如果元素的数量超过了redis.h/REDIS_AOF_REWRITE_ITEMS_PER_CMD常量的值，那么重写程序会使用多条命令来记录键的值，而不是单使用一条命令。该常量默认值是64– 即每条命令设置的元素的个数 是最多64个，使用多条命令重写实现集合键中元素数量超过64个的键。

##### **AOF后台重写（bgrewriteaof的原理）**

​		很明显AOF的重写函数aof_rewrite函数可以很好的创建一个新AOF文件，但是这个函数会有大量的写入操作，如果由主线程来执行它，服务端则无法处理客户端发来的请求。所以是不能在主线程中执行它的。

​		所以redis决定将AOF重写程序放到**子进程**里执行，这样做可以同时达到两个目的：

* 子进程在进行aof重写期间，服务端可以继续处理客户端的命令请求。
* 子进程带有服务器进程的副本，使用子进程而不是使用子线程，可以避免在使用锁的情况下保证数据的安全性。

​		不过，使用子进程的情况下，也有一个问题需要解决，当子进程在进行aof重写期间，服务端进程还需要继续处理命令，请求，而新的命令可能会对现有的数据库状态进行修改，从而使得服务器当前的数据库状态和重写后的aof保存的数据库状态不一致。

​		为了解决这种数据不一致的问题，Redis增加了一个AOF重写缓存，这个缓存在fork出子进程之后开始启用，Redis服务器主进程在执行完写命令之后，会同时将这个**写命令追加到AOF缓冲区和AOF重写缓冲区**

​		即子进程在执行AOF重写时，主进程需要执行以下三个工作：

- 执行client发来的命令请求；
- 将写命令追加到现有的AOF文件中；
- 将写命令追加到AOF重写缓存中。

​		这样可以保证AOF缓冲区的内容会定期被写入和同步到AOF文件中，对现有的AOF文件的处理工作会正常进行；从创建子进程开始，服务器执行的所有写操作都会被记录到AOF重写缓冲区中。

当子进程完成对AOF文件重写之后，**它会向父进程发送一个完成信号，父进程接到该完成信号之后，会调用一个信号处理函数**，该函数完成以下工作：

​		将AOF重写缓存中的内容全部写入到新的AOF文件中；这个时候新的AOF文件所保存的数据库状态和服务器当前的数据库状态一致；
​		对新的AOF文件进行改名，原子的覆盖原有的AOF文件；完成新旧两个AOF文件的替换。
​		当这个信号处理函数执行完毕之后，主进程就可以继续像往常一样接收命令请求了。在整个AOF后台重写过程中，**只有最后的“主进程写入命令到AOF缓存”和“对新的AOF文件进行改名，覆盖原有的AOF文件。”这两个步骤（信号处理函数执行期间）会造成主进程阻塞**，在其他时候，AOF后台重写都不会对主进程造成阻塞，这将AOF重写对性能造成的影响降到最低。



##### 触发AOF后台重写的条件

AOF重写可以由用户通过调用BGREWRITEAOF手动触发。

服务器在AOF功能开启的情况下，会维持以下三个变量：

​	记录当前AOF文件大小的变量`aof_current_size`。
​	记录最后一次AOF重写之后，AOF文件大小的变量`aof_rewrite_base_size`。
​	增长百分比变量`aof_rewrite_perc`。

每次当serverCron（服务器周期性操作函数）函数执行时，它会检查以下条件是否全部满足，如果全部满足的话，就触发自动的AOF重写操作：

​	没有BGSAVE命令（RDB持久化）/AOF持久化在执行；
​	没有BGREWRITEAOF在进行；
​	当前AOF文件大小要大于`server.aof_rewrite_min_size`（默认为1MB），或者在redis.conf配置了`auto-aof-rewrite-min-size`大小；
​	当前AOF文件大小和最后一次重写后的大小之间的比率等于或者等于指定的增长百分比（在配置文件设置了`auto-aof-rewrite-percentage`参数，不设置默认为100%）

如果前面三个条件都满足，并且当前AOF文件大小比最后一次AOF重写时的大小要大于指定的百分比，那么触发自动AOF重写。

> `auto-aof-rewrite-min-size`: 表示运行AOF重写时文件的最小大小，默认为64MB
>
> `auto-aof-rewrite-percentage`: 这个值的计算方法是：当前AOF文件大小和上一次重写后AOF文件大小的差值，再除以上一次重写后AOF文件大小。也就是当前AOF文件比上一次重写后AOF文件的增量大小，和上一次重写后AOF文件大小的比值。
>
> AOF文件大小同时超出上面这两个配置项时，会触发AOF重写。  



#### 4. AOF文件的载入和还原

​		因为AOF文件里面包含了重建数据库状态所需的所有命令，所以服务器只要读入并重新执行一遍aof文件里面保存的所有写命令，就可以还原服务器关闭之前的数据库状态。

​		redis读取aof文件并还原数据库状态的详细状态如下：

* 创建一个不网络状态的伪客户端（fake client）：因为redis的命令只能在客户端上下文中执行，而载入aof文件时所使用的命令直接来源于aof文件而不是来源于网络连接，所以服务器使用了一个没有网络连接的伪客户端来执行aof文件保存的写命令，伪客户端执行命令的效果和带网络连接的客户端执行命令的效果完全是一样的。
* 从aof文件中分析并且读取出一条写命令。
* 使用伪客户端执行被读出的写命令。
* 一直执行上面两步，知道aof文件中的所有写命令都被处理完毕。

​		

### 二. RDB

​		redis提供RDB持久化功能，这个功能可以将redis在内存中的数据库状态保存到磁盘里，避免数据意外丢失。它可以将某个时间点上的数据库状态保存到一个RDB文件中，生成的RDB文件是一个经过压缩的二进制文件，通过这个文件可以还原生成的RDB文件时的数据库状态。

#### 1. RDB文件的创建和载入

​		有两个redis命令可以用于生成RDB文件，一个是SAVE，一个是BGSAVE。创建的实际工作由`rdb.c\rdbsave`函数完成

​		SAVE命令会阻塞redis服务器进程，知道RDB文件创建完成为止，在RDB文件创建完成前，服务器不能处理任何请求。

​		和SAVE命令不同的是，BGSAVE命令会派生出一个子进程，然后由子进程负责创建RDB文件，服务器进程（父进程）继续处理请求。bgsave 避免阻塞。

> 这里就要说到一个常见的误区了，避免阻塞和正常处理写操作并不是一回事。此时，主线程的确没有阻塞，可以正常接收请求，但是，为了保证快照完整性，它只能处理读操作，因为不能修改正在执行快照的数据。（Redis 借助操作系统提供的写时复制技术（Copy-On-Write, COW），在执行快照的同时，正常处理写操作。）

​		RDB文件的载入是在服务器启动时启动执行的，所以redis并没有专门用于载入RDB文件的命令，只要redis服务器启动时监测到RDB文件的存在，它就会自动载入RDB文件。

​		载入RDB的工作实际上由`rdb.c\rdbload`这个函数自动完成的。另外值得一提的是，如果服务器开启了AOF持久化功能，那么服务器会优先使用AOF文件来还原数据库状态，只有在AOF持久化功能处于关闭状态时，服务器才会使用RDB文件来还原数据库状态。

**注意：在bgsave执行期间，`save`,`bgsave`命令会被拒绝，`bgrewriteaof`命令会被延迟到`bgsave`之后执行。**



#### 2. RDB的间隔性保存

​		用户通过配置文件的save选项设置多个保存条件，但只要其中一个任意条件被满足，服务器就会执行BGSAVE命令。

```bash
save 900 1
save 300 10
save 60 10000
```

​		Redis服务器是如何根据save选项设置的保存条件，自动执行bgsave命令呢？

​		redis服务器启动时，用户可以通过指定配置文件或者传入启动参数的方式设置save选项，如果用户没有主动设置save选项，那么服务器会为save选项设置默认条件，如上。接着服务器程序会根据save选项所设置的保存条件，设置服务器状态redisServer结构的saveparams属性：

```c
struct redisServer {
    struct saveparam *saveparams;   /* Save points array for RDB */
    
    // 自从上次 SAVE 执行以来，数据库被修改的次数
    long long dirty;                /* Changes to DB from the last save */

    // 最后一次完成 SAVE 的时间
    time_t lastsave;                /* Unix time of last successful save */
}

// 服务器的保存条件（BGSAVE 自动执行的条件）
struct saveparam {

    // 多少秒之内
    time_t seconds;

    // 发生多少次修改
    int changes;

};
```

​		redis的服务器周期性操作函数serverCron默认每隔100ms就会执行一次，该函数用于对正在运行的服务器进行维护，它的其中一项工作就是检查save选项所设置的条件是否已经满足，满足的话，就执行`BGSAVE`命令

​		RDB可以快速恢复数据库，也就是只需要把 RDB 文件直接读入内存，内存快照也有它的局限性。它拍的是一张内存的“大合影”，不可避免地会耗时耗力。虽然，Redis 设计了 bgsave 和写时复制方式，尽可能减少了内存快照对正常读写的影响，但是，频繁快照仍然是不太能接受的。



#### 3. RDB混合AOF(推荐使用)

​		Redis 4.0 中提出了一个混合使用 AOF 日志和内存快照的方法。简单来说，内存快照以一定的频率执行，在两次快照之间，使用 AOF 日志记录这期间的所有命令操作。

​		设置的参数是： aof-use-rdb-preamble yes







aof文件检查

redis-check-aof /etc/redis/appendonly.aof

rdb文件检查

redis-check-rdb /etc/redis/dump.rdb

查看持久化信息

info Persistence

查看状态信息

info stats

混合模式下手动写aof

bgrewriteaof



rdb模式：

1.手动执行save会调用rdbsave，阻塞redis主进程，导致无法提供服务

2.使用bgsave则fork出一个子进程，子进程负责调用rdbSave,在保存完成后向主进程发送信号告知完成。在bgsave执行期间仍然可以继续处理客户端请求

3、Copy On Write 机制，备份的是开始那个时刻内存中的数据，只复制被修改内存页数据，不是全部内存数据。

4、Copy On Write 时如果父子进程大量写操作会导致分页错误。







## redis内存

查看redis的内存

```bash
127.0.0.1:6379> info memory
# Memory
used_memory:4131112  #由 Redis 分配器分配的内存总量，以字节（byte）为单位
used_memory_human:3.94M # 以人类可读的格式返回 Redis 分配的内存总量
used_memory_rss:11890688 #从操作系统的角度，返回 Redis 已分配的内存总量（俗称常驻集大小）。这个值和 top 、 ps 等命令的输出一致。
used_memory_rss_human:11.34M
used_memory_peak:4643992 #Redis 的内存消耗峰值（以字节为单位）
used_memory_peak_human:4.43M
used_memory_peak_perc:88.96% 
used_memory_overhead:3404682
used_memory_startup:791032
used_memory_dataset:726430
used_memory_dataset_perc:21.75%
allocator_allocated:4200880
allocator_active:5222400
allocator_resident:8261632
total_system_memory:4143288320
total_system_memory_human:3.86G
used_memory_lua:37888
used_memory_lua_human:37.00K
used_memory_scripts:0
used_memory_scripts_human:0B
number_of_cached_scripts:0
maxmemory:0
maxmemory_human:0B
maxmemory_policy:noeviction
allocator_frag_ratio:1.24
allocator_frag_bytes:1021520
allocator_rss_ratio:1.58
allocator_rss_bytes:3039232
rss_overhead_ratio:1.44
rss_overhead_bytes:3629056
mem_fragmentation_ratio:2.91  #used_memory_rss 和 used_memory 之间的比率
mem_fragmentation_bytes:7800592
mem_not_counted_for_evict:2324
mem_replication_backlog:0
mem_clients_slaves:0
mem_clients_normal:2485302
mem_aof_buffer:2324
mem_allocator:jemalloc-5.1.0
active_defrag_running:0
lazyfree_pending_objects:0
```



测试

```bash
127.0.0.1:6379> info memory
# Memory
used_memory:1031808
used_memory_human:1007.62K
used_memory_rss:8839168
used_memory_rss_human:8.43M
used_memory_peak:3388024
used_memory_peak_human:3.23M
total_system_memory:4142133248
total_system_memory_human:3.86G
used_memory_lua:37888
used_memory_lua_human:37.00K
maxmemory:0
maxmemory_human:0B
maxmemory_policy:noeviction
mem_fragmentation_ratio:8.57
mem_allocator:jemalloc-3.6.0
127.0.0.1:6379> set stackFlowUpdate:94785989738590250 62631
OK
127.0.0.1:6379> object encoding stackFlowUpdate:94785989738590250
"int"
127.0.0.1:6379> info memory
# Memory
used_memory:1031920
used_memory_human:1007.73K
used_memory_rss:8863744
used_memory_rss_human:8.45M
used_memory_peak:3388024
used_memory_peak_human:3.23M
total_system_memory:4142133248
total_system_memory_human:3.86G
used_memory_lua:37888
used_memory_lua_human:37.00K
maxmemory:0
maxmemory_human:0B
maxmemory_policy:noeviction
mem_fragmentation_ratio:8.59
mem_allocator:jemalloc-3.6.0
127.0.0.1:6379> set stackFlowUpdate:94786178717152195 62179
OK
127.0.0.1:6379> info memory
# Memory
used_memory:1032032
used_memory_human:1007.84K
used_memory_rss:8863744
used_memory_rss_human:8.45M
used_memory_peak:3388024
used_memory_peak_human:3.23M
total_system_memory:4142133248
total_system_memory_human:3.86G
used_memory_lua:37888
used_memory_lua_human:37.00K
maxmemory:0
maxmemory_human:0B
maxmemory_policy:noeviction
mem_fragmentation_ratio:8.59
mem_allocator:jemalloc-3.6.0
```

set stackFlowUpdate:94786178717152195 62179

key ：stackFlowUpdate:94786178717152195  33个字节

value: 使用的是int类型的编码  

内存变化由 1031808->1031920->1032032;说明一个数据占了112个字节

但是实际的



安装pip3

```
# 下载指定版本
wget https://pypi.python.org/packages/source/p/pip/pip-18.1.tar.gz
# 解压
tar -zxvf pip-18.1.tar.gz 
# 安装
cd pip-18.1
python3 setup.py build
python3 setup.py install
# 添加到软连接
ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3
# 查看软连接
ll  /usr/bin/pip*
```

安装rdbtools

```bash
sudo yum install gcc
pip install rdbtools python-lzf
```

查找单个key的内存

```bash
#redis-memory-for-key -s localhost -p 6379 -a bdy123 stackFlowUpdate:94786178717152195
Key				stackFlowUpdate:94786178717152195
Bytes				80
Type				string
```

这个key占用了80B的内存，我们知道Redis 会使用一个全局哈希表保存所有键值对，哈希表的每一项是一个 dictEntry 的结构体，用来指向一个键值对。dictEntry 结构中有三个 8 字节的指针，分别指向 key、value 以及下一个 dictEntry，三个指针共 24 字节。如下

![内存计算1.png](http://ww1.sinaimg.cn/large/0072fULUgy1gs03xgbch7j60s60cwmxg02.jpg)

这里我们和112字节对上了  接下来要进一步分析剩下的key和value所占用的80字节

因为 Redis 的数据类型有很多，而且，不同数据类型都有些相同的元数据要记录（比如最后一次访问的时间、被引用的次数等），所以，Redis 会用一个 RedisObject 结构体来统一记录这些元数据，同时指向实际数据。一个 RedisObject 包含了 8 字节的元数据和一个 8 字节指针，这个指针再进一步指向具体数据类型的实际数据所在。

我们使用object encoding key来看这个value对应的String编码类型，其实我们可以猜到用的是int编码

```
127.0.0.1:6379> object encoding stackFlowUpdate:94786178717152195
"int"
```

当你保存 64 位有符号整数时，String 类型会把它保存为一个 8 字节的 Long 类型整数，这种保存方式通常也叫作 int 编码方式。所以我们可以先猜测value这个redisObject所占用的字节大小为16字节 ,那么剩下的64字节就分配给了key这个redisObject，可以参考下图看内存分配。

![redisString.png](http://ww1.sinaimg.cn/large/0072fULUgy1gs03p4q5tnj60hi0b076i02.jpg)





![内存计算2.png](http://ww1.sinaimg.cn/large/0072fULUgy1gs04vpzz6yj615w0g60tp02.jpg)





## redis各种类型已经使用场景

#### 1. string类型使用场景

最常用

SET key value
GET key
同时设置/获取多个键值

MSET key value [key value…]
MGET key [key…]
数值增减

递增数字 INCR key（可以不用预先设置key的数值。如果预先设置key但值不是数字，则会报错)
增加指定的整数 INCRBY key increment
递减数值 DECR key
减少指定的整数 DECRBY key decrement
获取字符串长度

STRLEN key

##### 分布式锁

SETNX key value
SET key value [EX seconds] [PX milliseconds] [NX|XX]
EX：key在多少秒之后过期
PX：key在多少毫秒之后过期
NX：当key不存在的时候，才创建key，效果等同于setnx
XX：当key存在的时候，覆盖key
应用场景

##### 商品编号、订单号采用INCR命令生成

是否喜欢的文章

#### 2. hash类型使用场景

Redis的Hash类型相当于Java中Map<String, Map<Object, Object>>

一次设置一个字段值 HSET key field value

一次获取一个字段值 HGET key field

一次设置多个字段值 HMSET key field value [field value …]

一次获取多个字段值 HMGET key field [field …]

获取所有字段值 HGETALL key

获取某个key内的全部数量 HLEN

删除一个key HDEL

##### 应用场景 - 购物车早期，当前小中厂可用

新增商品 hset shopcar:uid1024 334488 1
新增商品 hset shopcar:uid1024 334477 1
增加商品数量 hincrby shopcar:uid1024 334477 1
商品总数 hlen shopcar:uid1024
全部选择 hgetall shopcar:uid1024

#### 3. list类型使用场景

向列表左边添加元素 LPUSH key value [value …]

向列表右边添加元素 RPUSH key value [value …]

查看列表 LRANGE key start stop

获取列表中元素的个数 LLEN key

##### 应用场景 - 微信文章订阅公众号

大V作者李永乐老师和ICSDN发布了文章分别是11和22
阳哥关注了他们两个，只要他们发布了新文章，就会安装进我的List
lpush likearticle:阳哥id1122
查看阳哥自己的号订阅的全部文章，类似分页，下面0~10就是一次显示10条
lrange likearticle:阳哥id 0 10

#### 4. set类型使用场景

添加元素 SADD key member [member …]

删除元素 SREM key member [member …]

获取集合中的所有元素 SMEMBERS key

判断元素是否在集合中 SISMEMBER key member

获取集合中的元素个数 SCARD key

从集合中随机弹出一个元素，元素不删除 SRANDMEMBER key [数字]

从集合中随机弹出一个元素，出一个删一个 SPOP key[数字]

集合运算

集合的差集运算A - B
属于A但不属于B的元素构成的集合
SDIFF key [key …]
集合的交集运算A ∩ B
属于A同时也属于B的共同拥有的元素构成的集合
SINTER key [key …]
集合的并集运算A U B
属于A或者属于B的元素合并后的集合
SUNION key [key …]
应用场景

##### 微信抽奖小程序

用户ID，立即参与按钮
SADD key 用户ID
显示已经有多少人参与了、上图23208人参加
SCARD key
抽奖(从set中任意选取N个中奖人)
SRANDMEMBER key 2（随机抽奖2个人，元素不删除）
SPOP key 3（随机抽奖3个人，元素会删除）

##### 微信朋友圈点赞

新增点赞
sadd pub:msglD 点赞用户ID1 点赞用户ID2
取消点赞
srem pub:msglD 点赞用户ID
展现所有点赞过的用户
SMEMBERS pub:msglD
点赞用户数统计，就是常见的点赞红色数字
scard pub:msgID
判断某个朋友是否对楼主点赞过
SISMEMBER pub:msglD用户ID

##### 微博好友关注社交关系

共同关注：我去到局座张召忠的微博，马上获得我和局座共同关注的人
sadd s1 1 2 3 4 5
sadd s2 3 4 5 6 7
SINTER s1 s2
我关注的人也关注他(大家爱好相同)

##### QQ内推可能认识的人

sadd s1 1 2 3 4 5
sadd s2 3 4 5 6 7
SINTER s1 s2
SDIFF s1 s2
SDIFF s2 s1

#### 5. zset类型使用场景

向有序集合中加入一个元素和该元素的分数

添加元素 ZADD key score member [score member …]

按照元素分数从小到大的顺序返回索引从start到stop之间的所有元素 ZRANGE key start stop [WITHSCORES]

获取元素的分数 ZSCORE key member

删除元素 ZREM key member [member …]

获取指定分数范围的元素 ZRANGEBYSCORE key min max [WITHSCORES] [LIMIT offset count]

增加某个元素的分数 ZINCRBY key increment member

获取集合中元素的数量 ZCARD key

获得指定分数范围内的元素个数 ZCOUNT key min max

按照排名范围删除元素 ZREMRANGEBYRANK key start stop

获取元素的排名

从小到大 ZRANK key member

从大到小 ZREVRANK key member

应用场景

##### 根据商品销售对商品进行排序显示

定义商品销售排行榜（sorted set集合），key为goods:sellsort，分数为商品销售数量。
商品编号1001的销量是9，商品编号1002的销量是15 - zadd goods:sellsort 9 1001 15 1002
有一个客户又买了2件商品1001，商品编号1001销量加2 - zincrby goods:sellsort 2 1001
求商品销量前10名 - ZRANGE goods:sellsort 0 10 withscores
抖音热搜
点击视频
ZINCRBY hotvcr:20200919 1 八佰
ZINCRBY hotvcr:20200919 15 八佰 2 花木兰
展示当日排行前10条
ZREVRANGE hotvcr:20200919 0 9 withscores



rdbSave方法源码  rdbSaveBackground方法源码

```c
/* Save the DB on disk. Return REDIS_ERR on error, REDIS_OK on success 
 *
 * 将数据库保存到磁盘上。
 *
 * 保存成功返回 REDIS_OK ，出错/失败返回 REDIS_ERR 。
 */
int rdbSave(char *filename) {
    dictIterator *di = NULL;
    dictEntry *de;
    char tmpfile[256];
    char magic[10];
    int j;
    long long now = mstime();
    FILE *fp;
    rio rdb;
    uint64_t cksum;

    // 创建临时文件
    snprintf(tmpfile,256,"temp-%d.rdb", (int) getpid());
    fp = fopen(tmpfile,"w");
    if (!fp) {
        redisLog(REDIS_WARNING, "Failed opening .rdb for saving: %s",
                 strerror(errno));
        return REDIS_ERR;
    }

    // 初始化 I/O
    rioInitWithFile(&rdb,fp);

    // 设置校验和函数
    if (server.rdb_checksum)
        rdb.update_cksum = rioGenericUpdateChecksum;

    // 写入 RDB 版本号
    snprintf(magic,sizeof(magic),"REDIS%04d",REDIS_RDB_VERSION);
    if (rdbWriteRaw(&rdb,magic,9) == -1) goto werr;

    // 遍历所有数据库
    for (j = 0; j < server.dbnum; j++) {

        // 指向数据库
        redisDb *db = server.db+j;

        // 指向数据库键空间
        dict *d = db->dict;

        // 跳过空数据库
        if (dictSize(d) == 0) continue;

        // 创建键空间迭代器
        di = dictGetSafeIterator(d);
        if (!di) {
            fclose(fp);
            return REDIS_ERR;
        }

        /* Write the SELECT DB opcode 
         *
         * 写入 DB 选择器
         */
        if (rdbSaveType(&rdb,REDIS_RDB_OPCODE_SELECTDB) == -1) goto werr;
        if (rdbSaveLen(&rdb,j) == -1) goto werr;

        /* Iterate this DB writing every entry 
         *
         * 遍历数据库，并写入每个键值对的数据
         */
        while((de = dictNext(di)) != NULL) {
            sds keystr = dictGetKey(de);
            robj key, *o = dictGetVal(de);
            long long expire;

            // 根据 keystr ，在栈中创建一个 key 对象
            initStaticStringObject(key,keystr);

            // 获取键的过期时间
            expire = getExpire(db,&key);

            // 保存键值对数据
            if (rdbSaveKeyValuePair(&rdb,&key,o,expire,now) == -1) goto werr;
        }
        dictReleaseIterator(di);
    }
    di = NULL; /* So that we don't release it again on error. */

    /* EOF opcode 
     *
     * 写入 EOF 代码
     */
    if (rdbSaveType(&rdb,REDIS_RDB_OPCODE_EOF) == -1) goto werr;

    /* CRC64 checksum. It will be zero if checksum computation is disabled, the
     * loading code skips the check in this case. 
     *
     * CRC64 校验和。
     *
     * 如果校验和功能已关闭，那么 rdb.cksum 将为 0 ，
     * 在这种情况下， RDB 载入时会跳过校验和检查。
     */
    cksum = rdb.cksum;
    memrev64ifbe(&cksum);
    rioWrite(&rdb,&cksum,8);

    /* Make sure data will not remain on the OS's output buffers */
    // 冲洗缓存，确保数据已写入磁盘
    if (fflush(fp) == EOF) goto werr;
    if (fsync(fileno(fp)) == -1) goto werr;
    if (fclose(fp) == EOF) goto werr;

    /* Use RENAME to make sure the DB file is changed atomically only
     * if the generate DB file is ok. 
     *
     * 使用 RENAME ，原子性地对临时文件进行改名，覆盖原来的 RDB 文件。
     */
    if (rename(tmpfile,filename) == -1) {
        redisLog(REDIS_WARNING,"Error moving temp DB file on the final destination: %s", strerror(errno));
        unlink(tmpfile);
        return REDIS_ERR;
    }

    // 写入完成，打印日志
    redisLog(REDIS_NOTICE,"DB saved on disk");

    // 清零数据库脏状态
    server.dirty = 0;

    // 记录最后一次完成 SAVE 的时间
    server.lastsave = time(NULL);

    // 记录最后一次执行 SAVE 的状态
    server.lastbgsave_status = REDIS_OK;

    return REDIS_OK;

    werr:
    // 关闭文件
    fclose(fp);
    // 删除文件
    unlink(tmpfile);

    redisLog(REDIS_WARNING,"Write error saving DB on disk: %s", strerror(errno));

    if (di) dictReleaseIterator(di);

    return REDIS_ERR;
}

int rdbSaveBackground(char *filename) {
    pid_t childpid;
    long long start;

    // 如果 BGSAVE 已经在执行，那么出错
    if (server.rdb_child_pid != -1) return REDIS_ERR;

    // 记录 BGSAVE 执行前的数据库被修改次数
    server.dirty_before_bgsave = server.dirty;

    // 最近一次尝试执行 BGSAVE 的时间
    server.lastbgsave_try = time(NULL);

    // fork() 开始前的时间，记录 fork() 返回耗时用
    start = ustime();

    if ((childpid = fork()) == 0) {
        int retval;

        /* Child */

        // 关闭网络连接 fd
        closeListeningSockets(0);

        // 设置进程的标题，方便识别
        redisSetProcTitle("redis-rdb-bgsave");

        // 执行保存操作
        retval = rdbSave(filename);

        // 打印 copy-on-write 时使用的内存数
        if (retval == REDIS_OK) {
            size_t private_dirty = zmalloc_get_private_dirty();

            if (private_dirty) {
                redisLog(REDIS_NOTICE,
                    "RDB: %zu MB of memory used by copy-on-write",
                    private_dirty/(1024*1024));
            }
        }

        // 向父进程发送信号
        exitFromChild((retval == REDIS_OK) ? 0 : 1);

    } else {

        /* Parent */

        // 计算 fork() 执行的时间
        server.stat_fork_time = ustime()-start;

        // 如果 fork() 出错，那么报告错误
        if (childpid == -1) {
            server.lastbgsave_status = REDIS_ERR;
            redisLog(REDIS_WARNING,"Can't save in background: fork: %s",
                strerror(errno));
            return REDIS_ERR;
        }

        // 打印 BGSAVE 开始的日志
        redisLog(REDIS_NOTICE,"Background saving started by pid %d",childpid);

        // 记录数据库开始 BGSAVE 的时间
        server.rdb_save_time_start = time(NULL);

        // 记录负责执行 BGSAVE 的子进程 ID
        server.rdb_child_pid = childpid;

        // 关闭自动 rehash
        updateDictResizePolicy();

        return REDIS_OK;
    }

    return REDIS_OK; /* unreached */
}
```





1.识别Redis内存交换的检查方法如下：

1）查询Redis进程号：

```bash
redis-cli -p 6379 info server | grep process_id
```

2）根据进程号查询内存交换信息：

```bash
cat /proc/4476/smaps | grep Swap
```



2. reids脑裂

Redis 已经提供了两个配置项来限制主库的请求处理，分别是 min-slaves-to-write 和 min-slaves-max-lag。

min-slaves-to-write：这个配置项设置了主库能进行数据同步的最少从库数量；

min-slaves-max-lag：这个配置项设置了主从库间进行数据复制时，从库给主库发送 ACK 消息的最大延迟（以秒为单位）。

有了这两个配置项后，我们就可以轻松地应对脑裂问题了。具体咋做呢？我们可以把 min-slaves-to-write 和 min-slaves-max-lag 这两个配置项搭配起来使用，分别给它们设置一定的阈值，假设为 N 和 T。这两个配置项组合后的要求是，主库连接的从库中至少有 N 个从库，和主库进行数据复制时的 ACK 消息延迟不能超过 T 秒，否则，主库就不会再接收客户端的请求了。即使原主库是假故障，它在假故障期间也无法响应哨兵心跳，也不能和从库进行同步，自然也就无法和从库进行 ACK 确认了。这样一来，min-slaves-to-write 和 min-slaves-max-lag 的组合要求就无法得到满足，原主库就会被限制接收客户端请求，客户端也就不能在原主库中写入新数据了。

假设从库有 K 个，可以将 min-slaves-to-write 设置为 K/2+1（如果 K 等于 1，就设为 1），将 min-slaves-max-lag 设置为十几秒（例如 10～20s），在这个配置下，如果有一半以上的从库和主库进行的 ACK 消息延迟超过十几秒，我们就禁止主库接收客户端写请求。



## redis info命令

```bash
# Server
redis_version:3.2.3                  # Redis 的版本
redis_git_sha1:00000000              # Redis 的版本
redis_git_dirty:0
redis_build_id:9e93d0c7997bcfef
redis_mode:standalone                # 运行模式：单机（集群）
os:Linux 2.6.32-431.el6.x86_64 x86_64 # 操作系统
arch_bits:64                          # 操作系统位数
multiplexing_api:epoll               # redis所使用的事件处理机制
gcc_version:4.4.7                    # gcc版本号
process_id:1606                      # 当前 Redis 服务器进程id
run_id:17e79b1966f1f891eff203a8e496151ee8a3a7a7
tcp_port:7001                        # 端口号
uptime_in_seconds:4360189            # 运行时间(秒)
uptime_in_days:50                    # 运行时间(天)
hz:10                                # redis内部调度（进行关闭timeout的客户端，删除过期key等等）频率，程序规定serverCron每秒运行10次。
lru_clock:5070330                    # Redis的逻辑时钟
executable:/usr/local/bin/redis-server          # 启动脚本路径
config_file:/opt/redis3/conf/redis_7001.conf    # 启动指定的配置文件路径

# Clients
connected_clients:660                # 连接的客户端数量
client_longest_output_list:0         # 当前连接的客户端当中，最长的输出列表
client_biggest_input_buf:0           # 当前连接的客户端当中，最大输入缓存
blocked_clients:0                    # 阻塞的客户端数量

# Memory
used_memory:945408832               # 使用内存（B）
used_memory_human:901.61M           # 使用内存（MB）  
used_memory_rss:1148919808          # 系统给redis分配的内存（即常驻内存），这个值和top命令的输出一致
used_memory_rss_human:1.07G
used_memory_peak:1162079480         # 内存使用的峰值
used_memory_peak_human:1.08G        
total_system_memory:6136483840      # 整个系统内存
total_system_memory_human:5.72G
used_memory_lua:122880              # Lua脚本存储占用的内存
used_memory_lua_human:120.00K       
maxmemory:2147483648                # Redis实例的最大内存配置
maxmemory_human:2.00G
maxmemory_policy:allkeys-lru        # 当达到maxmemory时的淘汰策略
mem_fragmentation_ratio:1.22        # used_memory_rss/used_memory的比例。一般情况下，used_memory_rss略高于used_memory，当内存碎片较多时，则mem_fragmentation_ratio会较大，可以反映内存碎片是否很多
mem_allocator:jemalloc-4.0.3        # 内存分配器

# Persistence   
loading:0                                 # 服务器是否正在载入持久化文件
rdb_changes_since_last_save:82423954      # 离最近一次成功生成rdb文件，写入命令的个数                      
rdb_bgsave_in_progress:0                  # 服务器是否正在创建rdb文件           
rdb_last_save_time:1560991229             # 最近一次成功rdb文件的时间戳               
rdb_last_bgsave_status:ok                 # 最近一次成功rdb文件的状态           
rdb_last_bgsave_time_sec:-1               # 最近一次成功rdb文件的耗时            
rdb_current_bgsave_time_sec:-1            # 若当前正在创建rdb文件，指当前的创建操作已经耗费的时间                
aof_enabled:0                             # aof是否开启
aof_rewrite_in_progress:0                 # aof的rewrite操作是否在进行中            
aof_rewrite_scheduled:0                   # rewrite任务计划，当客户端发送bgrewriteaof指令，如果当前rewrite子进程正在执行，那么将客户端请求的bgrewriteaof变为计划任务，待aof子进程结束后执行rewrite        
aof_last_rewrite_time_sec:-1              # 最近一次aof rewrite耗费时长              
aof_current_rewrite_time_sec:-1           # 若当前正在执行aof rewrite，指当前的已经耗费的时间                
aof_last_bgrewrite_status:ok              # 最近一次aof bgrewrite的状态         
aof_last_write_status:ok                  # 最近一次aof写入状态  

# 开启aof后增加的一些info信息
-----------------------------  
aof_current_size:0                 # aof当前大小
aof_base_size:0                    # aof上次启动或rewrite的大小
aof_pending_rewrite:0              # 同上面的aof_rewrite_scheduled
aof_buffer_length:0                # aof buffer的大小
aof_rewrite_buffer_length:0        # aof rewrite buffer的大小
aof_pending_bio_fsync:0            # 后台IO队列中等待fsync任务的个数
aof_delayed_fsync:0                # 延迟的fsync计数器 
-----------------------------           

# Stats
total_connections_received:15815        # 自启动起连接过的总数。如果连接过多，说明短连接严重或连接池使用有问题，需调研代码的连接设置
total_commands_processed:502953838      # 自启动起运行命令的总数
instantaneous_ops_per_sec:7             # 每秒执行的命令数，相当于QPS
total_net_input_bytes:532510481889      # 网络入口流量字节数
total_net_output_bytes:1571444057940    # 网络出口流量字节数
instantaneous_input_kbps:0.37           # 网络入口kps
instantaneous_output_kbps:0.59          # 网络出口kps
rejected_connections:0                  # 拒绝的连接个数，由于maxclients限制，拒绝新连接的个数
sync_full:1                             # 主从完全同步成功次数
sync_partial_ok:0                       # 主从部分同步成功次数
sync_partial_err:0                      # 主从部分同步失败次数
expired_keys:4404930                    # 自启动起过期的key的总数
evicted_keys:0                          # 使用内存大于maxmemory后，淘汰的key的总数
keyspace_hits:337104556                 # 在main dictionary字典中成功查到的key个数
keyspace_misses:22865229                # 同上，未命中的key的个数
pubsub_channels:1                       # 发布/订阅频道数
pubsub_patterns:0                       # 发布/订阅模式数
latest_fork_usec:707                    # 上次的fork操作使用的时间（单位ms）
migrate_cached_sockets:0                # 是否已经缓存了到该地址的连接
slave_expires_tracked_keys:0            # 从实例到期key数量
active_defrag_hits:0                    # 主动碎片整理命中次数
active_defrag_misses:0                  # 主动碎片整理未命中次数
active_defrag_key_hits:0                # 主动碎片整理key命中次数
active_defrag_key_misses:0              # 主动碎片整理key未命中次数


# Replication
role:master                           # 当前实例的角色master还是slave
connected_slaves:1                    # slave的数量
master_replid:8f81c045a2cb00f16a7fc5c90a95e02127413bcc      # 主实例启动随机字符串
master_replid2:0000000000000000000000000000000000000000     # 主实例启动随机字符串2
slave0:ip=172.17.12.251,port=7002,state=online,offset=506247209326,lag=1    # slave机器的信息、状态
master_repl_offset:506247209478       # 主从同步偏移量,此值如果和上面的offset相同说明主从一致没延迟，与master_replid可被用来标识主实例复制流中的位置。
second_repl_offset                    # 主从同步偏移量2,此值如果和上面的offset相同说明主从一致没延迟
repl_backlog_active:1                 # 复制缓冲区是否开启
repl_backlog_size:157286400           # 复制缓冲区大小
repl_backlog_first_byte_offset:506089923079     # 复制缓冲区里偏移量的大小
repl_backlog_histlen:157286400        # 此值等于 master_repl_offset - repl_backlog_first_byte_offset,该值不会超过repl_backlog_size的大小

# CPU
used_cpu_sys:6834.06                  # 将所有redis主进程在核心态所占用的CPU时求和累计起来
used_cpu_user:8282.10                 # 将所有redis主进程在用户态所占用的CPU时求和累计起来
used_cpu_sys_children:0.11            # 后台进程的核心态cpu使用率
used_cpu_user_children:0.91           # 后台进程的用户态cpu使用率

# Cluster
cluster_enabled:0       # 实例是否启用集群模式

# Keyspace      # 各个数据库（0-15）的 key 的数量，带有生存期的 key 的数量，平均存活时间
db0:keys=267906,expires=109608,avg_ttl=3426011859194
db1:keys=182,expires=179,avg_ttl=503527626
db8:keys=6,expires=0,avg_ttl=0
db15:keys=2,expires=0,avg_ttl=0
```







[如何优雅地用Redis实现分布式锁](https://baijiahao.baidu.com/s?id=1623086259657780069&wfr=spider&for=pc)

[redis官方中文文档](http://www.redis.cn/topics/distlock.html)

[从应用到底层 36张图带你进入Redis世界](https://www.jianshu.com/p/1ac051c4184c)

[Redis的Gossip协议](https://mp.weixin.qq.com/s/dW0I29Sw86lU0qHpxyhdmw)

[bitmap算法和布隆过滤器](https://blog.csdn.net/zk3326312/article/details/79411089)

[详解布隆过滤器的原理，使用场景和注意事项](https://zhuanlan.zhihu.com/p/43263751)

[redis源码中文注释版](https://github.com/huangz1990/redis-3.0-annotated)

[Redis为什么变慢了？一文讲透如何排查Redis性能问题 | 万字长文](https://mp.weixin.qq.com/s?__biz=MzIyOTYxNDI5OA==&mid=2247484679&idx=1&sn=3273e2c9083e8307c87d13a441a267d7&chksm=e8beb2b2dfc93ba4c28c95fdcb62eefc529d6a4ca2b4971ad0493319adbf8348b318224bd3d9&scene=126&sessionid=1620722607&key=ad5be9c1f718c28a9033eeedbbe79fd302cadedabdc13a087e2fb435b239eaefbaee58e884921f26a839421ab1384c69740805d07315fe2dc5a29c7c083070239ce6ed28867256bfa43882988c542345c43ef81dd19f6a51810e5fb976e893f2e6e4ba3fbe126a6df6970baf556d2bdf54061e7951487b904476a6c70ac1ad73&ascene=1&uin=MTgxNTEwNTUxMw%3D%3D&devicetype=Windows+10+x64&version=62090529&lang=zh_CN&exportkey=AdyXaPAP7wvx%2BeRkwIIOVWk%3D&pass_ticket=sI7CTYvq1IlenOAd9YcWpdKNJxp4DyE5Yj6KD%2Bxkxtzu3E7KsMUhwkz9nvSpglFA&wx_header=0)

[Redis最佳实践：7个维度+43条使用规范，带你彻底玩转Redis | 附实践清单](https://mp.weixin.qq.com/s?__biz=MzIyOTYxNDI5OA==&mid=2247484890&idx=1&sn=6f6b550638e14df42646a9119d623bb4&chksm=e8beb26fdfc93b79a77fcafa5f42d5980b7a1230ede1314b9bf895f14fea03351418d58cb56c&scene=126&sessionid=1620722607&key=b7d01f67262b97891b32588f222ec53eaa354c79478c5d634d33702bb769284221df26b7c65cca3bd1772c1b438f008fa464a63bd484f968afd908dc842340789878c62f79ec3dddec9cf83e85a3c42388541e9f4043d359d53bfab6f9230aa0a94b22b08e2c766b47ef728753040e77dac1955dcaa849c6b65480e77fa515a3&ascene=1&uin=MTgxNTEwNTUxMw%3D%3D&devicetype=Windows+10+x64&version=62090529&lang=zh_CN&exportkey=AcqgwCXTCElvW5K5ej8ntEM%3D&pass_ticket=sI7CTYvq1IlenOAd9YcWpdKNJxp4DyE5Yj6KD%2Bxkxtzu3E7KsMUhwkz9nvSpglFA&wx_header=0)

[Redis 6.X Cluster 集群搭建](https://mp.weixin.qq.com/s?__biz=MzU3NDkwMjAyOQ==&mid=2247486674&idx=1&sn=f265262eb90c312ddaf6b8ddfcbfa646&scene=21#wechat_redirect)

[为什么Redis集群有16384个槽](https://www.cnblogs.com/rjzheng/p/11430592.html)

[redis调优 -- 内存碎片](https://www.cnblogs.com/grimm/p/10288116.html)

[Redis info命令中各个参数的含义](https://zhuanlan.zhihu.com/p/78297083)



1.redis使用的问题

设计实时数据模块。

**需求：**

设备实时上传数据，所以需要批量更新。界面、后台接口实时查询数据，所以需要快速响应查询。

需要可以根据各种平台公司项目国家省份城市各种维度去查询设备以及设备的实时状态。（复杂条件分页等各种查询）

可以快速查询某个设备的实时状态。（key-value）

可以根据各个维度统计在线的设备个数、离线的设备个数。（count）

数据量大概在30w左右



* 如果使用mysql存储设备实时状态

在设备、iot表里面都增加是否在线等表示实时状态的字段，这样的优点在于使用关系型数据库，使用sql可以很方便的实现各种复杂条件查询，分页查询。缺点在于慢。而且不一定能顶住更新和查询的压力

* 如果使用redis以key-value的方式存储设备状态

redis的话更新和单独查询某一个设备的实时状态时是非常快的，但是有个缺点是无法做各种复杂条件以及分页查询，只适合key-value形式的查询。



最开始的思路其实还是使用redis来做，如果只需要考虑统计这个需求，可以按最小维度项目来建立数据模型，以项目id为key,维护2个set ，一个在线set,一个离线set，这样可以快速获取某个项目在线数量和离线数量，其他维度就可以通过项目维度来聚合，但是如果要做分页查询就无法做到以及根据设备其他字段去做条件过滤就无法做到。这样的设计也无法扩展。

决定结合redis和mysql一起来使用，既然我们必须用到mysql的复杂关联查询，最后的数据还是以表的形式存储在mysql中，但是提交数据更新数据的压力和部分查询的压力我们可以通过redis来做一层缓存过滤，因为其实很多设备的数据状态每次上传都是一样的，相同的意味着并不需要更新数据库。我们可以将实时数据存在redis中，然后推送的数据与redis中的数据进行比对，如果实时值改变了，才真正的去更新mysql中的数据。这样虽然每次推送的数据很多，其实真正到达mysql的需要更新的数据量是比较少的。

在redis中给每个设备维护一个实时状态的key-value，同时建立一张实时状态的从表。

这样我们同时也可以将一部分某个设备实时状态的这种查询压力分担给redis，毕竟redis应付这种key-value查询是非常适合的。如果需要做复杂关联查询，那么我们可以使用状态表与其他表做链接，可以轻松的做到统计、复杂条件查询、分页。

推送数据上来时先判断是否在redis中，不在的话说明是第一次上传数据，插入数据库。如果在的话，就拿redis里面的实时状态值与上传的做比对，如果更新了值采取更改数据库。

这样可以同时取到了两种数据库的优点。



在实现的过程中，碰到的问题：

**使用pipeline优化redis批量取数据**

因为采用这种方式每次推送数据上来都需要先查询redis，如果推送5000条，那么就需要查询5000次，最开始使用了循环的方式获取发现取700次数据花费了将近25S！！！这种速度几乎是不可接受的。第一反应是写mysql或者是写redis比较慢，因为在大家的印象中去redis取数据应该是非常快的操作，但后面经过实际测试发现，写入mysql和批量写入redis几乎都是毫秒级的操作，最花费时间的就是去redis取数据这个操作。测试发现redis执行命令的时间还是很快的，花费的时间都是在请求往返上。（网络延迟开销。因为某种原因我们redis是在公网上）发现这个问题后很快的使用pipeline将循环取数据的代码优化了下。（最开始没使用pipeline方式获取数据是因为以为pipeline获取keys的值是没有办法排序的。后来发现keys数据和返回的值数组下标是一一对应的）

接口的耗时从原来的25S下降到了0.4S  几乎是几十倍的性能提升！！

测试延迟，其host和port是Redis实例的ip及端口。由于当前服务器不同的运行情况，延迟时间可能有所误差，通常1G网卡的延迟时间是200μs。若是延迟时间远高于200μs，那明显是出现了性能问题。 

```bash
./redis-cli --latency -h ***.**.**.122 -p 6379
min: 40, max: 45, avg: 41.19 (5444 samples)
```

测试延迟达到了40ms

而在内网中的延迟只有180us

````bash
min: 0, max: 5, avg: 0.18 (9866 samples)
````









2.redis设计缓存系统

缓存模块设计

缓存雪崩穿透击穿



怎么保持热点数据，淘汰策略，过期键清除策略，

* MySQL 里有 2000w 数据，Redis 中只存 20w 的数据，如何保证 Redis 中的数据都是热点数据？

  > Redis 内存数据集大小上升到一定大小的时候，就会施行数据淘汰策略。
  >
  > - volatile-lru：从已设置过期时间的数据集（server.db[i].expires）中挑选最近最少使用的数据淘汰
  > - volatile-ttl：从已设置过期时间的数据集（server.db[i].expires）中挑选将要过期的数据淘汰
  > - volatile-random：从已设置过期时间的数据集（server.db[i].expires）中任意选择数据淘汰
  > - allkeys-lru：从数据集（server.db[i].dict）中挑选最近最少使用的数据淘汰
  > - allkeys-random：从数据集（server.db[i].dict）中任意选择数据淘汰
  > - no-enviction（驱逐）：禁止驱逐数据



RDB和AOF持久化



RedisObject（redis的几种数据结构）



redis内存使用估算、内存碎片



分布式锁



三种集群模式：主从、哨兵、cluster切片集群











3.redisTemplate获取connection执行原生的redis命令时，命令结束不会将从连接池里面的连接还个还给连接池，会一直处于allocate状态，正常应该时idle状态，如果要使用的话可以使用redisTemplate的execute方法。

![1628647797409](C:\Users\miao\AppData\Roaming\Typora\typora-user-images\1628647797409.png)



使用完后可以使用来释放连接

```java
RedisConnectionUtils.releaseConnection(conn, factory);
```

[springboot研究九：lettuce连接池很香，撸撸它的源代码](https://blog.csdn.net/zjj2006/article/details/106876235?utm_medium=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7EBlogCommendFromMachineLearnPai2%7Edefault-1.control&depth_1-utm_source=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7EBlogCommendFromMachineLearnPai2%7Edefault-1.control)



4.执行lua脚本

```bash
执行命令： redis-cli -a 密码 --eval Lua脚本路径 key [key …] ,  arg [arg …] 
如：redis-cli -a 123456 --eval ./Redis_CompareAndSet.lua userName , zhangsan lisi 
```

"--eval"而不是命令模式中的"eval"，一定要有前端的两个-
脚本路径后紧跟key [key …]，相比命令行模式，少了numkeys这个key数量值
key [key …] 和 arg [arg …] 之间的“ , ”，英文逗号前后必须有空格，否则死活都报错









