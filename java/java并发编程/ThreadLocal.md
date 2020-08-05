## ThreadLocal

### 一、ThreadLocal简介

​		多线程访问同一个共享变量的时候容易出现并发问题，特别是多个线程对一个变量进行写入的时候，为了保证线程安全，一般使用者在访问共享变量的时候需要进行额外的同步措施才能保证线程安全性。ThreadLocal是除了加锁这种同步方式之外的一种保证一种规避多线程访问出现线程不安全的方法，当我们在创建一个变量后，如果每个线程对其进行访问的时候访问的都是线程自己的变量这样就不会存在线程不安全问题。

　　ThreadLocal是JDK包提供的，它提供线程本地变量，如果创建一个ThreadLocal变量，那么访问这个变量的每个线程都会有这个变量的一个副本，在实际多线程操作的时候，操作的是自己本地内存中的变量，从而规避了线程安全问题

​		**ThreadLocal只是一个工具类，他为用户提供get、set、remove接口操作实际存放本地变量的threadLocals（调用线程的成员变量）**

​		每个线程内部有一个名为threadLocals的成员变量，该变量的类型为ThreadLocal.ThreadLocalMap类型（类似于一个HashMap），**ThreadLocalMap使用了开放寻址法解决hash冲突（当数据量较小，装载因子较小时，适合采用开放寻址法）**，其中的key为当前定义的ThreadLocal变量的this引用，value为我们使用set方法设置的值。每个线程的本地变量存放在自己的本地内存变量threadLocals中，如果当前线程一直不消亡，那么这些本地变量就会一直存在（所以可能会导致内存溢出），因此使用完毕需要将其remove掉。

### 二、源码

1. set方法源码

```java
public void set(T value) {
    //(1)获取当前线程（调用者线程）
    Thread t = Thread.currentThread();
    //(2)以当前线程作为key值，去查找对应的线程变量，找到对应的map
    ThreadLocalMap map = getMap(t);
    //(3)如果map不为null，就直接添加本地变量，key为当前线程，值为添加的本地变量值
    if (map != null)
        map.set(this, value);
    //(4)如果map为null，说明首次添加，需要首先创建出对应的map
    else
        createMap(t, value);
}
```

在上面的代码中，(2)处调用getMap方法获得当前线程对应的threadLocals(参照上面的图示和文字说明)，该方法代码如下

```java
ThreadLocalMap getMap(Thread t) {
    return t.threadLocals; //获取线程自己的变量threadLocals，并绑定到当前调用线程的成员变量threadLocals上
}
```

如果调用getMap方法返回值不为null，就直接将value值设置到threadLocals中（key为当前线程引用，值为本地变量）；如果getMap方法返回null说明是第一次调用set方法（前面说到过，threadLocals默认值为null，只有调用set方法的时候才会创建map），这个时候就需要调用createMap方法创建threadLocals，该方法如下所示

```java
void createMap(Thread t, T firstValue) {
    t.threadLocals = new ThreadLocalMap(this, firstValue);
}
```

2. get方法源码

在get方法的实现中，首先获取当前调用者线程，如果当前线程的threadLocals不为null，就直接返回当前线程绑定的本地变量值，否则执行setInitialValue方法初始化threadLocals变量。在setInitialValue方法中，类似于set方法的实现，都是判断当前线程的threadLocals变量是否为null，是则添加本地变量（这个时候由于是初始化，所以添加的值为null），否则创建threadLocals变量，同样添加的值为null。

```java
public T get() {
    //(1)获取当前线程
    Thread t = Thread.currentThread();
    //(2)获取当前线程的threadLocals变量
    ThreadLocalMap map = getMap(t);
    //(3)如果threadLocals变量不为null，就可以在map中查找到本地变量的值
    if (map != null) {
        ThreadLocalMap.Entry e = map.getEntry(this);
        if (e != null) {
            @SuppressWarnings("unchecked")
            T result = (T)e.value;
            return result;
        }
    }
    //(4)执行到此处，threadLocals为null，调用该更改初始化当前线程的threadLocals变量
    return setInitialValue();
}

private T setInitialValue() {
    //protected T initialValue() {return null;}
    T value = initialValue();
    //获取当前线程
    Thread t = Thread.currentThread();
    //以当前线程作为key值，去查找对应的线程变量，找到对应的map
    ThreadLocalMap map = getMap(t);
    //如果map不为null，就直接添加本地变量，key为当前线程，值为添加的本地变量值
    if (map != null)
        map.set(this, value);
    //如果map为null，说明首次添加，需要首先创建出对应的map
    else
        createMap(t, value);
    return value;
}
```

3. remove方法源码

```java
public void remove() {
    //获取当前线程绑定的threadLocals
     ThreadLocalMap m = getMap(Thread.currentThread());
     //如果map不为null，就移除当前线程中指定ThreadLocal实例的本地变量
     if (m != null)
         m.remove(this);
 }
```

### 三. 获取父线程的本地变量值

​		如何让子线程获取到父线程的ThreadLocal，其实在线程中除了ThreadLocal外还有InheritableThreadLocal，顾名思义，可继承的线程变量表，可以让子线程获取到父线程中ThreadLocal的值

```c#
public class BaseTest {

    public static  final InheritableThreadLocal<String> inheritableThreadLocal = new InheritableThreadLocal<>();
    public static final ThreadLocal<String> threadLocal = new ThreadLocal<>();

    public static void main(String[] args) {
        inheritableThreadLocal.set("Inheritable hello");
        threadLocal.set("hello");
        new Thread(()->{
            System.out.println(String.format("子线程可继承值：%s",inheritableThreadLocal.get()));
            System.out.println(String.format("子线程值：%s",threadLocal.get()));
            new Thread(()->{
                System.out.println(String.format("孙子线程可继承值：%s",inheritableThreadLocal.get()));
                System.out.println(String.format("孙子线程值：%s",threadLocal.get()));
            }).start();

        }).start();


    }
```



```c#
/* ThreadLocal values pertaining to this thread. This map is maintained
     * by the ThreadLocal class. */
    ThreadLocal.ThreadLocalMap threadLocals = null;

    /*
     * InheritableThreadLocal values pertaining to this thread. This map is
     * maintained by the InheritableThreadLocal class.
     */
    ThreadLocal.ThreadLocalMap inheritableThreadLocals = null;
```

如果允许new的线程继承当前线程的threadlocalMap，那么new的线程会copy一份当前线程也就是父线程的inheritableThreadLocals 。这儿也可以说明继承有两条件，**new的线程允许继承(默认允许)，父线程的inheritableThreadLocals 不为null**

```c#
Thread parent = currentThread();      
//省略代码  
if (inheritThreadLocals && parent.inheritableThreadLocals != null)
            this.inheritableThreadLocals =
                ThreadLocal.createInheritedMap(parent.inheritableThreadLocals);
```

**这儿要注意不管是创建ThreadLocal还是inheritableThreadLocals(如果父线程没有) 的ThreadLocalMap都是在Threadlocal.set方法的时候创建的，即懒加载**

```c#
public void set(T value) {
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t);
        if (map != null)
            map.set(this, value);
        else
            createMap(t, value);
    }
```

