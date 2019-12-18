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
#解析json 可用grok 图简单就直接用这个了 
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

* elasticsearch curd（restful api）

```bash
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

* elasticsearch query

```bash
#query string
GET /accounts/person/_search?q=john

#query DSL
#查询所有商品
GET /product_index/product/_search
{
  "query": {
    "match_all": {}
  }
}

#查询商品名称包含 toothbrush 的商品，同时按照价格降序排序
GET /product_index/product/_search
{
  "query": {
    "match": {
      "product_name": "toothbrush"
    }
  },
  "sort": [
    {
      "price": "desc"
    }
  ]
}

#分页查询商品
GET /product_index/product/_search
{
  "query": {
    "match_all": {}
  },
  "from": 0, ## 从第几个商品开始查，最开始是 0
  "size": 1  ## 要查几个结果
}

#指定查询结果字段（field）
GET /product_index/product/_search
{
  "query": {
    "match_all": {}
  },
  "_source": [
    "product_name",
    "price"
  ]
}

#搜索商品名称包含 toothbrush，而且售价大于 400 元，小于 700 的商品
#注 query 和 filter 一起使用的话，filter 会先执行 filter（性能更好，无排序） query（性能较差，有排序
GET /product_index/product/_search
{
  "query": {
    "bool": {
      "must": {
        "match": {
          "product_name": "toothbrush"
        }
      },
      "filter": {
        "range": {
          "price": {
            "gt": 400,
            "lt": 700
          }
        }
      }
    }
  }
}

#1.匹配查询 match(其实是模糊查询)，match_all match 用法（与 term 进行对比）查询的字段内容是进行分词处理的，
#   只要分词的单词结果中，在数据中有满足任意的分词结果都会被查询出来
GET _search
{
  "query": {
    "match_all": {}
  }
}
#product_name为PHILIPS toothbrush  会分为2个词 包含的这两个词的所有结果都会展示出来  但是2个都包含显示在前面
#加operator为and  相当于并且  这时候查询出来的结果是2个都包含的
GET /product_index/product/_search
{
  "query": {
    "match": {
      "product_name": "PHILIPS toothbrush"
      #"operator": "and"
    }
  }
}
#multi_match 跨多个 field 查询



#must： 类似于SQL中的AND，必须包含
#must_not： 类似于SQL中的NOT，必须不包含
#should： 满足这些条件中的任何条件都会增加评分_score，不满足也不影响，should只会影响查询结果的_score值，并不会影响结果的内容
#filter： 与must相似，但不会对结果进行相关性评分_score，大多数情况下我们对于日志的需求都无相关性的要求，所以建议查询的过程中多用filter

#2.过滤查询 Filter 查找basicdata响应时间大于等于3ms的数据
GET /filebeat-*/_search
{
  "query": {
    "bool":{
      "filter":{
        "range": {
          "ElapsedMilliseconds": {
            "gte": 3          }
        }
      },
      "must":{
        "match":{
          "ServiceName":"BasicDataHost"
        }
      }
    }
  }
}

#3.range 用法，查询数值、时间区间  查找请求时间为12-18号8点到9点的请求 并且按响应时间降序排序
GET /filebeat-*/_search
{
  "query": {
    "range": {
      "RequestTime": {
        "gte": "2019-12-18T08:00:28.2635316+08:00",
        "lte": "2019-12-18T09:00:28.2635316+08:00"
      }
    }
  },
  "sort": [
    {
      "ElapsedMilliseconds": {
        "order": "desc"
      }
    }
  ]
}

#4.term 用法 （与 match 进行对比）（term 一般用在不分词字段上的，因为它是完全匹配查询，如果要查询的字段是分词字段就会被拆分成各种分词结果，和完全查询的内容就对应不上了。）
GET /product_index/product/_search
{
  "query": {
    "term": {
      "product_name": "PHILIPS toothbrush"
    }
  }
}

GET /product_index/product/_search
{
  "query": {
    "constant_score": {
      "filter":{
        "term": {
          "product_name": "PHILIPS toothbrush"
        }
      }
    }
  }
}
#terms 类似于数据库的 in
GET /product_index/product/_search
{
  "query": {
    "constant_score": {
      "filter": {
        "terms": {
          "product_name": [
            "toothbrush",
            "shell"
          ]
        }
      }
    }
  }
}

#多搜索条件组合查询（最常用） eg
GET /product_index/product/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "match": {
            "product_name": "PHILIPS toothbrush"
          }
        }
      ],
      "should": [
        {
          "match": {
            "product_desc": "刷头"
          }
        }
      ],
      "must_not": [
        {
          "match": {
            "product_name": "HX6730"
          }
        }
      ],
      "filter": {
        "range": {
          "price": {
            "gte": 33.00
          }
        }
      }
    }
  }
}

GET /product_index/product/_search
{
  "query": {
    "bool": {
      "should": [
        {
          "term": {
            "product_name": "飞利浦"
          }
        },
        {
          "bool": {
            "must": [
              {
                "term": {
                  "product_desc": "刷头"
                },
                "term": {
                  "price": 30
                }
              }
            ]
          }
        }
      ]
    }
  }
}
```







