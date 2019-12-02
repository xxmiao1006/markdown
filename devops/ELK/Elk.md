## ELK

```bash
sysctl -w vm.max_map_count=262144
docker run -p 5601:5601 -p 9200:9200 -p 5044:5044 -it --name elk -e ES_MIN_MEM=512m -e ES_MAX_MEM=1024m  sebp/elk
```

