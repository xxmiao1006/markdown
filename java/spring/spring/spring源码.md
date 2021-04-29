## spring 源码





上图就是spring容器初始化bean的大概过程(至于详细的过程，后面文章再来介绍)；
文字总结一下：
1：实例化一个ApplicationContext的对象；
2：调用bean工厂后置处理器完成扫描；
3：循环解析扫描出来的类信息；
4：实例化一个BeanDefinition对象来存储解析出来的信息；
5：把实例化好的beanDefinition对象put到beanDefinitionMap当中缓存起来，以便后面实例化bean；
6：再次调用bean工厂后置处理器；
7：当然spring还会干很多事情，比如国际化，比如注册BeanPostProcessor等等，如果我们只关心如何实例化一个bean的话那么这一步就是spring调用finishBeanFactoryInitialization方法来实例化单例的bean，实例化之前spring要做验证，需要遍历所有扫描出来的类，依次判断这个bean是否Lazy，是否prototype，是否abstract等等；
8：如果验证完成spring在实例化一个bean之前需要推断构造方法，因为spring实例化对象是通过构造方法反射，故而需要知道用哪个构造方法；
9：推断完构造方法之后spring调用构造方法反射实例化一个对象；注意我这里说的是对象、对象、对象；这个时候对象已经实例化出来了，但是并不是一个完整的bean，最简单的体现是这个时候实例化出来的对象属性是没有注入，所以不是一个完整的bean；
10：spring处理合并后的beanDefinition(合并？是spring当中非常重要的一块内容，后面的文章我会分析)；
11：判断是否支持循环依赖，如果支持则提前把一个工厂存入singletonFactories——map；
12：判断是否需要完成属性注入
13：如果需要完成属性注入，则开始注入属性
14：判断bean的类型回调Aware接口
15：调用生命周期回调方法
16：如果需要代理则完成代理
17：put到单例池——bean完成——存在spring容器当中

```java
public interface ApplicationContext
extends 
EnvironmentCapable,  // 继承环境对象容器接口
ListableBeanFactory,  
HierarchicalBeanFactory, // 继承beanFactory
MessageSource,  // 集成消息解析器
ApplicationEventPublisher, // 继承应用事件发布器
ResourcePatternResolver // 继承模式资源解析器
{}
```

org.springframework.context.support.AbstractApplicationContext#refresh方法

AbstractApplicationContext#finishBeanFactoryInitialization方法中完成了bean的实例化

```java
@Override
public void refresh() throws BeansException, IllegalStateException {
    synchronized (this.startupShutdownMonitor) {
        // Prepare this context for refreshing.
        prepareRefresh();

        // Tell the subclass to refresh the internal bean factory.
        ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

        // Prepare the bean factory for use in this context.
        // 准备beanfactory来使用这个上下文
        //（1）对SPEL语言的支持
        //（2）增加对属性编辑器的支持
        //（3）增加对一些内置类的支持，如EnvironmentAware、MessageSourceAware的注入
        //（4）设置了依赖功能可忽略的接口
        //（5）注册一些固定依赖的属性
        //（6）增加了AspectJ的支持
        //（7）将相关环境变量及属性以单例模式注册 
        prepareBeanFactory(beanFactory);

        try {
            // Allows post-processing of the bean factory in context subclasses.
            //允许上下文中的子类去执行PostProcessor
            postProcessBeanFactory(beanFactory);

            // Invoke factory processors registered as beans in the context.
            //开始执行注册到该上下文的BeanFactoryPostProcessors
            //对应完成上面2，3，4，5
            invokeBeanFactoryPostProcessors(beanFactory);

            // Register bean processors that intercept bean creation.
            registerBeanPostProcessors(beanFactory);

            // Initialize message source for this context.
            //初始化消息源
            initMessageSource();

            // Initialize event multicaster for this context.
            //注册上下文事件的广播集
            initApplicationEventMulticaster();

            // Initialize other special beans in specific context subclasses.
            //初始化一些特殊的Bean
            onRefresh();

            // Check for listener beans and register them.
            //查询并校验监听器并校验
            //注册系统里的监听者（观察者）
            registerListeners();

            // Instantiate all remaining (non-lazy-init) singletons.
            //实例化所有非懒加载的所有Bean
            //对应上面的7，8，9等
            finishBeanFactoryInitialization(beanFactory);

            // Last step: publish corresponding event.
            //最后一步：发布相应事件
            finishRefresh();
        }

        catch (BeansException ex) {
            logger.warn("Exception encountered during context initialization - cancelling refresh attempt", ex);

            // Destroy already created singletons to avoid dangling resources.
            destroyBeans();

            // Reset 'active' flag.
            cancelRefresh(ex);

            // Propagate exception to caller.
            throw ex;
        }

        finally {
            // Reset common introspection caches in Spring's core, since we
            // might not ever need metadata for singleton beans anymore...
            resetCommonCaches();
        }
    }
}
```





**spring 启动时容器里面bean 实例化方法调用流程**

org.springframework.boot.SpringApplication#run(java.lang.Class<?>, java.lang.String...)->

org.springframework.boot.SpringApplication#run(java.lang.String...)->

org.springframework.boot.SpringApplication#refreshContext->

org.springframework.context.support.**AbstractApplicationContext**#**refresh**->

org.springframework.context.support.**AbstractApplicationContext**#**finishBeanFactoryInitialization**->

org.springframework.beans.factory.config.**ConfigurableListableBeanFactory**#**preInstantiateSingletons**->

org.springframework.beans.factory.support.**AbstractBeanFactory**#**getBean**(java.lang.String)->

org.springframework.beans.factory.support.**AbstractBeanFactory**#**doGetBean**->

org.springframework.beans.factory.support.**AbstractAutowireCapableBeanFactory**#**createBean**()->

org.springframework.beans.factory.support.**AbstractAutowireCapableBeanFactory**#**doCreateBean**->

org.springframework.beans.factory.support.**AbstractAutowireCapableBeanFactory**#**createBeanInstance**->

//推断构造方法

org.springframework.beans.factory.support.**AbstractAutowireCapableBeanFactory**#**determineConstructorsFromBeanPostProcessors**



**spring 解析xml生成BeanDefinition**

org.springframework.context.support.ClassPathXmlApplicationContext#ClassPathXmlApplicationContext(java.lang.String[], boolean, org.springframework.context.ApplicationContext) ->

org.springframework.context.support.**AbstractApplicationContext**#**refresh** ->

org.springframework.context.support.**AbstractApplicationContext**#**obtainFreshBeanFactory**->

org.springframework.context.support.**AbstractRefreshableApplicationContext**#**refreshBeanFactory**->

org.springframework.context.support.**AbstractXmlApplicationContext**#**loadBeanDefinitions**(org.springframework.beans.factory.support.DefaultListableBeanFactory)->

org.springframework.context.support.**AbstractXmlApplicationContext**#**loadBeanDefinitions**(org.springframework.beans.factory.xml.XmlBeanDefinitionReader)->

org.springframework.beans.factory.support.AbstractBeanDefinitionReader#loadBeanDefinitions(org.springframework.core.io.Resource...)->

org.springframework.beans.factory.xml.XmlBeanDefinitionReader#loadBeanDefinitions(org.springframework.core.io.Resource)->

org.springframework.beans.factory.xml.**XmlBeanDefinitionReader**#**loadBeanDefinitions**(org.springframework.core.io.support.EncodedResource)->

org.springframework.beans.factory.xml.**XmlBeanDefinitionReader**#**doLoadBeanDefinitions**->

org.springframework.beans.factory.xml.**XmlBeanDefinitionReader**#**registerBeanDefinitions**->

org.springframework.beans.factory.xml.**DefaultBeanDefinitionDocumentReader**#**doRegisterBeanDefinitions**->

org.springframework.beans.factory.xml.**DefaultBeanDefinitionDocumentReader**#**parseBeanDefinitions**->

org.springframework.beans.factory.xml.**DefaultBeanDefinitionDocumentReader**#**parseDefaultElement**->标签解析

org.springframework.beans.factory.xml.**DefaultBeanDefinitionDocumentReader**#**processBeanDefinition**->

1.org.springframework.beans.factory.xml.**BeanDefinitionParserDelegate**#**parseBeanDefinitionElement**(org.w3c.dom.Element)->解析标签，这里会返回一个BeanDefinitionHolder.

2.org.springframework.beans.factory.support.**BeanDefinitionReaderUtils**#**registerBeanDefinition**->注册到beanDefinitionMap->

org.springframework.beans.factory.support.**DefaultListableBeanFactory**#**registerBeanDefinition**->这里将beanDifiniton put到了beanDefinitionMap。





AbstractApplicationContext类，spring又提供了两个分支的子类型

一方面，在前者的基础上，重新提供了`AbstractRefreshableApplicationContext`子类型。此类型继承`AbstractApplicationContext`，为`refreshBeanFactory`方法提供了一个逻辑实现——如果已有beanFactory刷新过了，则先关闭它，然后重建一个，并且为它加载bean定义。它提供了一个`loadBeanDefinitions`方法给子类实现。至于子类从哪加载，如何加载，并不过问。

`AbstractRefreshableApplicationContext`类的这条线上。`loadBeanDefinitions`方法没有提到如何加载bean定义，`AbstractRefreshableConfigApplicationContext`补上了这个缺陷，它认为所有的bean定义应该从configLocations处加载。但是，美中不足的是，这个类仍然没有说明configLocations应该是什么，从代码来看，它仅仅只是个字符串数组。

每个location可以解释为一个xml的位置，于是`AbstractXmlApplicationContext`应运而生。它将location解释为xml，并将xml的内容加载为beanDefinition注册到beanFactory中。此外，它提供了额外的Resource数组（内容必须是xml），使已经构建好的Resource对象不必再拆封装一次。然而，虽然这个类依然被声明为abstract，但它并没有提供更多的抽象方法。

org.springframework.context.support.AbstractXmlApplicationContext#loadBeanDefinitions(org.springframework.beans.factory.support.DefaultListableBeanFactory)

```java
@Override
protected void loadBeanDefinitions(DefaultListableBeanFactory beanFactory) throws BeansException, IOException {
    // Create a new XmlBeanDefinitionReader for the given BeanFactory.
    XmlBeanDefinitionReader beanDefinitionReader = new XmlBeanDefinitionReader(beanFactory);

    // Configure the bean definition reader with this context's
    // resource loading environment.
    beanDefinitionReader.setEnvironment(this.getEnvironment());
    beanDefinitionReader.setResourceLoader(this);
    beanDefinitionReader.setEntityResolver(new ResourceEntityResolver(this));

    // Allow a subclass to provide custom initialization of the reader,
    // then proceed with actually loading the bean definitions.
    initBeanDefinitionReader(beanDefinitionReader);
    loadBeanDefinitions(beanDefinitionReader);
}
```

如上，在AbstractXmlApplicationContext里面创建了XmlBeanDefinitionReader实际去读取和解析XML文件。

另一方面`GenericApplicationContext`则是直接实现了`AbstractApplicationContext`。这也是我们目前看到的第一个非抽象类。它的刷新方法`refreshBeanFactory`非常简单, 只是判断是否刷新过，如果刷新过就抛异常。在加载bean定义这件事上，它并不交给子类去做，而是自己实现了一个`BeanDefinitionRegistry`，也就是说将bean定义从哪里来的事情交给了外部类来考虑。















1.BeanFactory与ApplicationContext的比较

ApplicationContext是BeanFactory的子接口，都可以代表spring 容器，spring容器是生成Bean实例的工厂，并且管理容器中的bean,ApplicationContext再spring中称为上下文，它作为BeanFactory的子接口，不仅拥有BeanFactory接口的能力，还再它的基础上，通过其他接口扩展了其他的能力，提供了更多面向应用的功能，比如国际化支持、框架事件体系

比如：

ApplicationEventPublisher:让容器拥有发布应用上下文事件的功能，包括容器的启动事件、关闭事件等。
MessageSource：为应用提供i18N国际化消息访问的功能
ResourcePatternResolver：加载资源，可以通过带前缀的Ant风格的资源文件路径装载Spring的配置文件
LifeCycle：该接口提供start()和stop()方法，主要用于控制异步处理的过程，以达到管理和控制JMX、任务调度等目的

ApplicationContext由BeanFactory派生而来，提供了更多面向实际的功能。

在BeanFactory中，很多功能都需要以编程的形式实现，但是在Application中则可以通过配置的方式实现。



2.BeanFactory与FactoryBean的比较

BeanFactory以Factory结尾，表示它是一个工厂类(接口)， **它负责生产和管理bean的一个工厂**。在Spring中，**BeanFactory是IOC容器的核心接口，它的职责包括：实例化、定位、配置应用程序中的对象及建立这些对象间的依赖**。

FactoryBean**一般情况下，Spring通过反射机制利用<bean>的class属性指定实现类实例化Bean，在某些情况下，实例化Bean过程比较复杂，如果按照传统的方式，则需要在<bean>中提供大量的配置信息。配置方式的灵活性是受限的，这时采用编码的方式可能会得到一个简单的方案。Spring为此提供了一个org.springframework.bean.factory.FactoryBean的工厂类接口，用户可以通过实现该接口定制实例化Bean的逻辑。**FactoryBean以Bean结尾，表示它是一个Bean，不同于普通Bean的是：**它是实现了FactoryBean<T>接口的Bean，根据该Bean的ID从BeanFactory中获取的实际上是FactoryBean的getObject()返回的对象，而不是FactoryBean本身，如果要获取FactoryBean对象，请在id前面加一个&符号来获取**



3.spring 单例模式的循环依赖

org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory里面解决，创建单例bean的时候实际会记录创建状态(isSingletonCurrentlyInCreation)。

```java
/*
*大概流程如下：
*createBeanInstance() 实例化 bean
*populateBean() 属性填充
*循环依赖的处理
*initializeBean() 初始化 bean
*/
protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final @Nullable Object[] args)
    throws BeanCreationException {

    // BeanWrapper是对Bean的包装，其接口中所定义的功能很简单包括设置获取被包装的对象，获取被包装bean的属性描述器
    BeanWrapper instanceWrapper = null;
    // 单例模型，则从未完成的 FactoryBean 缓存中删除
    if (mbd.isSingleton()) {anceWrapper = this.factoryBeanInstanceCache.remove(beanName);
                           }

    // 使用合适的实例化策略来创建新的实例：工厂方法、构造函数自动注入、简单初始化
    if (instanceWrapper == null) {
        instanceWrapper = createBeanInstance(beanName, mbd, args);
    }

    // 包装的实例对象
    final Object bean = instanceWrapper.getWrappedInstance();
    // 包装的实例对象的类型
    Class<?> beanType = instanceWrapper.getWrappedClass();
    if (beanType != NullBean.class) {
        mbd.resolvedTargetType = beanType;
    }

    // 检测是否有后置处理
    // 如果有后置处理，则允许后置处理修改 BeanDefinition
    synchronized (mbd.postProcessingLock) {
        if (!mbd.postProcessed) {
            try {
                // applyMergedBeanDefinitionPostProcessors
                // 后置处理修改 BeanDefinition
                applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
            }
            catch (Throwable ex) {
                throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                                                "Post-processing of merged bean definition failed", ex);
            }
            mbd.postProcessed = true;
        }
    }

    // 解决单例模式的循环依赖
    // 单例模式 & 允许循环依赖&当前单例 bean 是否正在被创建
    boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
                                      isSingletonCurrentlyInCreation(beanName));
    if (earlySingletonExposure) {
        if (logger.isDebugEnabled()) {
            logger.debug("Eagerly caching bean '" + beanName +
                         "' to allow for resolving potential circular references");
        }
        // 提前将创建的 bean 实例加入到ObjectFactory 中
        // 这里是为了后期避免循环依赖
        addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
    }

    /*
     * 开始初始化 bean 实例对象
     */
    Object exposedObject = bean;
    try {
        // 对 bean 进行填充，将各个属性值注入，其中，可能存在依赖于其他 bean 的属性
        // 则会递归初始依赖 bean
        populateBean(beanName, mbd, instanceWrapper);
        // 调用初始化方法，比如 init-method 
        exposedObject = initializeBean(beanName, exposedObject, mbd);
    }
    catch (Throwable ex) {
        if (ex instanceof BeanCreationException && beanName.equals(((BeanCreationException) ex).getBeanName())) {
            throw (BeanCreationException) ex;
        }
        else {
            throw new BeanCreationException(
                mbd.getResourceDescription(), beanName, "Initialization of bean failed", ex);
        }
    }

    /**
     * 循环依赖处理
     */
    if (earlySingletonExposure) {
        // 获取 earlySingletonReference
        Object earlySingletonReference = getSingleton(beanName, false);
        // 只有在存在循环依赖的情况下，earlySingletonReference 才不会为空
        if (earlySingletonReference != null) {
            // 如果 exposedObject 没有在初始化方法中被改变，也就是没有被增强
            if (exposedObject == bean) {
                exposedObject = earlySingletonReference;
            }
            // 处理依赖
            else if (!this.allowRawInjectionDespiteWrapping && hasDependentBean(beanName)) {
                String[] dependentBeans = getDependentBeans(beanName);
                Set<String> actualDependentBeans = new LinkedHashSet<>(dependentBeans.length);
                for (String dependentBean : dependentBeans) {
                    if (!removeSingletonIfCreatedForTypeCheckOnly(dependentBean)) {
                        actualDependentBeans.add(dependentBean);
                    }
                }
                if (!actualDependentBeans.isEmpty()) {
                    throw new BeanCurrentlyInCreationException(beanName,
                                                               "Bean with name '" + beanName + "' has been injected into other beans [" +
                                                               StringUtils.collectionToCommaDelimitedString(actualDependentBeans) +
                                                               "] in its raw version as part of a circular reference, but has eventually been " +
                                                               "wrapped. This means that said other beans do not use the final version of the " +
                                                               "bean. This is often the result of over-eager type matching - consider using " +
                                                               "'getBeanNamesOfType' with the 'allowEagerInit' flag turned off, for example.");
                }
            }
        }
    }
    try {
        // 注册 bean
        registerDisposableBeanIfNecessary(beanName, bean, mbd);
    }
    catch (BeanDefinitionValidationException ex) {
        throw new BeanCreationException(
            mbd.getResourceDescription(), beanName, "Invalid destruction signature", ex);
    }

    return exposedObject;
}
```



[Spring 是如何解决循环依赖的？](https://www.zhihu.com/question/438247718/answer/1730527725)

[java_lyvee的专栏](https://blog.csdn.net/java_lyvee)

[spring5 源码深度解析-----Spring的整体架构和环境搭建](https://www.cnblogs.com/java-chen-hao/p/11046190.html)

[spring5 源码深度解析-----ApplicationContext容器refresh过程](https://www.cnblogs.com/java-chen-hao/p/11579591.html)

[spring5 源码深度解析----- IOC 之 容器的基本实现](https://www.cnblogs.com/java-chen-hao/p/11113340.html)

[spring5 源码深度解析----- IOC 之 开启 bean 的加载(解决循环依赖)](https://www.cnblogs.com/java-chen-hao/p/11137571.html)





