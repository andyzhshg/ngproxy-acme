FROM nginx:alpine

RUN apk add tzdata \
 && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
 && echo "Asia/Shanghai" > /etc/timezone

RUN apk add --no-cache curl bash busybox-suid cronie

COPY reload-nginx.sh /reload-nginx.sh
COPY nginx-cron /etc/crontabs/root

RUN chmod +x /reload-nginx.sh
RUN chmod +x /etc/crontabs/root

CMD ["sh", "-c", "nginx && crond -f"]
