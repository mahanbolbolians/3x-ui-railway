# 🚀 Complete Deployment Guide: 3x-ui (Sanaei Panel) on Railway

This guide walks you through deploying your own 24/7 high-speed **3x-ui (Sanaei) Panel** on **Railway** with ready-to-use **VLESS / VMess / Trojan WebSocket** configs.

---

## 📌 Why This Setup is Special

Standard 3x-ui on a VPS requires opening multiple TCP ports. On **Railway**, all external incoming traffic is handled over **HTTPS / TLS port 443** on a single assigned container port (`$PORT`).

This repository includes an **intelligent internal Nginx reverse-proxy & multiplexer** that maps:
1. **`https://your-app.up.railway.app`** ➔ Full 3x-ui Web Admin Panel (Port 2053)
2. **`https://your-app.up.railway.app/quick-config`** ➔ Visual configuration & QR code portal
3. **`https://your-app.up.railway.app/vless-ws`** ➔ VLESS WebSocket proxy (Port 10001)
4. **`https://your-app.up.railway.app/vmess-ws`** ➔ VMess WebSocket proxy (Port 10002)
5. **`https://your-app.up.railway.app/trojan-ws`** ➔ Trojan WebSocket proxy (Port 10003)
6. **`https://your-app.up.railway.app/sub`** ➔ 3x-ui client subscription feeds

---

## 🛠️ Step 1: Put the Files on GitHub

1. Go to **[github.com](https://github.com)** and create a new repository (e.g., `3x-ui-railway`). Make it **Public** or **Private**.
2. Upload the files from the `3x-ui-railway` folder:
   - `Dockerfile`
   - `entrypoint.sh`
   - `nginx.conf.template`
   - `quick-config.template.html`
   - `railway.json`
   - `README.md`
3. Commit and push the files to your repository.

---

## ☁️ Step 2: Deploy to Railway

1. Go to **[railway.com](https://railway.com)** and sign in with GitHub.
2. Click **+ New Project**.
3. Choose **Deploy from GitHub repo**.
4. Select your `3x-ui-railway` repository.
5. Click **Deploy Now**.
   *(Railway will build the Docker image in about 1 to 2 minutes).*

---

## 🌐 Step 3: Generate Public Domain & Pick Region

1. Click on the newly deployed service card to open its settings.
2. Go to the **Settings** tab:
   - Under **Networking**, click **Generate Domain**.
   - Railway will assign a public domain, such as: `3x-ui-production-xxxx.up.railway.app`.
3. Under **General / Service Settings**:
   - Change **Region** to **Europe (Amsterdam / Netherlands)**.
   - *(Amsterdam provides the best routing, lowest latency, and most stable pings to Iran and the Middle East).*
4. Click **Redeploy** if prompted.

---

## 🔒 Step 4: Optional Security & Custom Variables

In the service card, click the **Variables** tab. You can add:

```env
XUI_USERNAME=myadmin
XUI_PASSWORD=SuperSecretPass123!
```

> **Optional**: To persist data permanently across redeployments, click **+ New** ➔ **Volume**, set the mount path to `/etc/x-ui`, and attach it to your service.

---

## 📱 Step 5: Get Your Configs & Connect

You have 3 easy ways to get your configs:

### Option A: Check Railway Deploy Logs (Instant)
1. Go to the **Deploy Logs** tab in Railway.
2. Look at the end of the log output. You will see:
   ```text
   ============================================================
   🎉 ZEUS 3X-UI PANEL IS READY AND RUNNING ON RAILWAY!
   ============================================================
   🌐 Web Admin Panel:     https://your-app.up.railway.app/
   👤 Username:            admin
   🔑 Password:            admin
   📱 Quick Config Portal: https://your-app.up.railway.app/quick-config
   ------------------------------------------------------------
   🚀 READY-TO-USE CONFIGS (PORT 443 TLS/WEBSOCKET):
   ------------------------------------------------------------
   ▶ [VLESS WebSocket]:
   vless://<UUID>@your-app.up.railway.app:443?type=ws&security=tls&path=%2Fvless-ws&sni=your-app.up.railway.app#Zeus-Railway-VLESS

   ▶ [VMess WebSocket]:
   vmess://ey...

   ▶ [Trojan WebSocket]:
   trojan://<PASSWORD>@your-app.up.railway.app:443?type=ws&security=tls&path=%2Ftrojan-ws&sni=your-app.up.railway.app#Zeus-Railway-Trojan
   ```
3. Copy any of the links and import into your client!

### Option B: Quick Config Web Portal
Open `https://your-app.up.railway.app/quick-config` in your browser:
- Click **Copy Link** for 1-click clipboard copy.
- Click **QR Code** to scan directly from your phone!

### Option C: 3x-ui Web Panel
Open `https://your-app.up.railway.app`:
- Login with your username and password.
- You will see the inbounds table with real-time download and upload traffic, user creation, QR codes, and full 3x-ui management features!

---

## ⚙️ Client Configuration Details (Manual Setup)

If entering manually into v2rayNG, V2RayN, Streisand, or Nekoray:

| Field | VLESS Value | VMess Value | Trojan Value |
| :--- | :--- | :--- | :--- |
| **Address (Host)** | `your-app.up.railway.app` | `your-app.up.railway.app` | `your-app.up.railway.app` |
| **Port** | `443` | `443` | `443` |
| **UUID / Password** | Your VLESS UUID | Your VMess UUID | Your Trojan Password |
| **Transport / Network** | `ws` (WebSocket) | `ws` (WebSocket) | `ws` (WebSocket) |
| **Path** | `/vless-ws` | `/vmess-ws` | `/trojan-ws` |
| **Host Header** | `your-app.up.railway.app` | `your-app.up.railway.app` | `your-app.up.railway.app` |
| **Security / TLS** | `tls` | `tls` | `tls` |
| **SNI** | `your-app.up.railway.app` | `your-app.up.railway.app` | `your-app.up.railway.app` |
| **ALPN** | `http/1.1` | `http/1.1` | `http/1.1` |

---

## 🇮🇷 راهنمای اتصال برای کاربران ایران (Bypassing Heavy Censorship)

### 1. استفاده از کلودفلر (Cloudflare CDN)
اگر اپراتور شما (همراه اول، ایرانسل یا رایتل) دامنه‌های مستقیم Railway را کند یا فیلتر کرده باشد:
1. یک دامنه شخصی (مثلاً `sub.yourdomain.com`) را در کلودفلر ثبت کرده و CNAME آن را به آدرس ریلوِی (`your-app.up.railway.app`) وصل کنید.
2. پراکسی (ابر نارنجی 🟠) را **روشن (Proxied)** بگذارید.
3. در تنظیمات کلاینت:
   - **Host / SNI**: نام دامنه شما (`sub.yourdomain.com`).
   - **Address (IP)**: از یک **آی‌پی تمیز کلودفلر (Clean IP)** مخصوص اپراتور خود استفاده کنید.
   - با این روش، ترافیک بدون هیچ اختلالی از سرورهای CDN کلودفلر رد شده و به ریلوِی می‌رسد.

### 2. بهترین پروتکل
- **VLESS-WS**: سبک‌ترین و باثبات‌ترین پروتکل برای اتصالات وب‌سوکت.
- پینگ پایدار به دلیل انتخاب دیتاسنتر آمستردام (Amsterdam).
