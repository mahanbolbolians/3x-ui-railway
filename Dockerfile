# ==============================================================================
# 3x-ui (Sanaei Panel) on Railway - Production Docker Image
# Multi-protocol Xray VPN Panel with Nginx WebSocket Reverse Proxy
# ==============================================================================
FROM ghcr.io/mhsanaei/3x-ui:latest

# Switch to root to install dependencies and configure networking
USER root

# Install Nginx, envsubst (gettext), SQLite, curl, bash, jq, openssl, and qrencode
RUN apk add --no-cache --update \
    nginx \
    gettext \
    sqlite \
    curl \
    bash \
    jq \
    openssl \
    ca-certificates \
    tzdata

# Create necessary directories for Nginx and configs
RUN mkdir -p /etc/nginx/templates \
    /var/log/nginx \
    /var/lib/nginx/tmp \
    /var/www \
    /etc/x-ui

# Copy Nginx template and entrypoint
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY quick-config.template.html /var/www/quick-config.template.html
COPY entrypoint.sh /app/railway-entrypoint.sh

# Make entrypoint script executable
RUN chmod +x /app/railway-entrypoint.sh

# Set environment defaults for Railway
ENV TZ=Asia/Tehran \
    XUI_IN_DOCKER="true" \
    XUI_MAIN_FOLDER="/app" \
    XUI_ENABLE_FAIL2BAN="false" \
    PORT=8080 \
    XUI_PORT=2053 \
    XUI_USERNAME=admin \
    XUI_PASSWORD=admin \
    XUI_BASE_PATH=/ \
    VLESS_PATH=/vless-ws \
    VMESS_PATH=/vmess-ws \
    TROJAN_PATH=/trojan-ws \
    SS_PATH=/ss-ws

# Expose Railway container port and internal 3x-ui port
EXPOSE 8080 2053

# Set our custom orchestrator entrypoint
ENTRYPOINT [ "/bin/bash", "/app/railway-entrypoint.sh" ]
