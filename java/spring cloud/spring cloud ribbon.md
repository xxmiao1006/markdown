## spring cloud ribbon

在configuration类中，注入restTemplate时使用@LoadBalanced ,这个注解是用来给RestTemplate做标记，以使用LoadBalancerClient来配置它

```java
@Configuration
public class RibbonConfig {

    @Bean
    @LoadBalanced
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

}
```



具体的配置在LoadBalancerClient的包下面发现了一个类叫做LoadBalancerAutoConfiguration。

这个类简单来说就是给每一个restTemplate加了一个LoadBalancerInterceptor拦截器，让一个普通的restTemplate成为一个具有负载均衡功能的请求器

```java
/*
 * Copyright 2012-2019 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.springframework.cloud.client.loadbalancer;

import java.io.IOException;
import java.net.URI;

import org.springframework.http.HttpRequest;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.util.Assert;

/**
 * @author Spencer Gibb
 * @author Dave Syer
 * @author Ryan Baxter
 * @author William Tran
 */
public class LoadBalancerInterceptor implements ClientHttpRequestInterceptor {

	private LoadBalancerClient loadBalancer;

	private LoadBalancerRequestFactory requestFactory;

	public LoadBalancerInterceptor(LoadBalancerClient loadBalancer,
			LoadBalancerRequestFactory requestFactory) {
		this.loadBalancer = loadBalancer;
		this.requestFactory = requestFactory;
	}

	public LoadBalancerInterceptor(LoadBalancerClient loadBalancer) {
		// for backwards compatibility
		this(loadBalancer, new LoadBalancerRequestFactory(loadBalancer));
	}

	@Override
	public ClientHttpResponse intercept(final HttpRequest request, final byte[] body,
			final ClientHttpRequestExecution execution) throws IOException {
		final URI originalUri = request.getURI();
		String serviceName = originalUri.getHost();
		Assert.state(serviceName != null,
				"Request URI does not contain a valid hostname: " + originalUri);
		return this.loadBalancer.execute(serviceName,
				this.requestFactory.createRequest(request, body, execution));
	}

}

```

拦截器里面注入了LoadBalancerClient的实现类 RibbonLoadBalancerClient，调用execute方法

```java
@Override
	public <T> T execute(String serviceId, LoadBalancerRequest<T> request)
			throws IOException {
		return execute(serviceId, request, null);
	}

	/**
	 * New: Execute a request by selecting server using a 'key'. The hint will have to be
	 * the last parameter to not mess with the `execute(serviceId, ServiceInstance,
	 * request)` method. This somewhat breaks the fluent coding style when using a lambda
	 * to define the LoadBalancerRequest.
	 * @param <T> returned request execution result type
	 * @param serviceId id of the service to execute the request to
	 * @param request to be executed
	 * @param hint used to choose appropriate {@link Server} instance
	 * @return request execution result
	 * @throws IOException executing the request may result in an {@link IOException}
	 */
	public <T> T execute(String serviceId, LoadBalancerRequest<T> request, Object hint)
			throws IOException {
		ILoadBalancer loadBalancer = getLoadBalancer(serviceId);
		Server server = getServer(loadBalancer, hint);
		if (server == null) {
			throw new IllegalStateException("No instances available for " + serviceId);
		}
		RibbonServer ribbonServer = new RibbonServer(serviceId, server,
				isSecure(server, serviceId),
				serverIntrospector(serviceId).getMetadata(server));

		return execute(serviceId, ribbonServer, request);
	}

	@Override
	public <T> T execute(String serviceId, ServiceInstance serviceInstance,
			LoadBalancerRequest<T> request) throws IOException {
		Server server = null;
		if (serviceInstance instanceof RibbonServer) {
			server = ((RibbonServer) serviceInstance).getServer();
		}
		if (server == null) {
			throw new IllegalStateException("No instances available for " + serviceId);
		}

		RibbonLoadBalancerContext context = this.clientFactory
				.getLoadBalancerContext(serviceId);
		RibbonStatsRecorder statsRecorder = new RibbonStatsRecorder(context, server);

		try {
			T returnVal = request.apply(serviceInstance);
			statsRecorder.recordStats(returnVal);
			return returnVal;
		}
		// catch IOException and rethrow so RestTemplate behaves correctly
		catch (IOException ex) {
			statsRecorder.recordStats(ex);
			throw ex;
		}
		catch (Exception ex) {
			statsRecorder.recordStats(ex);
			ReflectionUtils.rethrowRuntimeException(ex);
		}
		return null;
	}
```

在execute方法中，首先根据serviceId获取一个ILoadBalancer，然后调用getServer方法去获取一个服务实例，但是在getServer方法中，我们看到并没有调用LoadBalancerClient中的choose方法，而是调用了另一个叫做ILoadBalancer的中定义的chooseServer方法

```java
/*
*
* Copyright 2013 Netflix, Inc.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
*/
package com.netflix.loadbalancer;

import java.util.List;

/**
 * Interface that defines the operations for a software loadbalancer. A typical
 * loadbalancer minimally need a set of servers to loadbalance for, a method to
 * mark a particular server to be out of rotation and a call that will choose a
 * server from the existing list of server.
 * 
 * @author stonse
 * 
 */
public interface ILoadBalancer {

	/**
	 * Initial list of servers.
	 * This API also serves to add additional ones at a later time
	 * The same logical server (host:port) could essentially be added multiple times
	 * (helpful in cases where you want to give more "weightage" perhaps ..)
	 * 
	 * @param newServers new servers to add
	 */
	public void addServers(List<Server> newServers);
	
	/**
	 * Choose a server from load balancer.
	 * 
	 * @param key An object that the load balancer may use to determine which server to return. null if 
	 *         the load balancer does not use this parameter.
	 * @return server chosen
	 */
	public Server chooseServer(Object key);
	
	/**
	 * To be called by the clients of the load balancer to notify that a Server is down
	 * else, the LB will think its still Alive until the next Ping cycle - potentially
	 * (assuming that the LB Impl does a ping)
	 * 
	 * @param server Server to mark as down
	 */
	public void markServerDown(Server server);
	
	/**
	 * @deprecated 2016-01-20 This method is deprecated in favor of the
	 * cleaner {@link #getReachableServers} (equivalent to availableOnly=true)
	 * and {@link #getAllServers} API (equivalent to availableOnly=false).
	 *
	 * Get the current list of servers.
	 *
	 * @param availableOnly if true, only live and available servers should be returned
	 */
	@Deprecated
	public List<Server> getServerList(boolean availableOnly);

	/**
	 * @return Only the servers that are up and reachable.
     */
    public List<Server> getReachableServers();

    /**
     * @return All known servers, both reachable and unreachable.
     */
	public List<Server> getAllServers();
}

```

1. addServers表示向负载均衡器中维护的实例列表增加服务实例
2. chooseServer表示通过某种策略，从负载均衡服务器中挑选出一个具体的服务实例
3. markServerDown表示用来通知和标识负载均衡器中某个具体实例已经停止服务，否则负载均衡器在下一次获取服务实例清单前都会认为这个服务实例是正常工作的
4. getReachableServers表示获取当前正常工作的服务实例列表
5. getAllServers表示获取所有的服务实例列表，包括正常的服务和停止工作的服务

这个是一个接口，那么在和Ribbon整合的时候，Spring Cloud默认采用了哪个具体的实现呢?我们可以从RibbonClientConfiguration类中一窥究竟。

```java
	@Bean
	@ConditionalOnMissingBean
	public ILoadBalancer ribbonLoadBalancer(IClientConfig config,
			ServerList<Server> serverList, ServerListFilter<Server> serverListFilter,
			IRule rule, IPing ping, ServerListUpdater serverListUpdater) {
		if (this.propertiesFactory.isSet(ILoadBalancer.class, name)) {
			return this.propertiesFactory.get(ILoadBalancer.class, config, name);
		}
		return new ZoneAwareLoadBalancer<>(config, rule, ping, serverList,
				serverListFilter, serverListUpdater);
	}
```

可以看到，默认使用的是ZoneAwareLoadBalancer

此时我们需要重新回到RibbonLoadBalancerClient类中继续看我们的execute方法的执行情况，在execute方法中，当获取到一个Server对象之后，将之包装成一个RibbonServer对象（从包装的过程我们可以发现，RibbonServer对象中保存了Server的所有信息，同时还保存了服务名serviceId、是否需要HTTPS等其他信息），然后再调用另一个重载的execute方法，在另一个重载的execute方法中最终调用到了LoadBalancerRequest中的apply方法，该方法向一个具体的服务实例发送请求，从而实现了从`http://服务名/hello`到`http://域名/hello`的转换。

后续补充apply...