# FlutterforShopware

Flutter mobile application integrated with Shopware 6 via ExpertiveMobileAppConnector.

## Requirements

- Flutter SDK 3.0+
- Dart 3.0+
- Shopware 6.6+ with ExpertiveMobileAppConnector plugin

## Configuration

Configuration is passed at build time via `--dart-define` (recommended for production).

| Variable | Description |
|----------|-------------|
| `SHOPWARE_BASE_URL` | Shopware public URL (must end with `/`) |
| `SHOPWARE_SALES_CHANNEL_ID` | Mobile sales channel UUID (32 hex chars) |
| `MOBILE_APP_SECRET` | Shared secret from plugin config (per sales channel) |

Copy `lib/core/config/app_config.example.dart` to `lib/core/config/app_config.dart` for local development, or use dart-define only.

### Shopware Admin setup

1. Extensions → Mobile App Connector → Configure
2. Select your mobile sales channel in the top selector
3. Enable **Mobile App Active**
4. Set **Mobile App Secret** (same value as `MOBILE_APP_SECRET` in the app build)
5. Configure CMS pages, colors, logo

## Run (development)

```bash
cd FlutterforShopware
flutter pub get

flutter run \
  --dart-define=SHOPWARE_BASE_URL=https://your-shop.com/ \
  --dart-define=SHOPWARE_SALES_CHANNEL_ID=your32charhexsaleschannelid \
  --dart-define=MOBILE_APP_SECRET=your-secret
```

VS Code: set the same values in `.vscode/launch.json` under `toolArgs`.

## Production build

### Android APK

```bash
flutter build apk --release \
  --dart-define=SHOPWARE_BASE_URL=https://your-shop.com/ \
  --dart-define=SHOPWARE_SALES_CHANNEL_ID=your32charhexsaleschannelid \
  --dart-define=MOBILE_APP_SECRET=your-secret
```

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release \
  --dart-define=SHOPWARE_BASE_URL=https://your-shop.com/ \
  --dart-define=SHOPWARE_SALES_CHANNEL_ID=your32charhexsaleschannelid \
  --dart-define=MOBILE_APP_SECRET=your-secret
```

### iOS

```bash
flutter build ios --release \
  --dart-define=SHOPWARE_BASE_URL=https://your-shop.com/ \
  --dart-define=SHOPWARE_SALES_CHANNEL_ID=your32charhexsaleschannelid \
  --dart-define=MOBILE_APP_SECRET=your-secret
```

> **Note:** `SHOPWARE_ACCESS_KEY` is no longer required. The access key is fetched automatically at startup via `/store-api/flutter/bootstrap`.

## Project structure

```
lib/
├── main.dart
├── core/
│   ├── config/          # App configuration
│   ├── models/
│   ├── services/        # API & layout services
│   └── api_client.dart
├── screens/
├── widgets/
└── data/repositories/
```

## Troubleshooting

| Issue | Check |
|-------|--------|
| "Unable to connect" on startup | Sales channel ID, secret, and Mobile App Active in admin |
| Empty home page | Home CMS page configured in plugin for that sales channel |
| API errors | `SHOPWARE_BASE_URL` must be HTTPS in production |

## License

MIT License
