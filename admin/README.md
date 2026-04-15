# Stock AI Scanner - PHP Admin Panel

A modern, responsive PHP admin panel for managing the Stock AI Scanner Flutter app.

**Live Domain:** `https://smartpricetracker.in/appadmin`

## Features

- **Dashboard** - Overview of all app statistics
- **Video Management** - Add, edit, and delete tutorial videos
- **AdMob Settings** - Configure all ad types (Banner, Native, Interstitial, Rewarded, App Open)
- **In-App Purchases** - Manage subscription plans and credits (Native StoreKit / Play Billing)
- **Push Notifications** - Send notifications via OneSignal with templates
- **User Management** - View users, add credits, manage premium status
- **App Settings** - Remote configuration, maintenance mode, force update
- **Gemini AI Config** - Set API key and model from admin panel (synced to Firebase)

## Requirements

- PHP 7.4 or higher
- cURL extension enabled
- Web server (Apache/Nginx) or XAMPP/WAMP/MAMP
- Firebase Realtime Database
- OneSignal account (for push notifications)

## Installation

### 1. Setup Web Server

Copy the `admin_panel_php` folder to your web server's document root:

- **XAMPP**: `C:\xampp\htdocs\admin_panel_php`
- **WAMP**: `C:\wamp64\www\admin_panel_php`
- **MAMP**: `/Applications/MAMP/htdocs/admin_panel_php`
- **Linux**: `/var/www/html/admin_panel_php`

### 2. Configure Firebase

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Project Settings** > **Service accounts**
4. Generate a new private key (download JSON file)
5. Copy the JSON file to `config/firebase-service-account.json`
6. Update `config/config.php`:

```php
define('FIREBASE_PROJECT_ID', 'your-actual-project-id');
define('FIREBASE_DATABASE_URL', 'https://your-project-id-default-rtdb.firebaseio.com');
define('FIREBASE_API_KEY', 'your-firebase-api-key');
```

### 3. Configure OneSignal

1. Go to [OneSignal Dashboard](https://onesignal.com)
2. Select your app
3. Go to **Settings** > **Keys & IDs**
4. Copy the App ID and REST API Key
5. Update `config/config.php`:

```php
define('ONESIGNAL_APP_ID', 'your-onesignal-app-id');
define('ONESIGNAL_REST_API_KEY', 'your-onesignal-rest-api-key');
```

### 4. Change Admin Credentials

Update admin login credentials in `config/config.php`:

```php
define('ADMIN_USERNAME', 'your_admin_username');
define('ADMIN_PASSWORD', 'your_secure_password');
```

**Note**: For production, use password hashing instead of plain text passwords.

### 6. Set Permissions

Make sure the web server can read all files:

```bash
chmod -R 755 admin_panel_php/
```

## Usage

### Access Admin Panel

1. Open your browser
2. Navigate to `http://localhost/admin_panel_php`
3. Login with your admin credentials

### Default Login

- **Username**: admin
- **Password**: admin123

**Important**: Change these credentials before deploying to production!

## API Endpoints

The admin panel includes REST API endpoints for mobile app integration:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/videos.php` | GET | Get all videos |
| `/api/videos.php` | POST | Add new video |
| `/api/videos.php` | PUT | Update video |
| `/api/videos.php` | DELETE | Delete video |
| `/api/ads.php` | GET | Get ad configuration |
| `/api/ads.php` | PUT | Update ad configuration |
| `/api/iap.php` | GET | Get IAP configuration |
| `/api/iap.php` | PUT | Update IAP configuration |
| `/api/notifications.php` | GET | Get notification history |
| `/api/notifications.php` | POST | Send notification |
| `/api/settings.php` | GET | Get app settings |
| `/api/api_config.php` | GET | Get API config (Gemini key, etc.) |
| `/api/users.php` | GET | Get user by ID |
| `/api/users.php` | POST | Add credits to user |
| `/api/users.php` | PUT | Update user premium status |

### Example API Usage

```bash
# Get all videos
curl -X GET http://localhost/admin_panel_php/api/videos.php

# Add a video
curl -X POST http://localhost/admin_panel_php/api/videos.php \
  -H "Content-Type: application/json" \
  -d '{"title":"Tutorial 1","sub_title":"Getting Started","video_url":"https://youtube.com/..."}'

# Send notification
curl -X POST http://localhost/admin_panel_php/api/notifications.php \
  -H "Content-Type: application/json" \
  -d '{"title":"Hello","message":"This is a test notification","segment":"All"}'
```

## Folder Structure

```
admin_panel_php/
├── api/
│   ├── ads.php
│   ├── api_config.php
│   ├── iap.php
│   ├── notifications.php
│   ├── settings.php
│   ├── users.php
│   └── videos.php
├── config/
│   ├── config.php
│   ├── firebase.php
│   └── onesignal.php
├── includes/
│   ├── footer.php
│   ├── header.php
│   └── sidebar.php
├── .htaccess
├── ads.php
├── iap.php
├── index.php
├── login.php
├── logout.php
├── notifications.php
├── settings.php
├── users.php
├── videos.php
└── README.md
```

## Domain Deployment (smartpricetracker.in/appadmin)

### 1. Upload Files

Upload the `admin_panel_php` folder contents to your server at:
```
/public_html/appadmin/
```

### 2. Set Permissions

```bash
chmod 755 /public_html/appadmin/
chmod 644 /public_html/appadmin/*.php
chmod 600 /public_html/appadmin/config/*.php
```

### 3. Update Config

Edit `config/config.php`:
```php
define('SITE_URL', 'https://smartpricetracker.in/appadmin');
```

### 4. SSL Certificate

Ensure SSL is enabled for `smartpricetracker.in`. Most hosting providers offer free Let's Encrypt certificates.

### 5. Test Access

Visit: `https://smartpricetracker.in/appadmin/login.php`

## Firebase Database Structure

The admin panel uses the following Firebase Realtime Database structure:

```json
{
  "videos": {
    "-NxxxxXXXX": {
      "title": "Video Title",
      "sub_title": "Video Subtitle",
      "video_url": "https://youtube.com/..."
    }
  },
  "ad_config": {
    "showBannerAd": true,
    "showNativeAd": true,
    "bannerAdId": "ca-app-pub-xxx/xxx",
    "nativeAdId": "ca-app-pub-xxx/xxx",
    "interstitialAdId": "ca-app-pub-xxx/xxx",
    "rewardedAdId": "ca-app-pub-xxx/xxx",
    "appOpenAdId": "ca-app-pub-xxx/xxx",
    "interstitialCooldownSeconds": 30,
    "appOpenCooldownSeconds": 30
  },
  "api_config": {
    "geminiApiKey": "AIzaSy...",
    "geminiModel": "gemini-2.5-flash",
    "analysisPrompt": "",
    "supportEmail": "support@example.com",
    "playStoreUrl": "https://play.google.com/...",
    "appStoreUrl": "https://apps.apple.com/...",
    "privacyPolicyUrl": "https://example.com/privacy",
    "termsOfServiceUrl": "https://example.com/terms"
  },
  "iap_config": {
    "enableIAP": true,
    "freeCredits": 5,
    "creditsPerAnalysis": 1,
    "showUpgradePrompt": true,
    "subscription_plans": {
      "weekly": {"productId": "weekly_plan", "price": "₹99", "bonusCredits": 5},
      "monthly": {"productId": "monthly_plan", "price": "₹199", "bonusCredits": 25},
      "quarterly": {"productId": "quarterly_plan", "price": "₹499", "bonusCredits": 50}
    }
  },
  "app_settings": {
    "appName": "Stock AI Scanner",
    "appVersion": "1.0.0",
    "maintenanceMode": false,
    "maintenanceMessage": "",
    "forceUpdateVersion": ""
  },
  "users": {
    "userId123": {
      "email": "user@example.com",
      "credits": 50,
      "isPremium": true,
      "createdAt": 1234567890000
    }
  }
}
```

## Security Recommendations

1. **Change default credentials** before deploying
2. **Use HTTPS** in production
3. **Implement rate limiting** for API endpoints
4. **Add API authentication** for production use
5. **Restrict Firebase rules** to allow only admin access
6. **Keep PHP and dependencies updated**

## Troubleshooting

### "cURL error" when saving data

Make sure cURL extension is enabled in PHP:

```php
extension=curl
```

### Firebase connection issues

1. Check if your Firebase database URL is correct
2. Verify Firebase rules allow read/write access
3. Check if your service account key is valid

### OneSignal notifications not sending

1. Verify your OneSignal App ID and API Key
2. Check if your app has subscribed users
3. Review OneSignal dashboard for error logs

## Support

For issues or feature requests, please create an issue in the repository.

## License

This project is proprietary software for Stock AI Scanner app.
