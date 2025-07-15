#!/bin/sh

# 随机等待 10-100 秒，避免所有节点同时 reload
SLEEP_TIME=$((RANDOM % 90 + 10))
echo "Sleeping for $SLEEP_TIME seconds before reloading nginx"
sleep $SLEEP_TIME

# 重新加载 nginx，主要是为了更新证书
nginx -s reload

# 输出当前时间
echo "Nginx reloaded at $(date)"
