## synchronized

虽然多线程编程极大地提高了效率，但是也会带来一定的隐患。比如说两个线程同时往一个数据库表中插入不重复的数据，就可能会导致数据库中插入了相同的数据。

### 一. 什么时候会出现线程安全问题

在单线程中不会出现线程安全问题，而在多线程编程中，有可能会出现同时访问同一个资源的情况，这种资源可以是各种类型的的资源：一个变量、一个对象、一个文件、一个数据库表等，而当多个线程同时访问同一个资源的时候，就会存在一个问题：

**由于每个线程执行的过程是不可控的，所以很可能导致最终的结果与实际上的愿望相违背或者直接导致程序出错。**

举个简单的例子：

现在有两个线程分别从网络上读取数据，然后插入一张数据库表中，要求不能插入重复的数据。

那么必然在插入数据的过程中存在两个操作：

　　1）检查数据库中是否存在该条数据；

　　2）如果存在，则不插入；如果不存在，则插入到数据库中。

假如两个线程分别用thread-1和thread-2表示，某一时刻，thread-1和thread-2都读取到了数据X，那么可能会发生这种情况：

thread-1去检查数据库中是否存在数据X，然后thread-2也接着去检查数据库中是否存在数据X。

结果两个线程检查的结果都是数据库中不存在数据X，那么两个线程都分别将数据X插入数据库表当中。

这个就是线程安全问题，即**多个线程同时访问一个资源时，会导致程序运行结果并不是想看到的结果。**

这里面，这个资源被称为：**临界资源（也有称为共享资源）。**

也就是说，当多个线程同时访问临界资源（一个对象，对象中的属性，一个文件，一个数据库等）时，就可能会产生线程安全问题。

不过，当多个线程执行一个方法，方法内部的局部变量并不是临界资源，因为方法是在栈上执行的，而Java栈是线程私有的，因此不会产生线程安全问题。

### 二. 如何解决线程安全问题

那么一般来说，是如何解决线程安全问题的呢？

基本上所有的并发模式在解决线程安全问题时，都采用“序列化访问临界资源”的方案，即在同一时刻，只能有一个线程访问临界资源，也称作同步互斥访问。

通常来说，是在访问临界资源的代码前面加上一个锁，当访问完临界资源后释放锁，让其他线程继续访问。

在Java中，提供了两种方式来实现同步互斥访问：synchronized和Lock，本文主要讲述synchronized

### 三. synchronized同步方法或者同步块

在了解synchronized关键字的使用方法之前，我们先来看一个概念：互斥锁，顾名思义：能到达到互斥访问目的的锁。

举个简单的例子：如果对临界资源加上互斥锁，当一个线程在访问该临界资源时，其他线程便只能等待。

在Java中，每一个对象都拥有一个锁标记（monitor），也称为监视器，多线程同时访问某个对象时，线程只有获取了该对象的锁才能访问。

在Java中，可以使用synchronized关键字来标记一个方法或者代码块，当某个线程调用该对象的synchronized方法或者访问synchronized代码块时，这个线程便获得了该对象的锁，其他线程暂时无法访问这个方法，只有等待这个方法执行完毕或者代码块执行完毕，这个线程才会释放该对象的锁，其他线程才能执行这个方法或者代码块。

下面通过几个简单的例子来说明synchronized关键字的使用：

1. **synchronized方法**

下面这段代码中两个线程分别调用insertData对象插入数据：

```java
public class Test {

    public static void main(String[] args)  {
        final InsertData insertData = new InsertData();

        new Thread(() -> insertData.insert(Thread.currentThread())).start();


        new Thread(() -> insertData.insert(Thread.currentThread())).start();
    }
}

class InsertData {
    private ArrayList<Integer> arrayList = new ArrayList<Integer>();

    public void insert(Thread thread){
        for(int i=0;i<5;i++){
            System.out.println(thread.getName()+"在插入数据"+i);
            arrayList.add(i);
        }
    }
}
```

```bash
Thread-0在插入数据0
Thread-1在插入数据0
Thread-1在插入数据1
Thread-0在插入数据1
Thread-1在插入数据2
Thread-1在插入数据3
Thread-1在插入数据4
Thread-0在插入数据2
Thread-0在插入数据3
Thread-0在插入数据4
```

说明两个线程在同时执行insert方法。

而如果在insert方法前面加上关键字synchronized的话，运行结果为：

```java
class InsertData {
    private ArrayList<Integer> arrayList = new ArrayList<Integer>();
     
    public synchronized void insert(Thread thread){
        for(int i=0;i<5;i++){
            System.out.println(thread.getName()+"在插入数据"+i);
            arrayList.add(i);
        }
    }
}
```

```bash
Thread-0在插入数据0
Thread-0在插入数据1
Thread-0在插入数据2
Thread-0在插入数据3
Thread-0在插入数据4
Thread-1在插入数据0
Thread-1在插入数据1
Thread-1在插入数据2
Thread-1在插入数据3
Thread-1在插入数据4
```

从上输出结果说明，Thread-1插入数据是等Thread-0插入完数据之后才进行的。说明Thread-0和Thread-1是顺序执行insert方法的。

这就是synchronized方法

不过有几点需要注意：

　　1）当一个线程正在访问一个对象的synchronized方法，那么其他线程不能访问该对象的其他synchronized方法。这个原因很简单，因为一个对象只有一把锁，当一个线程获取了该对象的锁之后，其他线程无法获取该对象的锁，所以无法访问该对象的其他synchronized方法。

　　2）当一个线程正在访问一个对象的synchronized方法，那么其他线程能访问该对象的非synchronized方法。这个原因很简单，访问非synchronized方法不需要获得该对象的锁，假如一个方法没用synchronized关键字修饰，说明它不会使用到临界资源，那么其他线程是可以访问这个方法的，

　　3）如果一个线程A需要访问对象object1的synchronized方法fun1，另外一个线程B需要访问对象object2的synchronized方法fun1，即使object1和object2是同一类型），也不会产生线程安全问题，因为他们访问的是不同的对象，所以不存在互斥问题。

2. **synchronized代码块**

synchronized代码块类似于以下这种形式:

```java
synchronized(synObject) {
         
}
```

当在某个线程中执行这段代码块，该线程会获取对象synObject的锁，从而使得其他线程无法同时访问该代码块。

synObject可以是this，代表获取当前对象的锁，也可以是类中的一个属性，代表获取该属性的锁。

比如上面的insert方法可以改成以下两种形式：

```java
class InsertData {
    private ArrayList<Integer> arrayList = new ArrayList<Integer>();

    public void insert(Thread thread){
        synchronized (this) {  //这里
            for(int i=0;i<100;i++){
                System.out.println(thread.getName()+"在插入数据"+i);
                arrayList.add(i);
            }
        }
    }
}

```

```java
class InsertData {
    private ArrayList<Integer> arrayList = new ArrayList<Integer>();
    private Object object = new Object();
     
    public void insert(Thread thread){
        synchronized (object) {  //这里
            for(int i=0;i<100;i++){
                System.out.println(thread.getName()+"在插入数据"+i);
                arrayList.add(i);
            }
        }
    }
}
```

从上面可以看出，synchronized代码块使用起来比synchronized方法要灵活得多。因为也许一个方法中只有一部分代码只需要同步，如果此时对整个方法用synchronized进行同步，会影响程序执行效率。而使用synchronized代码块就可以避免这个问题，synchronized代码块可以实现只对需要同步的地方进行同步。

另外，每个类也会有一个锁，它可以用来控制对static数据成员的并发访问。

并且如果一个线程执行一个对象的非static synchronized方法，另外一个线程需要执行这个对象所属类的static synchronized方法，此时不会发生互斥现象，因为访问static synchronized方法占用的是类锁，而访问非static synchronized方法占用的是对象锁，所以不存在互斥现象。

看下面这段代码就明白了：

```java
public class Test {

    public static void main(String[] args)  {
        final InsertData insertData = new InsertData();
        new Thread(() -> insertData.insert()).start();
        new Thread(() -> insertData.insert1()).start();
    }
}

class InsertData {
    public synchronized void insert(){
        System.out.println("执行insert");
        try {
            Thread.sleep(5000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("执行insert完毕");
    }

    public synchronized static void insert1() {
        System.out.println("执行insert1");
        System.out.println("执行insert1完毕");
    }
}
```

```bash
执行insert
执行insert1
执行insert1完毕
执行insert完毕
```

下面我们看一下synchronized关键字到底做了什么事情，我们来反编译它的字节码看一下，下面这段代码反编译后的字节码为：

```java
public class InsertData {
    private Object object = new Object();
     
    public void insert(Thread thread){
        synchronized (object) {
         
        }
    }
     
    public synchronized void insert1(Thread thread){
         
    }
     
    public void insert2(Thread thread){
         
    }
}
```

```java
public class InsertData {
  public InsertData();
    Code:
       0: aload_0
       1: invokespecial #1                  // Method java/lang/Object."<init>":()V
       4: aload_0
       5: new           #2                  // class java/lang/Object
       8: dup
       9: invokespecial #1                  // Method java/lang/Object."<init>":()V
      12: putfield      #3                  // Field object:Ljava/lang/Object;
      15: return

  public void insert(java.lang.Thread);
    Code:
       0: aload_0
       1: getfield      #3                  // Field object:Ljava/lang/Object;
       4: dup
       5: astore_2
       6: monitorenter  
       7: aload_2
       8: monitorexit	
       9: goto          17
      12: astore_3
      13: aload_2
      14: monitorexit
      15: aload_3
      16: athrow
      17: return
    Exception table:
       from    to  target type
           7     9    12   any
          12    15    12   any

  public synchronized void insert1(java.lang.Thread);
    Code:
       0: return

  public void insert2(java.lang.Thread);
    Code:
       0: return
}
```

从反编译获得的字节码可以看出，synchronized代码块实际上多了**monitorenter**和**monitorexit**两条指令。monitorenter指令执行时会让对象的锁计数加1，而monitorexit指令执行时会让对象的锁计数减1，其实这个与操作系统里面的PV操作很像，操作系统里面的PV操作就是用来控制多个线程对临界资源的访问。对于synchronized方法，执行中的线程识别该方法的 method_info 结构是否有 ACC_SYNCHRONIZED 标记设置，然后它自动获取对象的锁，调用方法，最后释放锁。如果有异常发生，线程自动释放锁。

有一点要注意：**对于synchronized方法或者synchronized代码块，当出现异常时，JVM会自动释放当前线程占用的锁，因此不会由于异常导致出现死锁现象。**





1. 关于 synchronized的偏向锁、轻量锁，重量锁和锁升级。（jdk6 之后对synchronized的优化）

​		实际上synchronized的重量锁涉及到线程的阻塞和唤醒，底层是使用pthread来实现的，涉及到系统调用，而涉及到系统调用就肯定会涉及到操作系统内核态和用户态的转换，所以这是一个非常消耗资源的操作，这可能就是为什么称为重量锁吧。其实这个时候就会想到要优化这个操作了，因为如果再阻塞后该锁立即被释放了，实际只需要稍微等一下下就能拿到锁，实际这时候就完全不需要加这个重量级锁，所以这里的优化方案其实就是**自旋**，自旋其实就是空转cpu，目的就是不让出cpu等待锁的释放。正常情况下锁获取失败就应该阻塞入队，但是有时候可能刚一阻塞，别的线程就释放锁了，然后再唤醒刚刚阻塞的线程，这就没必要了。

​		优化的后续步骤就是引入轻量级锁了。多个线程都是在不同的时间段来请求同一把锁，此时根本就用不需要阻塞线程，连 monitor 对象都不需要，所以就引入了轻量级锁这个概念，避免了系统调用，减少了开销。轻量级锁取消了系统调用阻塞，线程堆栈中开辟一个LockRecord区域(DisplacedMarkWord)，然后把锁对象的对象头中的markword拷贝到一份LockRecord中，最后通过cas把锁对象头指向这个LockRecord。**注意如果这里cas失败代表是有竞争的，这时候就会膨胀成为重量锁。**

> 线程1获取轻量级锁时会先把锁对象的对象头MarkWord复制一份到线程1的栈帧中创建的用于存储锁记录的空间（称为DisplacedMarkWord），然后使用CAS把对象头中的内容替换为线程1存储的锁记录（DisplacedMarkWord）的地址；
>
> 如果在线程1复制对象头的同时（在线程1CAS之前），线程2也准备获取锁，复制了对象头到线程2的锁记录空间中，但是在线程2CAS的时候，发现线程1已经把对象头换了，线程2的CAS失败，那么线程2就尝试使用自旋锁来等待线程1释放锁。 自旋锁简单来说就是让线程2在循环中不断CAS
>
> 但是如果自旋的时间太长也不行，因为自旋是要消耗CPU的，因此自旋的次数是有限制的，比如10次或者100次，如果自旋次数到了线程1还没有释放锁，或者线程1还在执行，线程2还在自旋等待，这时又有一个线程3过来竞争这个锁对象，那么这个时候轻量级锁就会膨胀为重量级锁。重量级锁把除了拥有锁的线程都阻塞，防止CPU空转。

​		现在要引入偏向锁，是否有这样的场景：一开始一直只有一个线程持有这个锁，也不会有其他线程来竞争，此时频繁的 CAS 是没有必要的，CAS 也是有开销的。如果当前锁对象支持偏向锁，那么就会通过 CAS 操作：将当前线程的地址(也当做唯一ID)记录到 markword 中，并且将标记字段的最后三位设置为 101。之后有线程请求这把锁，只需要判断 markword 最后三位是否为 101，是否指向的是当前线程的地址。还有一个可能很多文章会漏的点，就是还需要判断 epoch 值是否和锁对象的类中的 epoch 值相同。如果都满足，那么说明当前线程持有该偏向锁，就可以直接返回。**偏向锁在有竞争的时候是要执行撤销操作的（撤销为无锁状态），其实就是要升级成轻量级锁。**

> 当线程1访问代码块并获取锁对象时，会在java对象头和栈帧中记录偏向的锁的threadID，因为偏向锁不会主动释放锁，因此以后线程1再次获取锁的时候，需要比较当前线程的threadID和Java对象头中的threadID是否一致，如果一致（还是线程1获取锁对象），则无需使用CAS来加锁、解锁；如果不一致（其他线程，如线程2要竞争锁对象，而偏向锁不会主动释放因此还是存储的线程1的threadID），那么需要查看Java对象头中记录的线程1是否存活，如果没有存活，那么锁对象被重置为无锁状态，其它线程（线程2）可以竞争将其设置为偏向锁；如果存活，那么立刻查找该线程（线程1）的栈帧信息，如果还是需要继续持有这个锁对象，那么暂停当前线程1，撤销偏向锁，升级为轻量级锁，如果线程1 不再使用该锁对象，那么将锁对象状态设为无锁状态，重新偏向新的线程。















[关于 Synchronized 的一个点，网上99%的文章都错了](https://mp.weixin.qq.com/s/3PBGQBR9DNphE7jSMvOHXQ)

[面试官：说一下Synchronized底层实现，锁升级的具体过程？](https://blog.csdn.net/zzti_erlie/article/details/103997713)