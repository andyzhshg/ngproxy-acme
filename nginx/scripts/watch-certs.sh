#!/bin/bash

CERT_DIR="/certs"
CONFIG_FILE="/config/proxy-config.json"

echo "开始监控证书目录: $CERT_DIR"

# 首次启动生成配置
/opt/scripts/generate-configs.sh

# 函数：当证书变化时更新Nginx
update_nginx() {
    echo "检测到证书变化，重新生成配置..."
    /opt/scripts/generate-configs.sh
    
    if [ $? -eq 0 ]; then
        echo "正在重新加载 Nginx..."
        nginx -s reload
        echo "Nginx 已重新加载"
    else
        echo "Nginx 配置无效，不重新加载"
    fi
}

# 当配置文件变化时更新
update_config() {
    echo "检测到配置文件变化，重新生成配置..."
    /opt/scripts/generate-configs.sh
    
    if [ $? -eq 0 ]; then
        echo "正在重新加载 Nginx..."
        nginx -s reload
        echo "Nginx 已重新加载"
    else
        echo "Nginx 配置无效，不重新加载"
    fi
}

# 使用inotifywait持续监控证书目录和配置文件
(
    inotifywait -m -r -e modify,create,delete,move "$CERT_DIR" --format "%w%f" | while read -r file; do
        echo "证书文件变更: $file"
        
        # 只有当证书文件变化时才触发更新
        if [[ "$file" == *".key" || "$file" == *".cer" || "$file" == *".crt" || "$file" == *".pem" ]]; then
            update_nginx
        fi
    done
) &

(
    inotifywait -m -e modify,create "$CONFIG_FILE" --format "%w%f" | while read -r file; do
        echo "配置文件变更: $file"
        update_config
    done
) &

# 保持脚本运行
wait 