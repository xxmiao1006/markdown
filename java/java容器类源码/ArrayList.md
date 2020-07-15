## ArrayList

从构造函数到一些常用方法阅读ArrayList源码。（jdk1.8）了解里面的实际原理以及扩容机制。

### 1.变量

```java
//数组的默认大小
private static final int DEFAULT_CAPACITY = 10;
//空对象数组
private static final Object[] EMPTY_ELEMENTDATA = {};
//默认空对象数组
private static final Object[] DEFAULTCAPACITY_EMPTY_ELEMENTDATA = {};
//实际存储数据的数组 下面简称data
transient Object[] elementData;
//数组实际的长度
private int size;
// 最大数组容量
private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;
```



### 2.构造函数

有三种构造函数

```java
//1.无参构造函数，将element置为默认的空数组（初始化容量是在第一次添加数据的时候）  
public ArrayList() {
     this.elementData = DEFAULTCAPACITY_EMPTY_ELEMENTDATA;
}
//2.带参的构造函数
public ArrayList(int initialCapacity) {
        if (initialCapacity > 0) {
            //如果入参大于0，则使用入参初始化实际的数组大小
            this.elementData = new Object[initialCapacity];
        } else if (initialCapacity == 0) {
            //如果入参等于0，则等于空对象数组
            this.elementData = EMPTY_ELEMENTDATA;
        } else {
            //小于0抛出参数异常
            throw new IllegalArgumentException("Illegal Capacity: "+
                                               initialCapacity);
        }
}
//3.参数为集合（不常用）
public ArrayList(Collection<? extends E> c) {
    	//直接调用toArray将入参转化为数组给data
        elementData = c.toArray();
        if ((size = elementData.length) != 0) {
            // c.toArray might (incorrectly) not return Object[] (see 6260652)
            if (elementData.getClass() != Object[].class)
                elementData = Arrays.copyOf(elementData, size, Object[].class);
        } else {
            // replace with empty array.
            this.elementData = EMPTY_ELEMENTDATA;
        }
}
```

### 3.常用方法

* Add()     **当调用空的构成函数创建ArrayList时，初始化List大小是在第一次添加时进行。**

```java

public boolean add(E e) {
    	//确定容量的方法 添加一个元素 所有size要加1
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        //将下标加1 赋值
        elementData[size++] = e;
        return true;
}

private void ensureCapacityInternal(int minCapacity) {
    	//计算实际需要的容量
        ensureExplicitCapacity(calculateCapacity(elementData, minCapacity));
}

//计算实际需要的容量
private static int calculateCapacity(Object[] elementData, int minCapacity) {
        //如果实际的数组为默认的空数组，则比较默认值和参数值 然后找出默认容量和参数容量中大的
        if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
            return Math.max(DEFAULT_CAPACITY, minCapacity);
        }
        return minCapacity;
}

//实际计算是否需要扩容的方法
private void ensureExplicitCapacity(int minCapacity) {
        modCount++;

        // overflow-conscious code
    	//如果新增一个元素后的长度即实际的size大于data的长度，则需要扩容
        if (minCapacity - elementData.length > 0)
            grow(minCapacity);
}

//真正扩容的方法
private void grow(int minCapacity) {
        // overflow-conscious code
    	//旧的容量等于elementdata的长度
        int oldCapacity = elementData.length;
    	//容量扩容为原来的1.5倍
        int newCapacity = oldCapacity + (oldCapacity >> 1);
    	//这句话就是适应于elementData就空数组的时候，length=0，那么oldCapacity=0，newCapacity=0，所以这个判断成立，在这里就是真正的初始化elementData的大小了，就是为10.前面的工作都是准备工作
        //或者是当批量加入时，扩容后的newCapacity容量仍然小于最小需要容量时，就直接将最小容量赋值给newCapacity
    	//比如oldCapacity为2，addAll一个3个对象的集合，这时扩容后为2*1.5 < 2+3,判断成立，newCapacity就从3变成了5.
    	if (newCapacity - minCapacity < 0)
            newCapacity = minCapacity;
    	//如果扩大后的容量大于最大的长度 将能给的最大值给newCapacity
        if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
        // minCapacity is usually close to size, so this is a win:
        elementData = Arrays.copyOf(elementData, newCapacity);
}

private static int hugeCapacity(int minCapacity) {
        if (minCapacity < 0) // overflow
            throw new OutOfMemoryError();
        return (minCapacity > MAX_ARRAY_SIZE) ?
            Integer.MAX_VALUE :
            MAX_ARRAY_SIZE;
}


```

```java
public void add(int index, E element) {
        //校验添加的下标是否合法
    	rangeCheckForAdd(index);
		//校验容量，是否需要扩容、同上
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        //这个方法就是用来在插入元素之后，要将index之后的元素都往后移一位，
        System.arraycopy(elementData, index, elementData, index + 1,
                         size - index);
        elementData[index] = element;
        size++;
}
//如果下表大于数组大小或者小于0则抛出数组越界异常
private void rangeCheckForAdd(int index) {
        if (index > size || index < 0)
            throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
}
```

* 删除方法(里头证明了数组是可以存null的)

```java
public E remove(int index) {
    	//校验添加的下标是否合法
        rangeCheck(index);

        modCount++;
    	//通过下标取出要删除的值
        E oldValue = elementData(index);
		//计算要移动的位数
        int numMoved = size - index - 1;
    
        if (numMoved > 0)
            //原数组，起始位置，目标数组，起始位置，复制的长度
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--size] = null; // clear to let GC do its work

        return oldValue;
    }
```

```java
public boolean remove(Object o) {
        if (o == null) {
            for (int index = 0; index < size; index++)
                if (elementData[index] == null) {
                    fastRemove(index);
                    return true;
                }
        } else {
            for (int index = 0; index < size; index++)
                if (o.equals(elementData[index])) {
                    fastRemove(index);
                    return true;
                }
        }
        return false;
}

private void fastRemove(int index) {
        modCount++;
        int numMoved = size - index - 1;
        if (numMoved > 0)
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--size] = null; // clear to let GC do its work
}
```

* indexOf方法

```java
public int indexOf(Object o) {
        if (o == null) {
            for (int i = 0; i < size; i++)
                if (elementData[i]==null)
                    return i;
        } else {
            for (int i = 0; i < size; i++)
                if (o.equals(elementData[i]))
                    return i;
        }
        return -1;
}
```

### 4.总结

　　1）arrayList可以**存放null。**
　　2）arrayList**本质上就是一个elementData数组，size实际是elementData实际存放对象的个数，capacity实际是elementData的length**。
　　3）arrayList区别于数组的地方在于能够**自动扩展大小**，其中关键的方法就是**gorw()**方法。
　　4）arrayList中removeAll(collection c)和clear()的区别就是removeAll可以删除**批量指定**的元素，而clear是删除集合中的**全部**元素。
　　5）arrayList由于本质是数组，所以它在**数据的查询方面会很快，而在插入删除这些方面，性能下降很多**，因为需要移动很多数据才能达到应有的效果
　　6）arrayList实现了RandomAccess，所以在遍历它的时候推荐使用for循环。

