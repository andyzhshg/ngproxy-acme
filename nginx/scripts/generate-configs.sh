#!/bin/bash
set -e

CONFIG_FILE="/config/proxy-config.json"
TEMPLATE_DIR="/etc/nginx/templates"
CONF_DIR="/etc/nginx/conf.d"

# 确保配置目录存在
mkdir -p "$CONF_DIR"

# 清除现有的配置文件
rm -f "$CONF_DIR"/*.conf

echo "开始生成Nginx配置..."

echo "CONFIG_FILE: $CONFIG_FILE"
# 打印配置文件内容
echo "配置文件内容:"
cat "$CONFIG_FILE"

# 如果配置文件不存在，创建默认配置
if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件不存在，创建默认配置..."
    cat > "$CONFIG_FILE" << EOF
{
  "sites": [
    {
      "domain": "example.com",
      "ssl": true,
      "locations": [
        {
          "path": "/",
          "proxy_pass": "http://localhost:8080",
          "websocket": false
        }
      ]
    }
  ]
}
EOF
fi

# 获取站点数量
site_count=$(jq '.sites | length' "$CONFIG_FILE")
echo "找到 $site_count 个站点配置"

# 处理每个站点
for ((i=0; i<$site_count; i++)); do
    site_json=$(jq -c ".sites[$i]" "$CONFIG_FILE")
    
    echo "处理站点 #$i: $site_json"
    
    # 提取域名和SSL设置
    domain=$(echo "$site_json" | jq -r '.domain')
    ssl=$(echo "$site_json" | jq -r '.ssl')
    
    echo "处理站点: $domain"
    
    # 确保域名有效
    if [ -z "$domain" ] || [ "$domain" = "null" ]; then
        echo "警告: 跳过无效域名配置"
        continue
    fi
    
    # 创建配置文件
    conf_file="$CONF_DIR/$domain.conf"
    
    # 根据SSL选项选择模板
    if [ "$ssl" = "true" ]; then
        cert_dir="/certs/$domain"
        
        # 获取主域名
        main_domain=$(echo "$domain" | awk -F. '{if (NF>2) {print $(NF-1)"."$(NF)} else {print $0}}')
        main_cert_dir="/certs/$main_domain"
        
        echo "域名: $domain, 主域名: $main_domain"
        
        # 首先检查子域名证书
        if [ -f "$cert_dir/cert.key" ] && [ -f "$cert_dir/cert.fullchain.cer" ]; then
            echo "使用SSL模板 - 找到域名证书: $domain"
            template="$TEMPLATE_DIR/ssl-site.conf.template"
            use_cert_dir="$cert_dir"
        # 然后检查主域名证书
        elif [ -f "$main_cert_dir/cert.key" ] && [ -f "$main_cert_dir/cert.fullchain.cer" ]; then
            echo "使用SSL模板 - 找到主域名证书: $main_domain"
            template="$TEMPLATE_DIR/ssl-site.conf.template"
            use_cert_dir="$main_cert_dir"
        else
            echo "证书文件不存在，使用非SSL模板"
            template="$TEMPLATE_DIR/non-ssl-site.conf.template"
        fi
    else
        echo "使用非SSL模板"
        template="$TEMPLATE_DIR/non-ssl-site.conf.template"
    fi
    
    # 创建一个空白的临时配置文件
    > "$conf_file.tmp"
    
    # 读取主模板文件直到"动态生成的locations将被添加在这里"行
    awk '/# 动态生成的locations将被添加在这里/ {print; exit} {print}' "$template" > "$conf_file.tmp"
    
    # 替换域名
    sed -i "s/{{domain}}/$domain/g" "$conf_file.tmp"
    
    # 如果是SSL站点，替换证书路径
    if [ "$ssl" = "true" ] && [ -n "${use_cert_dir:-}" ] && [ -f "$use_cert_dir/cert.key" ] && [ -f "$use_cert_dir/cert.fullchain.cer" ]; then
        sed -i "s|{{ssl_certificate}}|$use_cert_dir/cert.fullchain.cer|g" "$conf_file.tmp"
        sed -i "s|{{ssl_certificate_key}}|$use_cert_dir/cert.key|g" "$conf_file.tmp"
    fi
    
    # 处理locations
    location_count=$(echo "$site_json" | jq '.locations | length')
    
    # 创建location配置字符串
    location_configs=""
    
    # 为每个位置添加配置
    for ((j=0; j<$location_count; j++)); do
        location_json=$(echo "$site_json" | jq -c ".locations[$j]")
        
        path=$(echo "$location_json" | jq -r '.path')
        proxy_pass=$(echo "$location_json" | jq -r '.proxy_pass')
        websocket=$(echo "$location_json" | jq -r '.websocket')
        
        echo "  - 位置: $path -> $proxy_pass (WebSocket: $websocket)"
        
        location_config="    location $path {\n"
        location_config+="        proxy_pass $proxy_pass;\n"
        location_config+="        proxy_pass_header Content-Type;\n"
        location_config+="        proxy_set_header Host \$host;\n"
        location_config+="        proxy_set_header X-Real-IP \$remote_addr;\n"
        location_config+="        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n"
        location_config+="        proxy_set_header X-Forwarded-Proto \$scheme;\n"
        
        # 添加WebSocket支持
        if [ "$websocket" = "true" ]; then
            location_config+="        proxy_http_version 1.1;\n"
            location_config+="        proxy_set_header Upgrade \$http_upgrade;\n"
            location_config+="        proxy_set_header Connection \"upgrade\";\n"
        fi
        
        location_config+="    }\n\n"
        
        # 添加到位置配置字符串
        location_configs+="$location_config"
    done
    
    # 添加location配置
    echo -e "$location_configs" >> "$conf_file.tmp"
    
    # 添加结尾配置（错误页等）
    cat "$TEMPLATE_DIR/site-end.conf.template" >> "$conf_file.tmp"
    
    # 应用配置
    mv "$conf_file.tmp" "$conf_file"
    echo "配置已生成: $conf_file"
    cat "$conf_file"
done

echo "配置生成完成"
nginx -t && echo "Nginx配置检查通过" || (echo "Nginx配置错误!" && exit 1) 