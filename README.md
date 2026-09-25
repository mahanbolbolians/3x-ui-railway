# ⚡ Zeus 3X-UI Cloud Proxy on Railway

Deploy a full **3x-ui (MHSanaei) Panel** running **Xray-core** on [Railway.app](https://railway.com) with 24/7 uptime, automated TLS, and high-performance WebSocket proxy protocols (VLESS, VMess, Trojan).

---

## 🌟 Highlights

- **Full 3x-ui Web UI**: The complete Sanaei web panel interface with real-time graphs, traffic monitor, multi-client management, and quota limits.
- **Unified Single-Port Ingress**: Railway routes port 443 HTTPS directly to an internal Nginx reverse-proxy which multiplexes:
  - 🖥️ Admin Panel & WebSockets on `/` (or custom path)
  - ⚡ VLESS + WebSocket on `/vless-ws`
  - 🛡️ VMess + WebSocket on `/vmess-ws`
  - 🔒 Trojan + WebSocket on `/trojan-ws`
  - 📱 Subscriptions on `/sub`
  - 🚀 Quick Config Portal on `/quick-config`
- **Zero-Configuration Instant Boot**: On first deploy, the container auto-generates credentials, inbounds, and ready-to-copy client URLs directly in your Railway deployment log!
- **Persistent Storage Supported**: Mount `/etc/x-ui` as a Railway Volume to keep all settings, users, and traffic statistics across redeployments.
- **Censorship-Resistant & Cloudflare CDN Compatible**: Standard WSS on port 443 with TLS. Can be fronted with Cloudflare CDN and Clean IPs for high resistance against DPI blocks.

---

## 🚀 2-Minute Quick Deploy on Railway

### 1. Push or Upload to GitHub
1. Create a new GitHub repository (e.g. `3x-ui-railway`).
2. Push all files from this directory to your repository.

### 2. Deploy on Railway
1. Open **[Railway.app](https://railway.com)** and log in.
2. Click **+ New Project** ➔ **Deploy from GitHub repo**.
3. Select your repository (`3x-ui-railway`).
4. Click **Deploy Now**.

### 3. Generate Public Domain & Optimize Region
1. Click on the deployed service box to open its panel.
2. Go to **Settings** ➔ **Networking** ➔ Click **Generate Domain** (e.g. `your-proxy.up.railway.app`).
3. Under **General / Service Settings**, set the **Region** to **Europe (Amsterdam / Netherlands)** for the lowest latency and best routes to Middle East / Europe.

### 4. Optional Environment Variables
In the **Variables** tab, you can customize:

| Variable | Default | Description |
| :--- | :--- | :--- |
| `XUI_USERNAME` | `admin` | Admin panel login username |
| `XUI_PASSWORD` | `admin` | Admin panel login password |
| `XUI_BASE_PATH` | `/` | Web base path (e.g. `/` or `/panel/`) |
| `VLESS_PATH` | `/vless-ws` | WebSocket path for VLESS |
| `VMESS_PATH` | `/vmess-ws` | WebSocket path for VMess |
| `TROJAN_PATH` | `/trojan-ws` | WebSocket path for Trojan |

---

## 📱 How to Get Your Configs

Once deployed:
1. **From Railway Deployment Logs**:
   Click the **Deploy Logs** tab. You will see ready-to-copy `vless://`, `vmess://`, and `trojan://` links printed right on the screen!
2. **From the Quick Config Portal**:
   Open `https://your-domain.up.railway.app/quick-config` in your browser to view your configs and scan QR codes on mobile!
3. **From 3x-ui Admin Panel**:
   Open `https://your-domain.up.railway.app` and log in with your credentials.

---

## 🛠️ Supported Clients

- **Android**: [v2rayNG](https://github.com/2dust/v2rayNG), [NekoBox](https://github.com/MatsuriDayo/NekoBoxForAndroid), [Sing-box](https://github.com/SagerNet/sing-box)
- **iOS**: [Streisand](https://apps.apple.com/app/streisand/id6450534064), [FoXray](https://apps.apple.com/app/foxray/id6448898396), [Shadowrocket](https://apps.apple.com/app/shadowrocket/id932747118)
- **Windows**: [v2rayN](https://github.com/2dust/v2rayN), [Nekoray](https://github.com/MatsuriDayo/nekoray), [Sing-box](https://github.com/SagerNet/sing-box)
- **macOS / Linux**: [Nekoray](https://github.com/MatsuriDayo/nekoray), [V22box](https://github.com/v2rayA/v2rayA)

---

## 🇮🇷 راهنمای استفاده و دور زدن فیلترینگ (Iran DPI Circumvention)

1. **پروتکل پیشنهادی اول**: `VLESS + WebSocket + TLS` (کمترین بار پردازشی و بالاترین سرعت).
2. **پورت**: همیشه پورت را روی `443` و Security را روی `TLS` قرار دهید.
3. **استفاده از آی‌پی تمیز کلودفلر (Clean IP)**:
   اگر به دامنه اصلی ریلوِی متصل نشدید، دامنه را در کلودفلر ثبت کرده (پراکسی ابر نارنجی روشن) و در کلاینت (v2rayNG یا v2rayN):
   - مقدار **Address / IP** را روی یک **IP تمیز کلودفلر** بگذارید.
   - مقدار **Host / SNI** را نام دامنه‌تان قرار دهید.
