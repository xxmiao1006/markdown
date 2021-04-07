## elasticsearch

### 一. elasticsearch部署与启动（windows）

下载ElasticSearch 5.6.8版本，无需安装，解压安装包后即可使用

https://www.elastic.co/downloads/past-releases/elasticsearch-5-6-8

进入ElasticSearch安装目录下的bin目录,执行命令

```bash
elasticsearch
```

我们打开浏览器，在地址栏输入http://127.0.0.1:9200/ 即可看到输出结果

```json
{
  "name" : "8kVxuGR",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "f6iBozWXR8CItIY6qf0pAA",
  "version" : {
    "number" : "5.6.8",
    "build_hash" : "688ecce",
    "build_date" : "2018-02-16T16:46:30.010Z",
    "build_snapshot" : false,
    "lucene_version" : "6.6.1"
  },
  "tagline" : "You Know, for Search"
}
```

### 二. Head插件的安装和使用

如果都是通过rest请求的方式使用Elasticsearch，未免太过麻烦，而且也不够人性化。我
们一般都会使用图形化界面来实现Elasticsearch的日常管理，最常用的就是Head插件

* 步骤1：
  下载head插件：https://github.com/mobz/elasticsearch-head

* 步骤2：
  解压到任意目录，但是要和elasticsearch的安装目录区别开。

* 步骤3：
  安装node js ,安装cnpm

  ```cmd
  npm install -g cnpm --registry=https://registry.npm.taobao.org
  ```

* 步骤4：
  将grunt安装为全局命令 。Grunt是基于Node.js的项目构建工具。它可以自动运行你所
  设定的任务
  
  ```cmd
  npm install -g grunt -cli
  ```
  
* 步骤5：安装依赖

  ```bash
  cnpm install
  ```

* 步骤6：进入head目录启动head，在命令提示符下输入命令

  ```bash
  grunt server
  ```

* 步骤7：打开浏览器，输入 http://localhost:9100

* 步骤8：点击连接按钮没有任何相应，按F12发现有如下错误

​       ` No 'Access-Control-Allow-Origin' header is present on the requested resource`

   这个错误是由于elasticsearch默认不允许跨域调用，而elasticsearch-head是属于前端工程，所以报错。我们这时需要修改elasticsearch的配置，让其允许跨域访问。

修改elasticsearch配置文件：elasticsearch.yml，增加以下两句命令：

```yml
http.cors.enabled: true
http.cors.allow-origin: "*"
```

### 三. Ik分词器

IK分词是一款国人开发的相对简单的中文分词器。虽然开发者自2012年之后就不在维护了，但在工程应用中IK算是比较流行的一款！我们今天就介绍一下IK中文分词器的使用。

下载地址：https://github.com/medcl/elasticsearch-analysis-ik/releases 

* 先将其解压，将解压后的elasticsearch文件夹重命名文件夹为ik

* 将ik文件夹拷贝到elasticsearch/plugins 目录下。

* 重新启动，即可加载IK分词器

IK提供了两个分词算法ik_smart 和 ik_max_word
其中 ik_smart 为最少切分，ik_max_word为最细粒度划分

我们分别来试一下
（1）最小切分：在浏览器地址栏输入地址
http://127.0.0.1:9200/_analyze?analyzer=ik_smart&pretty=true&text=我是程序员 输出的结果为：

```json
{
	"tokens": [{
			"token": "我",
			"start_offset": 0,
			"end_offset": 1,
			"type": "CN_CHAR",
			"position": 0
		},
		{
			"token": "是",
			"start_offset": 1,
			"end_offset": 2,
			"type": "CN_CHAR",
			"position": 1
		},
		{
			"token": "程序员",
			"start_offset": 2,
			"end_offset": 5,
			"type": "CN_WORD",
			"position": 2
		}
	]
}
```

（2）最细切分：在浏览器地址栏输入地址

http://127.0.0.1:9200/_analyze?analyzer=ik_max_word&pretty=true&text=我是程序员 输出的结果为：

```json
{
	"tokens": [{
			"token": "我",
			"start_offset": 0,
			"end_offset": 1,
			"type": "CN_CHAR",
			"position": 0
		},
		{
			"token": "是",
			"start_offset": 1,
			"end_offset": 2,
			"type": "CN_CHAR",
			"position": 1
		},
		{
			"token": "程序员",
			"start_offset": 2,
			"end_offset": 5,
			"type": "CN_WORD",
			"position": 2
		},
		{
			"token": "程序",
			"start_offset": 2,
			"end_offset": 4,
			"type": "CN_WORD",
			"position": 3
		},
		{
			"token": "员",
			"start_offset": 4,
			"end_offset": 5,
			"type": "CN_CHAR",
			"position": 4
		}
	]
}
```

#### 自定义词库

http://127.0.0.1:9200/_analyze?analyzer=ik_smart&pretty=true&text=是根大噶  结果为

```json
{
  "tokens": [
    {
      "token": "是",
      "start_offset": 0,
      "end_offset": 1,
      "type": "CN_CHAR",
      "position": 0
    },
    {
      "token": "根",
      "start_offset": 1,
      "end_offset": 2,
      "type": "CN_CHAR",
      "position": 1
    },
    {
      "token": "大",
      "start_offset": 2,
      "end_offset": 3,
      "type": "CN_CHAR",
      "position": 2
    },
    {
      "token": "噶",
      "start_offset": 3,
      "end_offset": 4,
      "type": "CN_CHAR",
      "position": 3
    }
  ]
}
```

如果我们想让系统识别“是根大噶”是一个词，需要编辑自定义词库。

步骤：

* 进入elasticsearch/plugins/ik/config目录

* 新建一个my.dic文件，编辑内容：

  ```
  是根大噶
  ```

  修改IKAnalyzer.cfg.xml（在ik/config目录下）

  ```xml
  <properties>
  <comment>IK Analyzer 扩展配置</comment>
  <!‐‐用户可以在这里配置自己的扩展字典 ‐‐>
  <entry key="ext_dict">my.dic</entry>
  <!‐‐用户可以在这里配置自己的扩展停止词字典‐‐>
  <entry key="ext_stopwords"></entry>
  </properties>
  ```

  重新启动elasticsearch,通过浏览器测试分词效果

```json
{
  "tokens": [
    {
      "token": "是根大噶",
      "start_offset": 0,
      "end_offset": 4,
      "type": "CN_WORD",
      "position": 0
    }
  ]
}
```

### 四. 使用logstash将Mysql数据导入Elasticsearch

Logstash是一款轻量级的日志搜集处理框架，可以方便的把分散的、多样化的日志搜集
起来，并进行自定义的处理，然后传输到指定的位置，比如某个服务器或者文件。

解压，进入bin目录

```bash
logstash -e 'input { stdin { } } output { stdout {} }'
```

控制台输入字符，随后就有日志输出,stdin，表示输入流，指从键盘输入;stdout，表示输出流，指从显示器输出
命令行参数: 

 -e 执行

 --config 或 -f 配置文件，后跟参数类型可以是一个字符串的配置或全路径文件名或全路径路径(如：/etc/logstash.d/，logstash会自动读取/etc/logstash.d/目录下所有*.conf 的文本文件，然后在自己内存里拼接成一个完整的大配置文件再去执行)

（1）在logstash-5.6.8安装目录下创建文件夹mysqletc （名称随意）

（2）文件夹下创建mysql.conf （名称随意） ，内容如下：

```conf
input {
  jdbc {
	  # mysql jdbc connection string to our backup databse
	  jdbc_connection_string => "jdbc:mysql://127.0.0.1:3306/tensquare_article?characterEncoding=UTF8"
	  # the user we wish to excute our statement as
	  jdbc_user => "root"
	  jdbc_password => "root"
	  # the path to our downloaded jdbc driver  
	  jdbc_driver_library => "E:/devops/elastic/logstash-5.6.8/mysqletc/mysql-connector-java-5.1.46.jar"
	  # the name of the driver class for mysql
	  jdbc_driver_class => "com.mysql.jdbc.Driver"
	  jdbc_paging_enabled => "true"
	  jdbc_page_size => "50000"
	  #以下对应着要执行的sql的绝对路径。
	  #statement_filepath => ""
	  statement => "select id,title,content from tb_article"
	  #定时字段 各字段含义（由左至右）分、时、天、月、年，全部为*默认含义为每分钟都更新（测试结果，不同的话请留言指出）
      schedule => "* * * * *"
  }
}

output {
  elasticsearch {
	  #ESIP地址与端口
	  hosts => "localhost:9200" 
	  #ES索引名称（自己定义的）
	  index => "tensquare"
	  #自增ID编号
	  document_id => "%{id}"
	  document_type => "article"
  }
  stdout {
      #以JSON格式输出
      codec => json_lines
  }
}

```

（3）将mysql驱动包mysql-connector-java-5.1.46.jar拷贝至D:/logstash5.6.8/mysqletc/ 下 。D:/logstash-5.6.8是你的安装目录

（4）命令行下执行

```bash
logstash -f ../mysqletc/mysql.conf
```

观察控制台输出，每间隔1分钟就执行一次sql查询。

### 五. elasticsearch docker环境下安装

（1）下载镜像

```bash
docker pull elasticsearch:5.6.8
```

（2）创建容器

```bash
docker run -di --name=tensquare_elasticsearch -p 9200:9200 -p 9300:9300 elasticsearch:5.6.8
```

（3）浏览器输入地址：
http://192.168.184.134:9200/ 即可看到如下信息

```json
{
  "name" : "ptfqpDk",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "oxaIdzWZSn26Mk3783tqew",
  "version" : {
    "number" : "5.6.8",
    "build_hash" : "688ecce",
    "build_date" : "2018-02-16T16:46:30.010Z",
    "build_snapshot" : false,
    "lucene_version" : "6.6.1"
  },
  "tagline" : "You Know, for Search"
}
```

这时候直接启动程序连接elasticsearch会报错因为elasticsearch从5版本以后默认不开启远程连接，需要修改配置文件

（4）我们进入容器

```bash
docker exec -it tensquare_elasticsearch /bin/bash
```

此时，我们看到elasticsearch所在的目录为/usr/share/elasticsearch ,进入config看到了配置文件elasticsearch.yml

我们通过vi命令编辑此文件，尴尬的是容器并没有vi命令 ，咋办？我们需要以文件挂载的方式创建容器才行，这样我们就可以通过修改宿主机中的某个文件来实现对容器内配置文件的修改.

（5）拷贝配置文件到宿主机

首先退出容器（exit），然后执行命令：

```
docker cp tensquare_elasticsearch:/usr/share/elasticsearch/config/elasticsearch.yml /usr/share/elasticsearch.yml
```

（6）停止和删除原来创建的容器

```bash
docker stop tensquare_elasticsearch
docker rm tensquare_elasticsearch
```

（7）重新执行创建容器命令

```bash
docker run -di --name=tensquare_elasticsearch -p 9200:9200 -p 9300:9300 -v /usr/share/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml elasticsearch:5.6.8
```

（8）修改/usr/share/elasticsearch.yml 将`transport.host: 0.0.0.0` 前的#去掉后保存文件退出。其作用是允许任何ip地址访问elasticsearch .开发测试阶段可以这么做，生产环境下指定具体的IP

（9）重启启动

```bash
docker restart tensquare_elasticsearch
```

重启后发现重启启动失败了，这时什么原因呢？这与我们刚才修改的配置有关，因为elasticsearch在启动的时候会进行一些检查，比如最多打开的文件的个数以及虚拟内存区域数量等等，如果你放开了此配置，意味着需要打开更多的文件以及虚拟内存，所以我们还需要系统调优。

（10）系统调优

我们一共需要修改两处

修改/etc/security/limits.conf ，追加内容

```bash
* soft nofile 65536
* hard nofile 65536
```

nofile是单个进程允许打开的最大文件个数 soft nofile 是软限制 hard nofile是硬限制

修改/etc/sysctl.conf，追加内容

```bash
vm.max_map_count=655360
```

限制一个进程可以拥有的VMA(虚拟内存区域)的数量 执行下面命令 修改内核参数马上生效

```bash
sysctl -p
```

（11）重新启动虚拟机，再次启动容器，发现已经可以启动并远程访问

#### 1. IK分词器安装

（1）将ik文件夹上传至宿主机

（2）在宿主机中将ik文件夹拷贝到容器内 /usr/share/elasticsearch/plugins 目录下。

（3）重新启动，即可加载IK分词器

```bash
docker restart tensquare_elasticsearch
```

#### 2. Head插件安装

（1）修改/usr/share/elasticsearch.yml ,添加允许跨域配置

```yml
http.cors.enabled: true
http.cors.allow-origin: "*"

```

（2）重新启动elasticseach容器
（3）下载head镜像（此步省略）

```bash
docker pull mobz/elasticsearch‐head:5
```

（4）创建head容器

```bash
docker run -di --name=myhead -p 9100:9100 docker pull mobz/elasticsearch-head:5
```



### 六. 倒排索引

在没有搜索引擎时，我们是直接输入一个网址，然后获取网站内容，这时我们的行为是：

document -> to -> words

通过文章，获取里面的单词，此谓「正向索引」，forward index.

后来，我们希望能够输入一个单词，找到含有这个单词，或者和这个单词有关系的文章：

word -> to -> documents

于是我们把这种索引，成为inverted index，直译过来，应该叫「反向索引」，国内翻译成「倒排索引」，有点委婉了

![倒排索引.png](http://ww1.sinaimg.cn/large/0072fULUgy1gp3z64k7fkj313h0lpto9.jpg)



![ela.png](http://ww1.sinaimg.cn/large/0072fULUgy1gp3z6y5043j30im09f779.jpg)

​		Lucene 的倒排索，增加了最左边的一层「字典树」term index，它不存储所有的单词，只存储单词前缀，通过字典树找到单词所在的块，也就是单词的大概位置，再在块里二分查找，找到对应的单词，再找到单词对应的文档列表











[elasticsearch的倒排索引](https://zhuanlan.zhihu.com/p/76485252)