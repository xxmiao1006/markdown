## jvm类加载机制

​		JVM 类加载机制分为五个部分：加载，验证，准备，解析，初始化。



* 加载

  加载是类加载过程中的一个阶段，**这个阶段会在内存中生成一个代表这个类的 java.lang.Class 对**
  **象，作为方法区这个类的各种数据的入口**。注意这里不一定非得要从一个 Class 文件获取，这里既
  可以从 ZIP 包中读取（比如从 jar 包和 war 包中读取），也可以在运行时计算生成（动态代  理），
  也可以由其它文件生成（比如将 JSP 文件转换成对应的 Class 类）

* 验证

  这一阶段的主要目的是为了**确保 Class 文件的字节流中包含的信息是否符合当前虚拟机的要求**，并且不会危害虚拟机自身的安全。

* 准备

  准备阶段是正式为类变量分配内存并设置类变量的初始值阶段，即在**方法区中分配这些变量所使**
  **用的内存空间**

* 解析

  解析阶段是指**虚拟机将常量池中的符号引用替换为直接引用的过程**





```java
/*Map<String, String> apiModelProperMap = new HashMap();
        Class<? extends Category> categoryClass = Category.class;
        //拿到该类的所有字段
        Field[] fields = categoryClass.getDeclaredFields();
        for (int i = 0; i < fields.length; i++) {
            //Field field=clazz.getDeclaredField(fields[i].getName());
            boolean annotationPresent = fields[i].isAnnotationPresent(ApiModelProperty.class);
            if (annotationPresent) {
                // 获取注解值
                String name = fields[i].getAnnotation(ApiModelProperty.class).value();
                apiModelProperMap.put(fields[i].getName(), name);
            }

        }
        String s = apiModelProperMap.get("");*/
```

