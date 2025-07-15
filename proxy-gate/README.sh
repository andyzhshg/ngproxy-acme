## 入口 nginx

```bash
#!/bin/sh

# path of this script
BASE_ROOT=$(cd "$(dirname "$0")";pwd)

docker pull registry.cn-shanghai.aliyuncs.com/onezero/proxy-gate:latest

docker stop gate-proxy
docker rm gate-proxy

sudo docker run -d \
    --restart always \
    --name gate-proxy \
    -p 80:80 \
    -p 443:443 \
    --network videosafe \
    -v /mnt/share/ssl:/certs \
    -v $BASE_ROOT/logs:/var/log/nginx \
    -v $BASE_ROOT/www:/usr/share/nginx/html \
    -v $BASE_ROOT/conf:/etc/nginx/conf.d \
    registry.cn-shanghai.aliyuncs.com/onezero/proxy-gate:latest

docker ps -a | grep gate-proxy
```
