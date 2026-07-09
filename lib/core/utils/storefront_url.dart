import '../config/app_config.dart';

/// Builds storefront (non Store-API) URLs from [AppConfig.baseUrl].
class StorefrontUrl {
  StorefrontUrl._();

  static String base() {
    var url = AppConfig.baseUrl.trim();
    if (url.endsWith('/store-api')) {
      url = url.substring(0, url.length - '/store-api'.length);
    }
    url = url.replaceAll(RegExp(r'/+$'), '');
    return '$url/';
  }

  static String accountLogin() => '${base()}account/login';

  static String accountLogout() => '${base()}account/logout';

  static String accountRegister() => '${base()}account/register';

  static String accountRecover() => '${base()}account/recover';

  static String accountProfile() => '${base()}account/profile';

  static String accountPassword() => '${base()}account/profile/password';

  static String accountOrders() => '${base()}account/order';

  static String orderEdit(String orderId) =>
      '${base()}account/order/edit/$orderId';

  static String checkoutCart() => '${base()}checkout/cart';

  static String checkoutConfirm() => '${base()}checkout/confirm';

  static String documentDownload(String documentId, String deepLinkCode) {
    final apiBase = AppConfig.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$apiBase/store-api/document/download/$documentId/$deepLinkCode';
  }
}
