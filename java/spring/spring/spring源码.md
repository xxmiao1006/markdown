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

* 首先是一个synchronized加锁，当然要加锁，不然你先调一次refresh()然后这次还没处理完又调一次，就会乱套了；
* 接着往下看prepareRefresh();这个方法是做准备工作的，记录容器的启动时间、标记“已启动”状态、处理配置文件中的占位符，可以点进去看看，这里就不多说了。
* 下一步ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();这个就很重要了，这一步是把配置文件解析成一个个Bean，并且注册到BeanFactory中，注意这里只是注册进去，并没有初始化。先继续往下看，等会展开这个方法详细解读
* 然后是prepareBeanFactory(beanFactory);这个方法的作用是：设置 BeanFactory 的类加载器，添加几个 BeanPostProcessor，手动注册几个特殊的 bean，这里都是spring里面的特殊处理，然后继续往下看
* postProcessBeanFactory(beanFactory);方法是提供给子类的扩展点，到这里的时候，所有的 Bean 都加载、注册完成了，但是都还没有初始化，具体的子类可以在这步的时候添加一些特殊的 BeanFactoryPostProcessor 的实现类，来完成一些其他的操作。
* 接下来是invokeBeanFactoryPostProcessors(beanFactory);这个方法是调用 BeanFactoryPostProcessor 各个实现类的 postProcessBeanFactory(factory) 方法；
* 然后是registerBeanPostProcessors(beanFactory);这个方法注册 BeanPostProcessor 的实现类，和上面的BeanFactoryPostProcessor 是有区别的，这个方法调用的其实是PostProcessorRegistrationDelegate类的registerBeanPostProcessors方法；这个类里面有个内部类BeanPostProcessorChecker，BeanPostProcessorChecker里面有两个方法postProcessBeforeInitialization和postProcessAfterInitialization，这两个方法分别在 Bean 初始化之前和初始化之后得到执行。然后回到refresh()方法中继续往下看
* initMessageSource();方法是初始化当前 ApplicationContext 的 MessageSource，国际化处理，继续往下
* initApplicationEventMulticaster();方法初始化当前 ApplicationContext 的事件广播器继续往下
* onRefresh();方法初始化一些特殊的 Bean（在初始化 singleton beans 之前）；继续往下
* registerListeners();方法注册事件监听器，监听器需要实现 ApplicationListener 接口；继续往下
* 重点到了：finishBeanFactoryInitialization(beanFactory);初始化所有的 singleton beans（单例bean），懒加载（non-lazy-init）的除外，这个方法也是等会细说
* finishRefresh();方法是最后一步，广播事件，ApplicationContext 初始化完成
  





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





1.谈谈 Spring Bean 的生命周期和作用域？

Spring Bean 生命周期比较复杂，可以分为创建和销毁两个过程。首先，创建 Bean 会经过一系列的步骤，主要包括：

* 实例化 Bean 对象。

* 设置 Bean 属性。
* 如果我们通过各种 Aware 接口声明了依赖关系，则会注入 Bean 对容器基础设施层面的依赖。具体包括 BeanNameAware、BeanFactoryAware 和 ApplicationContextAware，分别会注入 Bean ID、Bean Factory 或者 ApplicationContext。

* 调用 BeanPostProcessor 的前置初始化方法 postProcessBeforeInitialization。

* 如果实现了 InitializingBean 接口，则会调用 afterPropertiesSet 方法。

* 调用 Bean 自身定义的 init 方法。

* 调用 BeanPostProcessor 的后置初始化方法 postProcessAfterInitialization。

* 创建过程完毕。

![bean生命周期.png](http://ww1.sinaimg.cn/large/0072fULUgy1gr1d5sjramj60h50gf3yo02.jpg)

Spring Bean 的销毁过程会依次调用 DisposableBean 的 destroy 方法和 Bean 自身定制的 destroy 方法。







2.Spring 是如何甄别单例情况下的构造方法循环依赖的

​	Spring 通过 `Set<String> singletonsCurrentlyInCreation` 记录当前正在创建中的实例名称

创建实例对象之前，会判断 `singletonsCurrentlyInCreation` 中是否存在该实例的名称，如果存在则表示死循环了，那么抛出 `BeanCurrentlyInCreationException`



3.Spring 是如何甄别原型循环依赖的

​	Spring 通过 `ThreadLocal<Object> prototypesCurrentlyInCreation` 记录当前线程正在创建中的原型实例名称

创建原型实例之前，会判断 `prototypesCurrentlyInCreation` 中是否存在该实例的名称，如果存在则表示死循环了，那么抛出 `BeanCurrentlyInCreationException`



4.为什么单例构造方法循环依赖和原型循环依赖的报错时机不一致

​	单例构造方法实例的创建是在 Spring 启动过程中完成的，而原型实例是在获取的时候创建的

[Spring 是如何判定原型循环依赖和构造方法循环依赖的？](https://mp.weixin.qq.com/s?__biz=MzI4Njc5NjM1NQ==&mid=2247508518&idx=1&sn=0807103f612130bad5523dc80c5ce31d&chksm=ebd59d0adca2141c78f5424fa2440d91d3cc4174ce6416e0f9b4807b82da02f7a914c51af580&scene=126&sessionid=1623981014&key=ad5be9c1f718c28a0eee1b7db78e63b8b841b3df0d447d28e5e0b3eef5d850baf37569644867fe537d89a50358a18db7ea1a9132a05a95e0ea96a44030f6e680380246a80b4f22be5187b06f2ddd4c800ab4cdc9503eff006b9d366f47a2cff60b8fd3d9527d6b2f7988f4f0e3fe6d43c15bb957a0560d86418376238533d378&ascene=1&uin=MTgxNTEwNTUxMw%3D%3D&devicetype=Windows+10+x64&version=62090529&lang=zh_CN&exportkey=Aa6eVGeSuvB0ik2PgdTl%2FRc%3D&pass_ticket=8tRCVknbPuwaL8KpNWmGngJa0aRSfFMIoFVfNttCR86zgUvht7qFGVGIC0exrX8J&wx_header=0)



5.spring如何解决循环依赖

![spring解决循环依赖.png](http://ww1.sinaimg.cn/large/0072fULUgy1grt5zwt1lyj60j70aq46i02.jpg)



6.Spring 的循环依赖：真的必须非要三级缓存吗？

三级缓存各自的作用

* 第一级缓存存的是对外暴露的对象，也就是我们应用需要用到的

* 第二级缓存的作用是为了处理循环依赖的对象创建问题，里面存的是半成品对象或半成品对象的代理对象

* 第三级缓存的作用处理存在 AOP + 循环依赖的对象创建问题，能将代理对象提前创建

  

Spring 为什么要引入第三级缓存

严格来讲，第三级缓存并非缺它不可，因为可以提前创建代理对象

提前创建代理对象只是会节省那么一丢丢内存空间，并不会带来性能上的提升，但是会破环 Spring 的设计原则

Spring 的设计原则是尽可能保证普通对象创建完成之后，再生成其 AOP 代理（尽可能延迟代理对象的生成）

所以 Spring 用了第三级缓存，既维持了设计原则，又处理了循环依赖；牺牲那么一丢丢内存空间是愿意接受的



[Spring 的循环依赖：真的必须非要三级缓存吗？](https://mp.weixin.qq.com/s?__biz=MzI4Njc5NjM1NQ==&mid=2247503628&idx=1&sn=f1f3fec91ec5490b28f24d74b225c399&chksm=ebd5f020dca27936c46c13ace0f9cfb150fc7671b679ed0b38cf4f2f237b6a54c5eb327da94a&scene=21#wechat_redirect)







































[Spring 是如何解决循环依赖的？](https://www.zhihu.com/question/438247718/answer/1730527725)

[java_lyvee的专栏](https://blog.csdn.net/java_lyvee)

[spring5 源码深度解析-----Spring的整体架构和环境搭建](https://www.cnblogs.com/java-chen-hao/p/11046190.html)

[spring5 源码深度解析-----ApplicationContext容器refresh过程](https://www.cnblogs.com/java-chen-hao/p/11579591.html)

[spring5 源码深度解析----- IOC 之 容器的基本实现](https://www.cnblogs.com/java-chen-hao/p/11113340.html)

[spring5 源码深度解析----- IOC 之 开启 bean 的加载(解决循环依赖)](https://www.cnblogs.com/java-chen-hao/p/11137571.html)





