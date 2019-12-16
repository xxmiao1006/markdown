## ELK

```bash
sysctl -w vm.max_map_count=262144
docker run -p 5601:5601 -p 9200:9200 -p 5044:5044 -it --name elk -e ES_MIN_MEM=512m -e ES_MAX_MEM=1024m  sebp/elk
```





### filebeat

```bash
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.8.5-linux-x86_64.tar.gz
tar xzvf filebeat-6.8.5-linux-x86_64.tar.gz
#启动
.\filebeat.exe -c filebeat.yml -e

#测试输出
./filebeat test output
```



### kibana

```bash
wget https://artifacts.elastic.co/downloads/kibana/kibana-6.3.2-linux-x86_64.tar.gz
sha1sum kibana-6.3.2-linux-x86_64.tar.gz 
tar -xzf kibana-6.3.2-linux-x86_64.tar.gz
```

注意如果在阿里云上部署想通过ip访问先配置安全组规则，再去kibana.yml中配置servethost为0.0.0.0

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



### Filebeat

Filebeat Module