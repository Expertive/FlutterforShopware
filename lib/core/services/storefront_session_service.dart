import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';

import '../utils/storefront_url.dart';

/// Keeps the in-app WebView storefront session in sync with Store API login.
class StorefrontSessionService {
  StorefrontSessionService._();

  static final StorefrontSessionService instance =
      StorefrontSessionService._();

  /// Logs into the Shopware storefront inside a background WebView so checkout
  /// pages reuse the same session cookies.
  Future<bool> syncLogin({
    required String email,
    required String password,
  }) async {
    if (kIsWeb) return false;

    final completer = Completer<bool>();
    var loginSubmitted = false;
    Timer? timeoutTimer;

    late final WebViewController controller;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            if (completer.isCompleted) return;

            if (_isLoginPage(url) && !loginSubmitted) {
              loginSubmitted = true;
              final result = await _submitLoginForm(
                controller,
                email: email,
                password: password,
              );
              if (result == 'fields_not_found' && !completer.isCompleted) {
                completer.complete(false);
              }
              return;
            }

            if (loginSubmitted &&
                !_isLoginPage(url) &&
                !_isLogoutPage(url)) {
              if (!completer.isCompleted) completer.complete(true);
            }
          },
          onWebResourceError: (_) {
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );

    timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (!completer.isCompleted) completer.complete(false);
    });

    try {
      await controller.loadRequest(Uri.parse(StorefrontUrl.accountLogin()));
      return await completer.future;
    } catch (_) {
      return false;
    } finally {
      timeoutTimer.cancel();
    }
  }

  Future<void> clearSession() async {
    if (kIsWeb) return;

    final cookieManager = WebViewCookieManager();
    await cookieManager.clearCookies();

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.loadRequest(Uri.parse(StorefrontUrl.accountLogout()));
    } catch (_) {
      // Logout page is best-effort.
    }
  }

  WebViewController createController(String initialUrl) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(initialUrl));
  }

  bool _isLoginPage(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.path.contains('account/login');
  }

  bool _isLogoutPage(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.path.contains('account/logout');
  }

  Future<String> _submitLoginForm(
    WebViewController controller, {
    required String email,
    required String password,
  }) async {
    final escapedEmail = _escapeJs(email);
    final escapedPassword = _escapeJs(password);
    final result = await controller.runJavaScriptReturningResult('''
      (function() {
        const username = document.querySelector('input[name="username"]')
          || document.querySelector('input[name="login[username]"]')
          || document.querySelector('input[type="email"]');
        const pass = document.querySelector('input[name="password"]')
          || document.querySelector('input[name="login[password]"]')
          || document.querySelector('input[type="password"]:not([hidden])');
        if (!username || !pass) return 'fields_not_found';
        username.value = '$escapedEmail';
        pass.value = '$escapedPassword';
        username.dispatchEvent(new Event('input', { bubbles: true }));
        pass.dispatchEvent(new Event('input', { bubbles: true }));
        const form = username.closest('form');
        if (!form) return 'form_not_found';
        form.submit();
        return 'submitted';
      })();
    ''');

    return result.toString().replaceAll('"', '');
  }

  String _escapeJs(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r');
}
