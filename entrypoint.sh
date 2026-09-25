#!/bin/bash
set -e

echo "============================================================"
echo "⚡ Starting Zeus 3X-UI Cloud Proxy Engine on Railway..."
echo "============================================================"

# 1. Environment & Default Port Configuration
export PORT="${PORT:-8080}"
export XUI_PORT="${XUI_PORT:-2053}"
export XUI_USERNAME="${XUI_USERNAME:-admin}"
export XUI_PASSWORD="${XUI_PASSWORD:-admin}"
export XUI_BASE_PATH="${XUI_BASE_PATH:-/}"
export XUI_ENABLE_FAIL2BAN="false"
export XUI_IN_DOCKER="true"
export XUI_MAIN_FOLDER="/app"

# Normalize base path to start and end with / if not empty
if [ "$XUI_BASE_PATH" != "/" ]; then
    [[ "$XUI_BASE_PATH" != /* ]] && XUI_BASE_PATH="/${XUI_BASE_PATH}"
    [[ "$XUI_BASE_PATH" != */ ]] && XUI_BASE_PATH="${XUI_BASE_PATH}/"
fi

# Detect Public Domain
if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
    PUBLIC_DOMAIN="$RAILWAY_PUBLIC_DOMAIN"
elif [ -n "$PUBLIC_DOMAIN" ]; then
    PUBLIC_DOMAIN="$PUBLIC_DOMAIN"
else
    PUBLIC_DOMAIN="localhost"
fi
export PUBLIC_DOMAIN

# Transport Paths
export VLESS_PATH="${VLESS_PATH:-/vless-ws}"
export VMESS_PATH="${VMESS_PATH:-/vmess-ws}"
export TROJAN_PATH="${TROJAN_PATH:-/trojan-ws}"
export SS_PATH="${SS_PATH:-/ss-ws}"

# Generate Credentials if not provided
if [ -z "$VLESS_UUID" ]; then
    VLESS_UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || openssl rand -hex 16 | sed -E 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1-\2-\3-\4-\5/')
fi
if [ -z "$VMESS_UUID" ]; then
    VMESS_UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || openssl rand -hex 16 | sed -E 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1-\2-\3-\4-\5/')
fi
if [ -z "$TROJAN_PASSWORD" ]; then
    TROJAN_PASSWORD=$(openssl rand -hex 8)
fi

export VLESS_UUID VMESS_UUID TROJAN_PASSWORD

echo "🔧 Configuring Nginx on external port ${PORT}..."
# Substitute ONLY specific environment variables so Nginx's internal $variables remain intact!
envsubst '$PORT $VLESS_PATH $VMESS_PATH $TROJAN_PATH $SS_PATH' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Verify Nginx Configuration
nginx -t

# 2. Configure 3x-ui Database / Settings via CLI
echo "🔧 Configuring 3x-ui panel settings (Port: ${XUI_PORT}, BasePath: ${XUI_BASE_PATH})..."
mkdir -p /etc/x-ui
/app/x-ui setting -port "$XUI_PORT" -username "$XUI_USERNAME" -password "$XUI_PASSWORD" -webBasePath "$XUI_BASE_PATH" || true

# 3. Start 3x-ui in Background
echo "🚀 Launching 3x-ui core..."
/app/x-ui &
XUI_PID=$!

# Wait for 3x-ui web server to start responding
echo "⏳ Waiting for 3x-ui web daemon to initialize..."
MAX_WAIT=20
WAIT_COUNT=0
while ! curl -s -f "http://127.0.0.1:${XUI_PORT}${XUI_BASE_PATH}" >/dev/null 2>&1; do
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
        echo "⚠️ Warning: 3x-ui web port took longer than expected to answer. Continuing..."
        break
    fi
done

# 4. Check & Seed Inbounds via 3x-ui Internal API
COOKIE_FILE="/tmp/xui_cookie.txt"
echo "🔑 Authenticating with 3x-ui API..."
LOGIN_RESP=$(curl -s -c "$COOKIE_FILE" -X POST "http://127.0.0.1:${XUI_PORT}${XUI_BASE_PATH}login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${XUI_USERNAME}&password=${XUI_PASSWORD}")

echo "📋 Checking existing inbounds..."
INBOUNDS_RESP=$(curl -s -b "$COOKIE_FILE" -X GET "http://127.0.0.1:${XUI_PORT}${XUI_BASE_PATH}panel/api/inbounds/list")

# Check if inbounds are empty or uninitialized
INBOUND_COUNT=$(echo "$INBOUNDS_RESP" | jq -r '.obj | length' 2>/dev/null || echo "0")

if [ "$INBOUND_COUNT" = "0" ] || [ -z "$INBOUND_COUNT" ] || [ "$INBOUND_COUNT" = "null" ]; then
    echo "✨ Initializing default high-performance WebSocket inbounds..."

    # Inbound 1: VLESS + WebSocket
    echo "   ➕ Adding VLESS WebSocket Inbound (Port: 10001, Path: ${VLESS_PATH})..."
    curl -s -b "$COOKIE_FILE" -X POST "http://127.0.0.1:${XUI_PORT}${XUI_BASE_PATH}panel/api/inbounds/add" \
        -H "Content-Type: application/json" \
        -d "{
            \"up\": 0,
            \"down\": 0,
            \"total\": 0,
            \"remark\": \"Zeus-VLESS-WS\",
            \"enable\": true,
            \"expiryTime\": 0,
            \"listen\": \"127.0.0.1\",
            \"port\": 10001,
            \"protocol\": \"vless\",
            \"settings\": \"{\\\"clients\\\":[{\\\"id\\\":\\\"${VLESS_UUID}\\\",\\\"email\\\":\\\"zeus-vless@railway\\\",\\\"enable\\\":true,\\\"flow\\\":\\\"\\\"}],\\\"decryption\\\":\\\"none\\\",\\\"fallbacks\\\":[]}\",
            \"streamSettings\": \"{\\\"network\\\":\\\"ws\\\",\\\"security\\\":\\\"none\\\",\\\"wsSettings\\\":{\\\"acceptProxyProtocol\\\":false,\\\"path\\\":\\\"${VLESS_PATH}\\\",\\\"headers\\\":{}}}\",
            \"sniffing\": \"{\\\"enabled\\\":true,\\\"destOverride\\\":[\\\"http\\\",\\\"tls\\\",\\\"quic\\\"]}\"
        }" >/dev/null 2>&1 || true

    # Inbound 2: VMess + WebSocket
    echo "   ➕ Adding VMess WebSocket Inbound (Port: 10002, Path: ${VMESS_PATH})..."
    curl -s -b "$COOKIE_FILE" -X POST "http://127.0.0.1:${XUI_PORT}${XUI_BASE_PATH}panel/api/inbounds/add" \
        -H "Content-Type: application/json" \
        -d "{
            \"up\": 0,
            \"down\": 0,
            \"total\": 0,
            \"remark\": \"Zeus-VMESS-WS\",
            \"enable\": true,
            \"expiryTime\": 0,
            \"listen\": \"127.0.0.1\",
            \"port\": 10002,
            \"protocol\": \"vmess\",
            \"settings\": \"{\\\"clients\\\":[{\\\"id\\\":\\\"${VMESS_UUID}\\\",\\\"email\\\":\\\"zeus-vmess@railway\\\",\\\"enable\\\":true,\\\"alterId\\\":0}],\\\"decryption\\\":\\\"none\\\",\\\"fallbacks\\\":[]}\",
            \"streamSettings\": \"{\\\"network\\\":\\\"ws\\\",\\\"security\\\":\\\"none\\\",\\\"wsSettings\\\":{\\\"acceptProxyProtocol\\\":false,\\\"path\\\":\\\"${VMESS_PATH}\\\",\\\"headers\\\":{}}}\",
            \"sniffing\": \"{\\\"enabled\\\":true,\\\"destOverride\\\":[\\\"http\\\",\\\"tls\\\",\\\"quic\\\"]}\"
        }" >/dev/null 2>&1 || true

    # Inbound 3: Trojan + WebSocket
    echo "   ➕ Adding Trojan WebSocket Inbound (Port: 10003, Path: ${TROJAN_PATH})..."
    curl -s -b "$COOKIE_FILE" -X POST "http://127.0.0.1:${XUI_PORT}${XUI_BASE_PATH}panel/api/inbounds/add" \
        -H "Content-Type: application/json" \
        -d "{
            \"up\": 0,
            \"down\": 0,
            \"total\": 0,
            \"remark\": \"Zeus-TROJAN-WS\",
            \"enable\": true,
            \"expiryTime\": 0,
            \"listen\": \"127.0.0.1\",
            \"port\": 10003,
            \"protocol\": \"trojan\",
            \"settings\": \"{\\\"clients\\\":[{\\\"password\\\":\\\"${TROJAN_PASSWORD}\\\",\\\"email\\\":\\\"zeus-trojan@railway\\\",\\\"enable\\\":true}],\\\"fallbacks\\\":[]}\",
            \"streamSettings\": \"{\\\"network\\\":\\\"ws\\\",\\\"security\\\":\\\"none\\\",\\\"wsSettings\\\":{\\\"acceptProxyProtocol\\\":false,\\\"path\\\":\\\"${TROJAN_PATH}\\\",\\\"headers\\\":{}}}\",
            \"sniffing\": \"{\\\"enabled\\\":true,\\\"destOverride\\\":[\\\"http\\\",\\\"tls\\\",\\\"quic\\\"]}\"
        }" >/dev/null 2>&1 || true
    echo "✅ Default inbounds successfully created and loaded into Xray!"
else
    echo "ℹ️ Existing inbounds detected (${INBOUND_COUNT} inbounds found in database). Keeping current configuration."
fi

# 5. Build Client Configuration URLs
# URL encode paths for query strings
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o
    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * ) printf -v o '%%%02X' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}

VLESS_ENC_PATH=$(urlencode "$VLESS_PATH")
TROJAN_ENC_PATH=$(urlencode "$TROJAN_PATH")

VLESS_CONFIG="vless://${VLESS_UUID}@${PUBLIC_DOMAIN}:443?type=ws&security=tls&path=${VLESS_ENC_PATH}&sni=${PUBLIC_DOMAIN}#Zeus-Railway-VLESS"

# Build VMess Base64 JSON
VMESS_JSON=$(cat <<EOF
{
  "v": "2",
  "ps": "Zeus-Railway-VMess",
  "add": "${PUBLIC_DOMAIN}",
  "port": "443",
  "id": "${VMESS_UUID}",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "${PUBLIC_DOMAIN}",
  "path": "${VMESS_PATH}",
  "tls": "tls",
  "sni": "${PUBLIC_DOMAIN}"
}
EOF
)
VMESS_B64=$(echo -n "$VMESS_JSON" | base64 | tr -d '\n')
VMESS_CONFIG="vmess://${VMESS_B64}"

TROJAN_CONFIG="trojan://${TROJAN_PASSWORD}@${PUBLIC_DOMAIN}:443?type=ws&security=tls&path=${TROJAN_ENC_PATH}&sni=${PUBLIC_DOMAIN}#Zeus-Railway-Trojan"

PANEL_URL="https://${PUBLIC_DOMAIN}${XUI_BASE_PATH}"
SUB_URL="https://${PUBLIC_DOMAIN}/sub"

export VLESS_CONFIG VMESS_CONFIG TROJAN_CONFIG PANEL_URL SUB_URL

# 6. Generate Quick-Config HTML Page
if [ -f /var/www/quick-config.template.html ]; then
    envsubst '$PUBLIC_DOMAIN $VLESS_CONFIG $VMESS_CONFIG $TROJAN_CONFIG $PANEL_URL $SUB_URL $VLESS_PATH $VMESS_PATH $TROJAN_PATH' \
        < /var/www/quick-config.template.html > /var/www/quick-config.html
fi

# 7. Start Nginx Reverse Proxy
echo "🌐 Starting Nginx ingress on port ${PORT}..."
nginx -g "daemon off;" &
NGINX_PID=$!

# 8. Output Deployment Banner to Logs
echo ""
echo "============================================================"
echo "🎉 ZEUS 3X-UI PANEL IS READY AND RUNNING ON RAILWAY!"
echo "============================================================"
echo "🌐 Web Admin Panel:     https://${PUBLIC_DOMAIN}${XUI_BASE_PATH}"
echo "👤 Username:            ${XUI_USERNAME}"
echo "🔑 Password:            ${XUI_PASSWORD}"
echo "📱 Quick Config Portal: https://${PUBLIC_DOMAIN}/quick-config"
echo "------------------------------------------------------------"
echo "🚀 READY-TO-USE CONFIGS (PORT 443 TLS/WEBSOCKET):"
echo "------------------------------------------------------------"
echo ""
echo "▶ [VLESS WebSocket]:"
echo "${VLESS_CONFIG}"
echo ""
echo "▶ [VMess WebSocket]:"
echo "${VMESS_CONFIG}"
echo ""
echo "▶ [Trojan WebSocket]:"
echo "${TROJAN_CONFIG}"
echo ""
echo "============================================================"
echo "💡 TIP: Import into v2rayNG / Streisand / Shadowrocket / Nekoray"
echo "============================================================"

# Handle termination gracefully
trap "echo 'Stopping services...'; kill -TERM $XUI_PID $NGINX_PID 2>/dev/null; exit 0" SIGTERM SIGINT

# Keep running
wait -n $XUI_PID $NGINX_PID
