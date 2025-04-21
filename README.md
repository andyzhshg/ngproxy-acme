# 带有证书自动更新功能的反向代理服务

## 证书更新服务

```bash
docker run --rm \
    --name acme.sh \
    -v $PWD:/acme-certs \
    -e CERT_EMAIL=me@example.com \
    -e DOMAIN=example.com \
    -e DNS_API=dns_name \
    -e DNS_API_KEY=xxx \
    -e DNS_API_SECRET=xxx \
    acme:latest
```

## 反向代理服务

```bash
docker run --rm \
    --name ngproxy \
    -v cert_root:/certs \
    -v config_root:/config \
    -p 443:443 \
    ngproxy:latest
```
