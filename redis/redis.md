## redis

docker	启动redis并配置密码

```bash
docker pull redis:latest
docker run --name redis-tensquare -p 6379:6379 -d --restart=always redis:latest redis-server --appendonly yes --requirepass "sUlnkfBOQ3MglYN1"

```

