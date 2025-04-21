FROM alpine:3.19

# 安装必要的软件包
RUN apk add --no-cache \
    openssl \
    curl \
    socat \
    tzdata \
    bash \
    coreutils \
    bind-tools \
    tar \
    ca-certificates \
    dcron

# 设置工作目录
WORKDIR /root

# 安装acme.sh
RUN curl https://get.acme.sh | sh -s email=my@example.com

# 创建配置目录
RUN mkdir -p /acme-certs

# 添加启动脚本
COPY start.sh /root/start.sh
RUN chmod +x /root/start.sh

# 配置cron任务
RUN echo "0 0 * * * /root/.acme.sh/acme.sh --cron --home /root/.acme.sh > /dev/null" | crontab -

# 暴露卷
VOLUME ["/acme-certs"]

# 设置环境变量，这些是默认值，可以在运行容器时覆盖
ENV DOMAIN="example.com" \
    DNS_API="dns_cf" \
    DNS_API_KEY="your-api-key" \
    DNS_API_SECRET="your-api-secret" \
    RENEW_DAYS=30 \
    CERT_EMAIL="my@example.com" \
    CERT_KEYLENGTH=2048

# 设置时区
ENV TZ=UTC

# 运行启动脚本
CMD ["/root/start.sh"]