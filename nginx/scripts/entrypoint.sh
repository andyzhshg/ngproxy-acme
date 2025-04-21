#!/bin/bash
set -e

echo "======= 初始化 Nginx 反向代理容器 ======="

# 创建必要的目录
mkdir -p /config /certs /var/log/nginx /var/log/supervisor

# 设置默认配置
if [ ! -f "/config/proxy-config.json" ]; then
    echo "创建默认配置文件..."
    cat > /config/proxy-config.json << EOF
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
    echo "默认配置文件已创建"
fi

# 创建默认错误页面
if [ ! -f "/var/www/html/404.html" ]; then
    echo "创建默认错误页面..."
    cat > /var/www/html/404.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>404 - 页面未找到</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { font-size: 36px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>404 - 页面未找到</h1>
    <p>您请求的页面不存在。</p>
</body>
</html>
EOF
fi

if [ ! -f "/var/www/html/50x.html" ]; then
    cat > /var/www/html/50x.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>服务器错误</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { font-size: 36px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>服务器错误</h1>
    <p>服务器暂时无法处理您的请求。</p>
</body>
</html>
EOF
fi

# 生成初始配置
echo "生成初始Nginx配置..."
/opt/scripts/generate-configs.sh

# 检查配置是否有效
if ! nginx -t; then
    echo "错误: Nginx 配置无效，请检查配置文件"
    exit 1
fi

echo "初始化完成，启动服务..."

# 执行传入的命令
exec "$@" 