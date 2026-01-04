# FlutterforShopware

Shopware 6 ile entegre Flutter mobil uygulaması. Dynamic Widget kullanarak CMS içeriklerini dinamik olarak yönetir.

## Özellikler

- **Dynamic Layout**: Shopware CMS'den gelen JSON layout'ları dinamik olarak render etme
- **Ürün Kataloğu**: Ürün listesi, detay ve arama
- **Kategori Navigasyonu**: Hiyerarşik kategori yapısı
- **Responsive Design**: Modern ve kullanıcı dostu arayüz
- **Cache Sistemi**: Performans optimizasyonu

## Kurulum

### Gereksinimler

- Flutter SDK 3.0+
- Dart 3.0+
- Shopware 6.6+

### Adımlar

1. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

2. **Konfigürasyonu yapın:**
`lib/core/config/app_config.dart` dosyasını ExpertiveFlutterApp uç noktalarına göre düzenleyin:

```dart
static const String shopwareBaseUrl = 'http://localhost/shopware67/public/';
static const String salesChannelAccessKey = 'SWSCA...';
static const String layoutEndpoint = '/store-api/flutter/layout';
static const String productsEndpoint = '/store-api/flutter/products';
static const String categoriesEndpoint = '/store-api/flutter/categories';
static const String defaultHomePageId = 'YOUR_CMS_PAGE_ID';

`lib/core/api_client.dart` otomatik olarak `sw-context-token` başlığını ekler. Giriş yaptıktan sonra token `SharedPreferences` içinde saklanır ve tüm Store API isteklerinde kullanılır.
```

3. **Uygulamayı çalıştırın:**
```bash
flutter run
```

## Proje Yapısı

```
lib/
├── main.dart                 # Uygulama giriş noktası
├── core/
│   ├── config/              # Konfigürasyon dosyaları
│   ├── models/              # Veri modelleri
│   └── services/            # API servisleri
├── screens/                 # Uygulama ekranları
├── widgets/                 # Özel widget'lar
│   └── custom_parsers/      # Dynamic widget parser'ları
└── assets/                  # Resim ve ikon dosyaları
```

## API Entegrasyonu

### Shopware API Client

```dart
final api = ShopwareApi();

// Layout yükleme
final layout = await api.getLayout('page-id');

// Ürün listesi
final products = await api.getProducts(categoryId: 'category-id');

// Kategori listesi
final categories = await api.getCategories(parentId: 'parent-id');
```

### Dynamic Widget Parser'ları

Özel widget parser'ları kaydetme:

```dart
// main.dart
ProductSliderParser.register();
ProductGridParser.register();
CategoryListParser.register();
```

## Ekranlar

### HomeScreen
- CMS layout'unu dinamik olarak render eder
- Ana sayfa içeriğini gösterir

### CategoryScreen
- Kategori listesi ve ürünleri gösterir
- Hiyerarşik navigasyon

### ProductDetailScreen
- Ürün detay bilgileri
- Sepete ekleme ve satın alma

### SearchScreen
- Ürün arama
- Filtreleme ve sıralama

## Custom Widget'lar

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

Riverpod kullanılarak state management yapılır:

```dart
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final api = ref.read(shopwareApiProvider);
  return api.getProducts();
});
```

## Styling

Material Design 3 kullanılır. Tema konfigürasyonu:

```dart
ThemeData(
  primarySwatch: Colors.blue,
  useMaterial3: true,
  // ...
)
```

## Navigation

Go Router kullanılarak navigation yönetimi:

```dart
GoRoute(
  path: '/product/:productId',
  builder: (context, state) {
    final productId = state.pathParameters['productId']!;
    return ProductDetailScreen(productId: productId);
  },
)
```

## Build ve Deploy

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## Test

```bash
# Unit testler
flutter test

# Integration testler
flutter drive --target=test_driver/app.dart
```

## Troubleshooting

### API Bağlantı Sorunları
- Shopware URL'sinin doğru olduğundan emin olun
- Sales Channel Access Key'in geçerli olduğunu kontrol edin
- Network bağlantısını kontrol edin

### Widget Render Sorunları
- JSON formatının doğru olduğundan emin olun
- Custom parser'ların kayıtlı olduğunu kontrol edin
- Debug modunda çalıştırın

### Performance Sorunları
- Cache ayarlarını kontrol edin
- Image loading optimizasyonlarını uygulayın
- ListView lazy loading kullanın

## Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## Lisans

MIT License

## İletişim

Sorularınız için: info@expertive.com
