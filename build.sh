#!/bin/bash


docker buildx build --platform linux/amd64 -t registry.cn-shanghai.aliyuncs.com/onezero/ngproxy:latest nginx --push
docker buildx build --platform linux/amd64 -t registry.cn-shanghai.aliyuncs.com/onezero/acme.sh:latest acme --push
# docker buildx build --platform linux/amd64 -t ccr.ccs.tencentyun.com/videosafe/ngproxy:latest nginx --push
# docker buildx build --platform linux/amd64 -t ccr.ccs.tencentyun.com/videosafe/acme.sh:latest acme --push
