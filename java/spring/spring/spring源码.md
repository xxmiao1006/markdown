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





spring bean 实例化方法调用流程

org.springframework.boot.SpringApplication#run(java.lang.Class<?>, java.lang.String...)->

org.springframework.boot.SpringApplication#run(java.lang.String...)->

org.springframework.boot.SpringApplication#refreshContext->

org.springframework.context.support.AbstractApplicationContext#refresh->

org.springframework.context.support.AbstractApplicationContext#finishBeanFactoryInitialization->

org.springframework.beans.factory.config.ConfigurableListableBeanFactory#preInstantiateSingletons->

org.springframework.beans.factory.support.AbstractBeanFactory#getBean(java.lang.String)->

org.springframework.beans.factory.support.AbstractBeanFactory#doGetBean->

org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#createBean()->

org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#doCreateBean->

org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#createBeanInstance->

//推断构造方法

org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#determineConstructorsFromBeanPostProcessors

