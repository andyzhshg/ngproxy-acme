FROM nginx:alpine

# 安装必要的工具
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    inotify-tools \
    openssl \
    supervisor

# 创建必要的目录
RUN mkdir -p /etc/nginx/conf.d \
    /etc/nginx/sites-available \
    /etc/nginx/sites-enabled \
    /etc/nginx/templates \
    /var/log/supervisor \
    /var/www/html \
    /certs \
    /config

# 删除默认配置
RUN rm -f /etc/nginx/conf.d/default.conf

# 复制配置文件
COPY nginx.conf /etc/nginx/nginx.conf
COPY templates /etc/nginx/templates
COPY scripts /opt/scripts
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 添加执行权限
RUN chmod +x /opt/scripts/*.sh

# 暴露端口
EXPOSE 80 443

# 设置工作目录
WORKDIR /opt/scripts

# 卷配置
VOLUME ["/config", "/certs"]

# 设置entrypoint
ENTRYPOINT ["/opt/scripts/entrypoint.sh"]

# 默认命令
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"] 