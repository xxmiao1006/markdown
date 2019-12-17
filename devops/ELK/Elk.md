## ELK

```bash
sysctl -w vm.max_map_count=262144
docker run -p 5601:5601 -p 9200:9200 -p 5044:5044 -it --name elk -e ES_MIN_MEM=512m -e ES_MAX_MEM=1024m  sebp/elk
```

### 在centos下安装ELK

#### 一. 安装elasticsearch,kibana,logstash,filebeat

```bash
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.4.rpm
wget https://artifacts.elastic.co/downloads/kibana/kibana-6.2.4-x86_64.rpm
wget https://artifacts.elastic.co/downloads/logstash/logstash-6.2.4.rpm
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.2.4-x86_64.rpm

yum localinstall -y elasticsearch-6.2.4.rpm
yum localinstall -y kibana-6.2.4-x86_64.rpm
yum localinstall -y logstash-6.2.4.rpm
yum localinstall -y filebeat-6.2.4-x86_64.rpm

# 新建配置文件目录
mkdir -pv /data/elasticsearch/{data,logs}
mkdir -pv /data/logstash/{data,logs}
chown -R elasticsearch.elasticsearch /data/elasticsearch/
chown -R logstash.logstash /data/logstash/
```

#### 二. 更改配置文件

* elasticsearch

```bash
vim /etc/elasticsearch/elasticsearch.yml
path.data: /data/elasticsearch/data
path.logs: /data/elasticsearch/logs
#不改这个无法通过ip访问
network.host: 0.0.0.0
http.port: 9200
```

* logstash

```bash
vim /etc/logstash/logstash.yml
path.data: /data/logstash/data
path.logs: /data/logstash/logs

#新建并编辑这个配置文件 添加配置
vim /etc/logstash/conf.d/logstash.conf
input {
  beats {
    port => 5044
    #乱码
    codec => plain {
          charset => "UTF-8"
    }
  }
}
#解析json
 filter {
    json {
        source => "message"
        #target => "doc"
        #remove_field => ["message"]
    }        
 }
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    manage_template => false
    index => "filebeat-efos"
    #index => "filebeat-efos-%{+YYYY.MM.dd}" 索引可以根据日期
    document_type => "doc"
  }
}

```

* kibana

```bash
vim /etc/kibana/kibana.yml
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.url: "http://localhost:9200"
```

* filebeat

```bash
vim /etc/filebeat/filebeat.yml

- type: log
  enabled: true
    - /var/log/*.log
    - /var/log/messages
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 3
setup.kibana:
  host: "localhost:5601"
#output.elasticsearch:    //我们输出到logstash，把这行注释掉
  #hosts: ["localhost:9200"]   //这行也注释掉
output.logstash:
  hosts: ["localhost:5044"]
  
#启动后可测试输出
#测试输出
filebeat test output
```

#### 三. 启动

```bash
systemctl start elasticsearch
systemctl start kibana
systemctl start logstash
systemctl start filebeat
```

#### 四. 问题

- 解码问题（见logstash配置文件）
- json解析问题（见logstash配置文件）
- kibana中terms字段无法选取问题

查阅官方文档kibana相关配置位置，尝试查看了setting，果然发现在index里找到了相关项，刷新后字段就被索引上了，相当于在kibana中如果索引建立后，再通过logstash添加新字段时，需要在这边刷新以更新状态（不知道重启kibana是否有同样效果，有时间可以尝试）。之后便可正常使用此字段了。

------

### elasticsearch

* elasticsearch curd

```
#增加
POST /accounts/person/1
{
	"name": "xiaoming",
	"grade": 1,
	"gender": "男",
	"birth": "2012-10-01"
}

#查找
GET /accounts/person/1
GET /filebeat-2019.12.13/doc/TuUZ_24BuXQ-Cg1PdV-H
"_index": "filebeat-2019.12.13",
  "_type": "doc",
  "_id": "TuUZ_24BuXQ-Cg1PdV-H",

#更新
POST /accounts/person/1/_update
{
	"doc": {
	  "grade":2
	}
}

#删除
DELETE /accounts/person/1
DELETE /accounts
#删除所有索引
DELETE /_all

#分词器
POST _analyze
{
  "analyzer": "standard",
  "text": "hello world!"
}


```

* elasticsearch qury

```
#query string
GET /accounts/person/_search?q=john

#query DSL
GET /accounts/person/_search
{
	"query":{
		"match":{
			"name" : "john"
		}
	}
}

GET /accounts/person/_search
{
  "query": {
    "term": {
      "name": {
        "value": "xiaoming"
      }
    }
  }
}
```







