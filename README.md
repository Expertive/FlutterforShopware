# FlutterforShopware

Flutter mobile application integrated with Shopware 6. Dynamically manages CMS content using Dynamic Widget.

## Features

- **Dynamic Layout**: Dynamically render JSON layouts from Shopware CMS
- **Product Catalog**: Product list, details, and search
- **Category Navigation**: Hierarchical category structure
- **Responsive Design**: Modern and user-friendly interface
- **Cache System**: Performance optimization

## Installation

### Requirements

- Flutter SDK 3.0+
- Dart 3.0+
- Shopware 6.6+

### Steps

1. **Install dependencies:**
```bash
flutter pub get
```

2. **Configure the application:**
Edit the `lib/core/config/app_config.dart` file according to ExpertiveMobileAppConnector endpoints:

```dart
static const String shopwareBaseUrl = 'http://localhost/shopware67/public/';
static const String salesChannelAccessKey = 'SWSCA...';
static const String layoutEndpoint = '/store-api/flutter/layout';
static const String productsEndpoint = '/store-api/product';
static const String categoriesEndpoint = '/store-api/category';
static const String defaultHomePageId = 'YOUR_CMS_PAGE_ID';

`lib/core/api_client.dart` automatically adds the `sw-context-token` header. After login, the token is stored in `SharedPreferences` and used in all Store API requests.
```

3. **Run the application:**
```bash
flutter run --dart-define=SHOPWARE_ACCESS_KEY=xx

```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── core/
│   ├── config/              # Configuration files
│   ├── models/              # Data models
│   └── services/            # API services
├── screens/                 # Application screens
├── widgets/                 # Custom widgets
│   └── custom_parsers/      # Dynamic widget parsers
└── assets/                  # Images and icon files
```

## API Integration

### Shopware API Client

```dart
final api = ShopwareApi();

// Load layout
final layout = await api.getLayout('page-id');

// Product list
final products = await api.getProducts(categoryId: 'category-id');

// Category list
final categories = await api.getCategories(parentId: 'parent-id');
```

### Dynamic Widget Parsers

Register custom widget parsers:

```dart
// main.dart
ProductSliderParser.register();
ProductGridParser.register();
CategoryListParser.register();
```

## Screens

### HomeScreen
- Dynamically renders CMS layout
- Displays home page content

### CategoryScreen
- Shows category list and products
- Hierarchical navigation

### ProductDetailScreen
- Product detail information
- Add to cart and purchase

### SearchScreen
- Product search
- Filtering and sorting

## Custom Widgets

### ProductSlider
```dart
{
  "type": "ProductSlider",
  "products": [...],
  "height": 250.0
}
```

### ProductGrid
```dart
{
  "type": "ProductGrid",
  "products": [...],
  "crossAxisCount": 2
}
```

### CategoryList
```dart
{
  "type": "CategoryList",
  "categories": [...]
}
```

## State Management

State management is handled using Riverpod:

```dart
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final api = ref.read(shopwareApiProvider);
  return api.getProducts();
});
```

## Styling

Material Design 3 is used. Theme configuration:

```dart
ThemeData(
  primarySwatch: Colors.blue,
  useMaterial3: true,
  // ...
)
```

## Navigation

Navigation is managed using Go Router:

```dart
GoRoute(
  path: '/product/:productId',
  builder: (context, state) {
    final productId = state.pathParameters['productId']!;
    return ProductDetailScreen(productId: productId);
  },
)
```

## Build and Deploy

### Android

```bash
flutter build apk --release --dart-define=SHOPWARE_ACCESS_KEY=XX
```

### iOS

```bash
flutter build ios --release --dart-define=SHOPWARE_ACCESS_KEY=XX
```

## Testing

```bash
# Unit tests
flutter test --dart-define=SHOPWARE_ACCESS_KEY=XX

# Integration tests
flutter drive --target=test_driver/app.dart
```

## Troubleshooting

### API Connection Issues
- Make sure the Shopware URL is correct
- Verify that the Sales Channel Access Key is valid
- Check the network connection

### Widget Render Issues
- Ensure the JSON format is correct
- Verify that custom parsers are registered
- Run in debug mode

### Performance Issues
- Check cache settings
- Apply image loading optimizations
- Use ListView lazy loading

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License

## Contact

For questions: info@expertive.de
