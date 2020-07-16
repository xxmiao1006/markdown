## LinkedList

jdk1.8 LinkedList源码。实际就是使用node类实现了一个双向链表（不循环）。

### 1. 变量

```java
//链表长度
transient int size = 0;
//头节点
/**
* Pointer to first node.
* Invariant: (first == null && last == null) ||
*            (first.prev == null && first.item != null)
*/
//这两段说明是指，1.如果first是null，那么last节点也应该是null。2.first.prev等于null，first.item不能等于null这两个条件至少有一个成立
transient Node<E> first;
//尾节点
/**
* Pointer to last node.
* Invariant: (first == null && last == null) ||
*            (last.next == null && last.item != null)
*/
transient Node<E> last;

//node类 构成链表的基础元素（可以看出是双向链表，不循环）
private static class Node<E> {
    	//当前节点元素
        E item;
    	//下一节点元素
        Node<E> next;
    	//上一节点元素
        Node<E> prev;

        Node(Node<E> prev, E element, Node<E> next) {
            this.item = element;
            this.next = next;
            this.prev = prev;
        }
}
```

### 2. 构造函数

```java
//无参构造函数 
public LinkedList() {
}

//少用
public LinkedList(Collection<? extends E> c) {
        this();
        addAll(c);
}

```

### 3. 常用方法

* add()

```java
//默认add方法调用linkLast在链表尾部添加一个元素
public boolean add(E e) {
        linkLast(e);
}

void linkLast(E e) {
    	//将尾部节点引用给l
        final Node<E> l = last;
    	//创建新的尾部节点，前一节点指向l，后节点指向null
        final Node<E> newNode = new Node<>(l, e, null);
    	//将last指向新的尾部节点
        last = newNode;
    	//如果尾部节点的前一引用节点为null 则说明他为头节点
        if (l == null)
            first = newNode;
        else//否则将之前的尾部节点的下一节点指向新的尾部节点
            l.next = newNode;
        size++;
        modCount++;
}
```

* remove()

```java
//分两种情况，为空和不为空，从前往后遍历，删除遍历到的第一个元素后返回，如果有重复的元素，也只会删除一个。
public boolean remove(Object o) {
        if (o == null) {
            for (Node<E> x = first; x != null; x = x.next) {
                //证明链表可以存null
                if (x.item == null) {
                    //调用unlink删除一个非空节点
                    unlink(x);
                    return true;
                }
            }
        } else {
            for (Node<E> x = first; x != null; x = x.next) {
                //比较元素是否相等是通过equals方法
                if (o.equals(x.item)) {
                    unlink(x);
                    return true;
                }
            }
        }
        return false;
}
```

* unlink(Node<E> x)  删除一个非空节点

```java
//删除方法调用的就是unlink  linkedlist的内部实现是双向链表，记得要将删除节点的前一引用和后一引用都置为空
E unlink(Node<E> x) {
        // assert x != null;
    	//当前节点
        final E element = x.item;
    	//下一节点
        final Node<E> next = x.next;
    	//上一节点
        final Node<E> prev = x.prev;
		//如果上一节点引用为空，则证明当前节点为头节点
        if (prev == null) {
            //直接将头节点指向当前节点的下一节点
            first = next;
        } else {
            //如果上一节点不为空，将上一节点的下一节点指向当前节点的下一节点
            prev.next = next;
            //并且把当前节点的前一引用置为空
            x.prev = null;
        }
		
    	//如果下一节点的引用为空，则证明当前节点为尾节点
        if (next == null) {
            //直接将尾节点指向当前节点的上一节点
            last = prev;
        } else {
            //如果下一节点不为空，将下一节点的前一节点指向当前节点的上一节点
            next.prev = prev;
            //并且把当前节点的下一节点置为空 
            x.next = null;
        }

        x.item = null;
        size--;
        modCount++;
        return element;
}
```

* indexOf(Objec o)

```java
//和删除类似
public int indexOf(Object o) {
        int index = 0;
        if (o == null) {
            for (Node<E> x = first; x != null; x = x.next) {
                if (x.item == null)
                    return index;
                index++;
            }
        } else {
            for (Node<E> x = first; x != null; x = x.next) {
                if (o.equals(x.item))
                    return index;
                index++;
            }
        }
        return -1;
}
```

* node(index) 根据索引返回一个节点

```java
Node<E> node(int index) {
        // assert isElementIndex(index);
		//这里让索引和size/2比较，大于则从后往前遍历找，如果小于则从前往后遍历找，小优化吧
        if (index < (size >> 1)) {
            Node<E> x = first;
            for (int i = 0; i < index; i++)
                x = x.next;
            return x;
        } else {
            Node<E> x = last;
            for (int i = size - 1; i > index; i--)
                x = x.prev;
            return x;
        }
}
```

