#!/bin/bash
set -e

# 显示欢迎信息
echo "====== acme.sh HTTPS 证书自动化容器 ======"
echo "域名: $DOMAIN"
echo "DNS API: $DNS_API"
echo "证书更新天数: $RENEW_DAYS"
echo "证书邮箱: $CERT_EMAIL"

# 验证邮箱地址并确保不使用example.com
if [[ -z "$CERT_EMAIL" || "$CERT_EMAIL" == *"@example.com"* ]]; then
    echo "警告: 邮箱地址无效或使用example.com域名，建议使用真实有效的邮箱"
    echo "将不使用邮箱地址进行注册"
    CERT_EMAIL=""
else
    # 如果邮箱有效，更新acme.sh账户配置文件
    echo "设置acme.sh全局邮箱: $CERT_EMAIL"
    if [ -f "/root/.acme.sh/account.conf" ]; then
        # 如果配置文件存在，更新邮箱
        sed -i "s/^ACCOUNT_EMAIL=.*$/ACCOUNT_EMAIL=\"$CERT_EMAIL\"/" /root/.acme.sh/account.conf 2>/dev/null || true
    else
        # 如果配置文件不存在，创建一个新的
        mkdir -p /root/.acme.sh
        echo "ACCOUNT_EMAIL=\"$CERT_EMAIL\"" > /root/.acme.sh/account.conf
    fi
fi

# 设置 acme.sh
echo "配置 acme.sh..."
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
# 如果邮箱有效，注册账户
if [ -n "$CERT_EMAIL" ]; then
    echo "使用邮箱注册账户..."
    /root/.acme.sh/acme.sh --register-account -m "$CERT_EMAIL"
fi

# 配置通知设置
/root/.acme.sh/acme.sh --set-notify --notify-level 2 --notify-mode 0

# 设置更新时间使用正确的参数
if [ -n "$RENEW_DAYS" ]; then
    echo "设置证书提前 $RENEW_DAYS 天更新..."
    /root/.acme.sh/acme.sh --set-notify-renew-hook --renew-hook "$RENEW_DAYS" 2>/dev/null || true
fi

# 设置域名参数
DOMAIN_PARAMS="-d *.$DOMAIN -d $DOMAIN"
echo "添加泛域名: *.$DOMAIN 和根域名: $DOMAIN"

# 设置DNS API环境变量
if [ "$DNS_API" = "dns_cf" ]; then
    export CF_Key="$DNS_API_KEY"
    export CF_Email="$DNS_API_SECRET"
elif [ "$DNS_API" = "dns_dp" ]; then
    export DP_Id="$DNS_API_KEY"
    export DP_Key="$DNS_API_SECRET"
elif [ "$DNS_API" = "dns_ali" ]; then
    export Ali_Key="$DNS_API_KEY"
    export Ali_Secret="$DNS_API_SECRET"
elif [ "$DNS_API" = "dns_tencent" ]; then
    # 正确设置腾讯云DNS环境变量
    echo "设置腾讯云DNS验证参数..."
    export Tencent_SecretId="$DNS_API_KEY"
    export Tencent_SecretKey="$DNS_API_SECRET"
else
    echo "警告: 未知的DNS API提供商: $DNS_API"
fi

# 检查证书是否已存在
if [ -d "/root/.acme.sh/$DOMAIN" ] && [ -f "/root/.acme.sh/$DOMAIN/$DOMAIN.cer" ]; then
    echo "证书已存在，检查是否需要更新..."
    /root/.acme.sh/acme.sh --renew $DOMAIN_PARAMS --force --keylength "$CERT_KEYLENGTH"
else
    echo "证书不存在，申请新证书..."
    # 对于泛域名，必须使用DNS验证方式
    /root/.acme.sh/acme.sh --log --issue $DOMAIN_PARAMS --dns "$DNS_API" --keylength "$CERT_KEYLENGTH" --force
fi

# 创建证书目录
mkdir -p /acme-certs/$DOMAIN

# 安装证书到指定目录
echo "安装证书到 /acme-certs 目录..."
/root/.acme.sh/acme.sh --install-cert $DOMAIN_PARAMS \
    --key-file       /acme-certs/$DOMAIN/cert.key \
    --fullchain-file /acme-certs/$DOMAIN/cert.fullchain.cer \
    --cert-file      /acme-certs/$DOMAIN/cert.cer \
    --ca-file        /acme-certs/$DOMAIN/cert.ca.cer

# 执行颁发后钩子脚本(如果有)
if [ -n "$ISSUE_HOOK" ]; then
    echo "执行颁发后钩子脚本..."
    eval "$ISSUE_HOOK"
fi

# 显示cron任务
echo "当前cron任务:"
crontab -l

# 启动cron服务
echo "启动cron服务..."
crond -f -l 8