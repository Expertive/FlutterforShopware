import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get navCart;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String commonError(String message);

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get commonTryAgain;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get commonLogin;

  /// No description provided for @commonLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get commonLogout;

  /// No description provided for @commonLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'Logged out'**
  String get commonLoggedOut;

  /// No description provided for @commonRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get commonRegister;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get commonCategories;

  /// No description provided for @commonProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get commonProduct;

  /// No description provided for @commonTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// No description provided for @commonSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get commonSubtotal;

  /// No description provided for @commonShipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get commonShipping;

  /// No description provided for @commonPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get commonPayment;

  /// No description provided for @commonOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get commonOrders;

  /// No description provided for @commonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @cookieTitle.
  ///
  /// In en, this message translates to:
  /// **'Cookie Usage'**
  String get cookieTitle;

  /// No description provided for @cookieMessage.
  ///
  /// In en, this message translates to:
  /// **'This website uses cookies to improve your experience. By continuing to use our site, you agree to our cookie policy.'**
  String get cookieMessage;

  /// No description provided for @cookieDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get cookieDecline;

  /// No description provided for @cookieAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get cookieAccept;

  /// No description provided for @homeContentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Home page content is not available.'**
  String get homeContentUnavailable;

  /// No description provided for @homeLayoutError.
  ///
  /// In en, this message translates to:
  /// **'Layout loading error'**
  String get homeLayoutError;

  /// No description provided for @languageCurrencyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language/Currency updated'**
  String get languageCurrencyUpdated;

  /// No description provided for @languageCurrencyUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Update error: {message}'**
  String languageCurrencyUpdateError(String message);

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @categoriesNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Categories not available'**
  String get categoriesNotAvailable;

  /// No description provided for @categoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Category not found'**
  String get categoryNotFound;

  /// No description provided for @showProductsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show products'**
  String get showProductsTooltip;

  /// No description provided for @unnamedCategory.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Category'**
  String get unnamedCategory;

  /// No description provided for @unknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown Category'**
  String get unknownCategory;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Login'**
  String get loginTitle;

  /// No description provided for @loginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email required'**
  String get loginEmailRequired;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get loginPasswordRequired;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get loginForgotPassword;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessful;

  /// No description provided for @passwordRecovery.
  ///
  /// In en, this message translates to:
  /// **'Password Recovery'**
  String get passwordRecovery;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register New Account'**
  String get registerTitle;

  /// No description provided for @registerEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get registerEmailAddress;

  /// No description provided for @registerNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get registerNewPassword;

  /// No description provided for @registerFirstNameOptional.
  ///
  /// In en, this message translates to:
  /// **'First Name (Optional)'**
  String get registerFirstNameOptional;

  /// No description provided for @registerLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get registerLastName;

  /// No description provided for @registerSalutationId.
  ///
  /// In en, this message translates to:
  /// **'Salutation ID'**
  String get registerSalutationId;

  /// No description provided for @registerEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email address required'**
  String get registerEmailRequired;

  /// No description provided for @registerPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'New password required'**
  String get registerPasswordRequired;

  /// No description provided for @registerFirstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name required'**
  String get registerFirstNameRequired;

  /// No description provided for @registerLastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name required'**
  String get registerLastNameRequired;

  /// No description provided for @registerSalutationRequired.
  ///
  /// In en, this message translates to:
  /// **'Salutation ID required'**
  String get registerSalutationRequired;

  /// No description provided for @registerSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful'**
  String get registerSuccessful;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit: {price}'**
  String cartUnitPrice(String price);

  /// No description provided for @cartLineTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {price}'**
  String cartLineTotal(String price);

  /// No description provided for @cartAppliedDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Applied Discounts'**
  String get cartAppliedDiscounts;

  /// No description provided for @cartDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get cartDiscount;

  /// No description provided for @cartVatPercent.
  ///
  /// In en, this message translates to:
  /// **'VAT ({rate}%)'**
  String cartVatPercent(String rate);

  /// No description provided for @cartExcludingVat.
  ///
  /// In en, this message translates to:
  /// **'Excluding VAT'**
  String get cartExcludingVat;

  /// No description provided for @cartCompleteOrder.
  ///
  /// In en, this message translates to:
  /// **'Complete Order'**
  String get cartCompleteOrder;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @checkoutFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get checkoutFillAllFields;

  /// No description provided for @checkoutLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to create an order.'**
  String get checkoutLoginRequired;

  /// No description provided for @checkoutShippingBlocked.
  ///
  /// In en, this message translates to:
  /// **'This shipping method cannot be used for the selected shipping address. Please select a different address or shipping method.'**
  String get checkoutShippingBlocked;

  /// No description provided for @checkoutOrderCreatedMissingPayment.
  ///
  /// In en, this message translates to:
  /// **'Order created. Required information for payment could not be retrieved.'**
  String get checkoutOrderCreatedMissingPayment;

  /// No description provided for @checkoutOrderCreatedPaymentRetry.
  ///
  /// In en, this message translates to:
  /// **'Your order has been successfully created. Please try again later for payment or contact customer service.'**
  String get checkoutOrderCreatedPaymentRetry;

  /// No description provided for @checkoutPaymentError.
  ///
  /// In en, this message translates to:
  /// **'Payment error: {message}'**
  String checkoutPaymentError(String message);

  /// No description provided for @checkoutPaymentStepFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment step failed.'**
  String get checkoutPaymentStepFailed;

  /// No description provided for @checkoutLoginAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Login and try again.'**
  String get checkoutLoginAndTryAgain;

  /// No description provided for @checkoutShippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get checkoutShippingAddress;

  /// No description provided for @checkoutBillingAddress.
  ///
  /// In en, this message translates to:
  /// **'Billing Address'**
  String get checkoutBillingAddress;

  /// No description provided for @checkoutShippingMethod.
  ///
  /// In en, this message translates to:
  /// **'Shipping Method'**
  String get checkoutShippingMethod;

  /// No description provided for @checkoutPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get checkoutPaymentMethod;

  /// No description provided for @checkoutOrderCreated.
  ///
  /// In en, this message translates to:
  /// **'Order created'**
  String get checkoutOrderCreated;

  /// No description provided for @checkoutOrderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID: {orderId}'**
  String checkoutOrderId(String orderId);

  /// No description provided for @checkoutTransactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID: {transactionId}'**
  String checkoutTransactionId(String transactionId);

  /// No description provided for @checkoutPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status: {status}'**
  String checkoutPaymentStatus(String status);

  /// No description provided for @checkoutOrderCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your order has been successfully created.'**
  String get checkoutOrderCreatedSuccess;

  /// No description provided for @checkoutOrderIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order ID not found'**
  String get checkoutOrderIdNotFound;

  /// No description provided for @checkoutCompletePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Payment'**
  String get checkoutCompletePayment;

  /// No description provided for @checkoutCompleteOrder.
  ///
  /// In en, this message translates to:
  /// **'Complete Order'**
  String get checkoutCompleteOrder;

  /// No description provided for @checkoutRedirectingPayment.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to payment provider...'**
  String get checkoutRedirectingPayment;

  /// No description provided for @checkoutInvalidRedirectUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid redirect URL: {url}'**
  String checkoutInvalidRedirectUrl(String url);

  /// No description provided for @productLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading product information...'**
  String get productLoading;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @productOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get productOutOfStock;

  /// No description provided for @productInStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get productInStock;

  /// No description provided for @productLastOne.
  ///
  /// In en, this message translates to:
  /// **'Last 1 Item'**
  String get productLastOne;

  /// No description provided for @productVariantSelection.
  ///
  /// In en, this message translates to:
  /// **'Variant Selection'**
  String get productVariantSelection;

  /// No description provided for @productOption.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get productOption;

  /// No description provided for @productDescription.
  ///
  /// In en, this message translates to:
  /// **'Product Description'**
  String get productDescription;

  /// No description provided for @productCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get productCategories;

  /// No description provided for @productRelated.
  ///
  /// In en, this message translates to:
  /// **'Related Products'**
  String get productRelated;

  /// No description provided for @productVariantNotFound.
  ///
  /// In en, this message translates to:
  /// **'Variant not found: {message}'**
  String productVariantNotFound(String message);

  /// No description provided for @productAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'{name} added to cart'**
  String productAddedToCart(String name);

  /// No description provided for @productAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get productAddToCart;

  /// No description provided for @categoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading category information...'**
  String get categoryLoading;

  /// No description provided for @categorySubcategories.
  ///
  /// In en, this message translates to:
  /// **'Subcategories'**
  String get categorySubcategories;

  /// No description provided for @categoryProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get categoryProducts;

  /// No description provided for @categoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No products or subcategories found in this category yet.'**
  String get categoryEmpty;

  /// No description provided for @categoryMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get categoryMenu;

  /// No description provided for @categoryNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get categoryNoCategories;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchHint;

  /// No description provided for @searchSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchSearching;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during search. Please try again.'**
  String get searchError;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No search results found'**
  String get searchNoResults;

  /// No description provided for @searchTryDifferent.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get searchTryDifferent;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Use the search box above to search for products'**
  String get searchPrompt;

  /// No description provided for @searchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'\"{query}\" — {count} results found'**
  String searchResultsCount(String query, int count);

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get accountTitle;

  /// No description provided for @accountPleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please log in'**
  String get accountPleaseLogin;

  /// No description provided for @accountHello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {firstName} {lastName}'**
  String accountHello(String firstName, String lastName);

  /// No description provided for @accountMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get accountMyOrders;

  /// No description provided for @accountMyAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get accountMyAddresses;

  /// No description provided for @accountWishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get accountWishlist;

  /// No description provided for @accountUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get accountUpdateProfile;

  /// No description provided for @accountChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get accountChangeEmail;

  /// No description provided for @accountChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get accountChangePassword;

  /// No description provided for @accountLanguageCurrency.
  ///
  /// In en, this message translates to:
  /// **'Language & Currency'**
  String get accountLanguageCurrency;

  /// No description provided for @accountLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get accountLogOut;

  /// No description provided for @accountFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get accountFirstName;

  /// No description provided for @accountLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get accountLastName;

  /// No description provided for @accountNewEmail.
  ///
  /// In en, this message translates to:
  /// **'New Email'**
  String get accountNewEmail;

  /// No description provided for @accountConfirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm Email'**
  String get accountConfirmEmail;

  /// No description provided for @accountCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get accountCurrentPassword;

  /// No description provided for @accountNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get accountNewPassword;

  /// No description provided for @accountConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get accountConfirmNewPassword;

  /// No description provided for @accountProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get accountProfileUpdated;

  /// No description provided for @accountEmailUpdated.
  ///
  /// In en, this message translates to:
  /// **'Email updated'**
  String get accountEmailUpdated;

  /// No description provided for @accountPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get accountPasswordUpdated;

  /// No description provided for @accountProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get accountProfile;

  /// No description provided for @addressListTitle.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get addressListTitle;

  /// No description provided for @addressListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses.'**
  String get addressListEmpty;

  /// No description provided for @addressFallback.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressFallback;

  /// No description provided for @addressDefaultShipping.
  ///
  /// In en, this message translates to:
  /// **'Default shipping address assigned'**
  String get addressDefaultShipping;

  /// No description provided for @addressDefaultBilling.
  ///
  /// In en, this message translates to:
  /// **'Default billing address assigned'**
  String get addressDefaultBilling;

  /// No description provided for @addressEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get addressEdit;

  /// No description provided for @addressSetDefaultShipping.
  ///
  /// In en, this message translates to:
  /// **'Set as Default Shipping'**
  String get addressSetDefaultShipping;

  /// No description provided for @addressSetDefaultBilling.
  ///
  /// In en, this message translates to:
  /// **'Set as Default Billing'**
  String get addressSetDefaultBilling;

  /// No description provided for @addressDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get addressDelete;

  /// No description provided for @addressEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get addressEditTitle;

  /// No description provided for @addressNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Address'**
  String get addressNewTitle;

  /// No description provided for @addressStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get addressStreet;

  /// No description provided for @addressPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get addressPostalCode;

  /// No description provided for @addressCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get addressCity;

  /// No description provided for @addressSalutation.
  ///
  /// In en, this message translates to:
  /// **'Salutation'**
  String get addressSalutation;

  /// No description provided for @addressSalutationSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get addressSalutationSelect;

  /// No description provided for @addressCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get addressCountry;

  /// No description provided for @addressStateOptional.
  ///
  /// In en, this message translates to:
  /// **'State (optional)'**
  String get addressStateOptional;

  /// No description provided for @addressState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get addressState;

  /// No description provided for @addressPhoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get addressPhoneOptional;

  /// No description provided for @addressFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{label} required'**
  String addressFieldRequired(String label);

  /// No description provided for @wishlistTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wishlist'**
  String get wishlistTitle;

  /// No description provided for @wishlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get wishlistEmpty;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Reviews'**
  String get reviewsTitle;

  /// No description provided for @reviewsAdded.
  ///
  /// In en, this message translates to:
  /// **'Review added'**
  String get reviewsAdded;

  /// No description provided for @reviewsRating.
  ///
  /// In en, this message translates to:
  /// **'Rating:'**
  String get reviewsRating;

  /// No description provided for @reviewsRatingValue.
  ///
  /// In en, this message translates to:
  /// **'Rating: {points}'**
  String reviewsRatingValue(String points);

  /// No description provided for @reviewsTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reviewsTitleLabel;

  /// No description provided for @reviewsReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewsReviewLabel;

  /// No description provided for @reviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get reviewsEmpty;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Language & Currency'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings updated successfully'**
  String get settingsUpdated;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get settingsSave;

  /// No description provided for @orderListTitle.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get orderListTitle;

  /// No description provided for @orderListEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no orders yet'**
  String get orderListEmpty;

  /// No description provided for @orderListStartShopping.
  ///
  /// In en, this message translates to:
  /// **'Start Shopping'**
  String get orderListStartShopping;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumber(String number);

  /// No description provided for @orderChangePayment.
  ///
  /// In en, this message translates to:
  /// **'Change Payment Method'**
  String get orderChangePayment;

  /// No description provided for @orderViewList.
  ///
  /// In en, this message translates to:
  /// **'View Order List'**
  String get orderViewList;

  /// No description provided for @dateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Date unknown'**
  String get dateUnknown;

  /// No description provided for @orderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetailTitle;

  /// No description provided for @orderDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderDetailNotFound;

  /// No description provided for @orderDetailShippingStatus.
  ///
  /// In en, this message translates to:
  /// **'Shipping: {status}'**
  String orderDetailShippingStatus(String status);

  /// No description provided for @orderDetailItems.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderDetailItems;

  /// No description provided for @orderDetailNoItems.
  ///
  /// In en, this message translates to:
  /// **'No order items found'**
  String get orderDetailNoItems;

  /// No description provided for @orderDetailQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {quantity}'**
  String orderDetailQuantity(String quantity);

  /// No description provided for @orderDetailBillingAddress.
  ///
  /// In en, this message translates to:
  /// **'Billing Address'**
  String get orderDetailBillingAddress;

  /// No description provided for @orderDetailShippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get orderDetailShippingAddress;

  /// No description provided for @orderDetailSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderDetailSummary;

  /// No description provided for @orderDetailNetTotal.
  ///
  /// In en, this message translates to:
  /// **'Net Total'**
  String get orderDetailNetTotal;

  /// No description provided for @orderDetailVatPlus.
  ///
  /// In en, this message translates to:
  /// **'Plus {rate}% VAT'**
  String orderDetailVatPlus(String rate);

  /// No description provided for @orderDetailVat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get orderDetailVat;

  /// No description provided for @orderDetailDownload.
  ///
  /// In en, this message translates to:
  /// **'Download {docType}'**
  String orderDetailDownload(String docType);

  /// No description provided for @passwordResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Reset'**
  String get passwordResetTitle;

  /// No description provided for @passwordResetHeading.
  ///
  /// In en, this message translates to:
  /// **'Did you forget your password?'**
  String get passwordResetHeading;

  /// No description provided for @passwordResetInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address, we will send you a password reset link.'**
  String get passwordResetInstructions;

  /// No description provided for @passwordResetSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send Password Reset Link'**
  String get passwordResetSendLink;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Email Sent'**
  String get passwordResetEmailSent;

  /// No description provided for @passwordResetCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Please check your email at {email}.'**
  String passwordResetCheckEmail(String email);

  /// No description provided for @passwordResetReturnLogin.
  ///
  /// In en, this message translates to:
  /// **'Return to Login Page'**
  String get passwordResetReturnLogin;

  /// No description provided for @passwordConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get passwordConfirmTitle;

  /// No description provided for @passwordConfirmInstructions.
  ///
  /// In en, this message translates to:
  /// **'Select a secure password. It must be at least 8 characters long.'**
  String get passwordConfirmInstructions;

  /// No description provided for @passwordConfirmNewPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'New Password (Confirm)'**
  String get passwordConfirmNewPasswordConfirm;

  /// No description provided for @passwordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordConfirmRequired;

  /// No description provided for @passwordConfirmMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long'**
  String get passwordConfirmMinLength;

  /// No description provided for @passwordConfirmAgainRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password again'**
  String get passwordConfirmAgainRequired;

  /// No description provided for @passwordConfirmMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordConfirmMismatch;

  /// No description provided for @passwordConfirmUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get passwordConfirmUpdate;

  /// No description provided for @passwordConfirmSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Updated Successfully'**
  String get passwordConfirmSuccessTitle;

  /// No description provided for @passwordConfirmSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'You can now login with your new password.'**
  String get passwordConfirmSuccessBody;

  /// No description provided for @guestOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest Order Lookup'**
  String get guestOrderTitle;

  /// No description provided for @guestOrderHeading.
  ///
  /// In en, this message translates to:
  /// **'Lookup Your Orders'**
  String get guestOrderHeading;

  /// No description provided for @guestOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your email address and postal code can be used to view your orders.'**
  String get guestOrderSubtitle;

  /// No description provided for @guestOrderPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get guestOrderPostalCode;

  /// No description provided for @guestOrderCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Order Code (Optional)'**
  String get guestOrderCodeOptional;

  /// No description provided for @guestOrderLookup.
  ///
  /// In en, this message translates to:
  /// **'Lookup Orders'**
  String get guestOrderLookup;

  /// No description provided for @guestOrderYourOrders.
  ///
  /// In en, this message translates to:
  /// **'Your Orders'**
  String get guestOrderYourOrders;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactTitle;

  /// No description provided for @contactHeading.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactHeading;

  /// No description provided for @contactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us for your questions or suggestions.'**
  String get contactSubtitle;

  /// No description provided for @contactSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject *'**
  String get contactSubject;

  /// No description provided for @contactMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Message *'**
  String get contactMessage;

  /// No description provided for @contactSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get contactSend;

  /// No description provided for @contactEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get contactEmailRequired;

  /// No description provided for @contactEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get contactEmailInvalid;

  /// No description provided for @contactSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject'**
  String get contactSubjectRequired;

  /// No description provided for @contactMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your message'**
  String get contactMessageRequired;

  /// No description provided for @contactSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Message Sent'**
  String get contactSuccessTitle;

  /// No description provided for @contactSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'We have received your message. We will get back to you as soon as possible.'**
  String get contactSuccessBody;

  /// No description provided for @contactSendNew.
  ///
  /// In en, this message translates to:
  /// **'Send New Message'**
  String get contactSendNew;

  /// No description provided for @bootstrapErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect'**
  String get bootstrapErrorTitle;

  /// No description provided for @bootstrapErrorBody.
  ///
  /// In en, this message translates to:
  /// **'The app could not authenticate with the store. Please verify the sales channel ID, app secret, and that the mobile app is enabled in Shopware admin.'**
  String get bootstrapErrorBody;

  /// No description provided for @urlRequired.
  ///
  /// In en, this message translates to:
  /// **'URL is required'**
  String get urlRequired;

  /// No description provided for @paymentStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get paymentStatusOpen;

  /// No description provided for @paymentStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentStatusPaid;

  /// No description provided for @paymentStatusPartiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially paid'**
  String get paymentStatusPartiallyPaid;

  /// No description provided for @paymentStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get paymentStatusInProgress;

  /// No description provided for @paymentStatusAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Authorized'**
  String get paymentStatusAuthorized;

  /// No description provided for @paymentStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get paymentStatusCancelled;

  /// No description provided for @paymentStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get paymentStatusRefunded;

  /// No description provided for @paymentStatusPartiallyRefunded.
  ///
  /// In en, this message translates to:
  /// **'Partially refunded'**
  String get paymentStatusPartiallyRefunded;

  /// No description provided for @paymentStatusReminded.
  ///
  /// In en, this message translates to:
  /// **'Reminded'**
  String get paymentStatusReminded;

  /// No description provided for @paymentStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get paymentStatusFailed;

  /// No description provided for @paymentStatusReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get paymentStatusReopened;

  /// No description provided for @paymentStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get paymentStatusUnknown;

  /// No description provided for @shippingStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get shippingStatusOpen;

  /// No description provided for @shippingStatusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get shippingStatusShipped;

  /// No description provided for @shippingStatusPartiallyShipped.
  ///
  /// In en, this message translates to:
  /// **'Partially shipped'**
  String get shippingStatusPartiallyShipped;

  /// No description provided for @shippingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get shippingStatusCancelled;

  /// No description provided for @shippingStatusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get shippingStatusReturned;

  /// No description provided for @shippingStatusPartiallyReturned.
  ///
  /// In en, this message translates to:
  /// **'Partially returned'**
  String get shippingStatusPartiallyReturned;

  /// No description provided for @shippingStatusReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get shippingStatusReopened;

  /// No description provided for @shippingStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get shippingStatusUnknown;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
