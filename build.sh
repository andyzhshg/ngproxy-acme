#!/bin/bash


docker buildx build --platform linux/amd64 -t registry.cn-shanghai.aliyuncs.com/onezero/ngproxy:latest nginx --push
docker buildx build --platform linux/amd64 -t registry.cn-shanghai.aliyuncs.com/onezero/acme.sh:latest acme --push
