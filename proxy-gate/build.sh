#!/bin/bash

docker buildx build --platform linux/amd64 -t registry.cn-shanghai.aliyuncs.com/onezero/proxy-gate:latest . --push
