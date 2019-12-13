## ELK

```bash
sysctl -w vm.max_map_count=262144
docker run -p 5601:5601 -p 9200:9200 -p 5044:5044 -it --name elk -e ES_MIN_MEM=512m -e ES_MAX_MEM=1024m  sebp/elk
```





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