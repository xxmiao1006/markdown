## Kubernetes快速交互实验手册

### 一. 实验介绍

此交互实验可以让你不用搭建K8S环境就可以轻松地尝试管理一个简单的容器化应用集群。此交互实验主要基于虚拟终端（Virutal Terminal），可以直接在你的Web浏览器中运行Minikube，这是一个可以随处运行K8S的最小化的本地K8S环境，不需要你安装任何软件和做任何配置。

### 二. 实验内容

1. 创建一个集群
2. 部署一个应用
3. 访问当前应用
4. 伸缩当前应用
5. 滚动更新应用

### 三. 具体步骤

#### 创建一个集群

进入实验地址：https://kubernetes.io/docs/tutorials/kubernetes-basics/create-cluster/cluster-interactive/

选中“Create a Cluster"=>"Interactive Tutorial - Creating a Cluster"，从这里开始，然后会看到提示和终端的界面，这是一个基于Minikube的K8S终端，通过在终端中执行 minikube start 来创建一个单节点的K8S集群：

![basic-1.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9tq62l6y3j30vj0gsjs3.jpg)

通过执行 kubectl cluster-info 可以查看集群信息：

![basic-2.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9tq8b4k1ej30vk0gwaas.jpg)

#### 部署一个应用

这里使用示例的命令部署一个应用

```bash
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
```



![basic-3.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9tqdrgoguj30vi0gsgme.jpg)

通过执行`kubectl get pods`可以看到，当前的kubernetes-bootcamp-75bccb7d87-626s9就是当前应用的Pod。

#### 访问当前应用

默认情况下，所有Pod只能在集群内部访问，想要从外部访问，就必须映射端口

```bash
echo -e "\n\n\n\e[92mStarting Proxy. After starting it will not output a response. Please click the first Terminal Tab\n";
kubectl proxy
```

![basic-4.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9tqph919pj30vf0gq3za.jpg)

```bash
curl http://localhost:8001/version
```

![basic-5.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9tqqzps5jj30vp0gugm5.jpg)

