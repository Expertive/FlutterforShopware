// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shop';

  @override
  String get navHome => 'Home';

  @override
  String get navCart => 'Cart';

  @override
  String get navAccount => 'Account';

  @override
  String commonError(String message) {
    return 'Error: $message';
  }

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonTryAgain => 'Try Again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonLogin => 'Login';

  @override
  String get commonLogout => 'Logout';

  @override
  String get commonLoggedOut => 'Logged out';

  @override
  String get commonRegister => 'Register';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonCategories => 'Categories';

  @override
  String get commonProduct => 'Product';

  @override
  String get commonTotal => 'Total';

  @override
  String get commonSubtotal => 'Subtotal';

  @override
  String get commonShipping => 'Shipping';

  @override
  String get commonPayment => 'Payment';

  @override
  String get commonOrders => 'Orders';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get cookieTitle => 'Cookie Usage';

  @override
  String get cookieMessage =>
      'This website uses cookies to improve your experience. By continuing to use our site, you agree to our cookie policy.';

  @override
  String get cookieDecline => 'Decline';

  @override
  String get cookieAccept => 'Accept';

  @override
  String get homeContentUnavailable => 'Home page content is not available.';

  @override
  String get homeLayoutError => 'Layout loading error';

  @override
  String get languageCurrencyUpdated => 'Language/Currency updated';

  @override
  String languageCurrencyUpdateError(String message) {
    return 'Update error: $message';
  }

  @override
  String get languageLabel => 'Language';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get categoriesNotAvailable => 'Categories not available';

  @override
  String get categoryNotFound => 'Category not found';

  @override
  String get showProductsTooltip => 'Show products';

  @override
  String get unnamedCategory => 'Unnamed Category';

  @override
  String get unknownCategory => 'Unknown Category';

  @override
  String get loginTitle => 'Customer Login';

  @override
  String get loginEmailRequired => 'Email required';

  @override
  String get loginPasswordRequired => 'Password required';

  @override
  String get loginForgotPassword => 'Forgot Password';

  @override
  String get loginSuccessful => 'Login successful';

  @override
  String get passwordRecovery => 'Password Recovery';

  @override
  String get registerTitle => 'Register New Account';

  @override
  String get registerEmailAddress => 'Email Address';

  @override
  String get registerNewPassword => 'New Password';

  @override
  String get registerFirstNameOptional => 'First Name (Optional)';

  @override
  String get registerLastName => 'Last Name';

  @override
  String get registerSalutationId => 'Salutation ID';

  @override
  String get registerEmailRequired => 'Email address required';

  @override
  String get registerPasswordRequired => 'New password required';

  @override
  String get registerFirstNameRequired => 'First name required';

  @override
  String get registerLastNameRequired => 'Last name required';

  @override
  String get registerSalutationRequired => 'Salutation ID required';

  @override
  String get registerSuccessful => 'Registration Successful';

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String cartUnitPrice(String price) {
    return 'Unit: $price';
  }

  @override
  String cartLineTotal(String price) {
    return 'Total: $price';
  }

  @override
  String get cartAppliedDiscounts => 'Applied Discounts';

  @override
  String get cartDiscount => 'Discount';

  @override
  String cartVatPercent(String rate) {
    return 'VAT ($rate%)';
  }

  @override
  String get cartExcludingVat => 'Excluding VAT';

  @override
  String get cartCompleteOrder => 'Complete Order';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutFillAllFields => 'Please fill in all fields';

  @override
  String get checkoutLoginRequired => 'Please log in to create an order.';

  @override
  String get checkoutShippingBlocked =>
      'This shipping method cannot be used for the selected shipping address. Please select a different address or shipping method.';

  @override
  String get checkoutOrderCreatedMissingPayment =>
      'Order created. Required information for payment could not be retrieved.';

  @override
  String get checkoutOrderCreatedPaymentRetry =>
      'Your order has been successfully created. Please try again later for payment or contact customer service.';

  @override
  String checkoutPaymentError(String message) {
    return 'Payment error: $message';
  }

  @override
  String get checkoutPaymentStepFailed => 'Payment step failed.';

  @override
  String get checkoutLoginAndTryAgain => 'Login and try again.';

  @override
  String get checkoutShippingAddress => 'Shipping Address';

  @override
  String get checkoutBillingAddress => 'Billing Address';

  @override
  String get checkoutShippingMethod => 'Shipping Method';

  @override
  String get checkoutPaymentMethod => 'Payment Method';

  @override
  String get checkoutOrderCreated => 'Order created';

  @override
  String checkoutOrderId(String orderId) {
    return 'Order ID: $orderId';
  }

  @override
  String checkoutTransactionId(String transactionId) {
    return 'Transaction ID: $transactionId';
  }

  @override
  String checkoutPaymentStatus(String status) {
    return 'Payment status: $status';
  }

  @override
  String get checkoutOrderCreatedSuccess =>
      'Your order has been successfully created.';

  @override
  String get checkoutOrderIdNotFound => 'Order ID not found';

  @override
  String get checkoutCompletePayment => 'Complete Payment';

  @override
  String get checkoutCompleteOrder => 'Complete Order';

  @override
  String get checkoutRedirectingPayment => 'Redirecting to payment provider...';

  @override
  String checkoutInvalidRedirectUrl(String url) {
    return 'Invalid redirect URL: $url';
  }

  @override
  String get productLoading => 'Loading product information...';

  @override
  String get productNotFound => 'Product not found';

  @override
  String get productOutOfStock => 'Out of Stock';

  @override
  String get productInStock => 'In Stock';

  @override
  String get productLastOne => 'Last 1 Item';

  @override
  String get productVariantSelection => 'Variant Selection';

  @override
  String get productOption => 'Option';

  @override
  String get productDescription => 'Product Description';

  @override
  String get productCategories => 'Categories';

  @override
  String get productRelated => 'Related Products';

  @override
  String productVariantNotFound(String message) {
    return 'Variant not found: $message';
  }

  @override
  String productAddedToCart(String name) {
    return '$name added to cart';
  }

  @override
  String get productAddToCart => 'Add to Cart';

  @override
  String get categoryLoading => 'Loading category information...';

  @override
  String get categorySubcategories => 'Subcategories';

  @override
  String get categoryProducts => 'Products';

  @override
  String get categoryEmpty =>
      'No products or subcategories found in this category yet.';

  @override
  String get categoryMenu => 'Menu';

  @override
  String get categoryNoCategories => 'No categories found';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search products...';

  @override
  String get searchSearching => 'Searching...';

  @override
  String get searchError =>
      'An error occurred during search. Please try again.';

  @override
  String get searchNoResults => 'No search results found';

  @override
  String get searchTryDifferent => 'Try different keywords';

  @override
  String get searchPrompt => 'Use the search box above to search for products';

  @override
  String searchResultsCount(String query, int count) {
    return '\"$query\" — $count results found';
  }

  @override
  String get accountTitle => 'My Account';

  @override
  String get accountPleaseLogin => 'Please log in';

  @override
  String accountHello(String firstName, String lastName) {
    return 'Hello, $firstName $lastName';
  }

  @override
  String get accountMyOrders => 'My Orders';

  @override
  String get accountMyAddresses => 'My Addresses';

  @override
  String get accountWishlist => 'Wishlist';

  @override
  String get accountUpdateProfile => 'Update Profile';

  @override
  String get accountChangeEmail => 'Change Email';

  @override
  String get accountChangePassword => 'Change Password';

  @override
  String get accountLanguageCurrency => 'Language & Currency';

  @override
  String get accountLogOut => 'Log Out';

  @override
  String get accountFirstName => 'First Name';

  @override
  String get accountLastName => 'Last Name';

  @override
  String get accountNewEmail => 'New Email';

  @override
  String get accountConfirmEmail => 'Confirm Email';

  @override
  String get accountCurrentPassword => 'Current Password';

  @override
  String get accountNewPassword => 'New Password';

  @override
  String get accountConfirmNewPassword => 'Confirm New Password';

  @override
  String get accountProfileUpdated => 'Profile updated';

  @override
  String get accountEmailUpdated => 'Email updated';

  @override
  String get accountPasswordUpdated => 'Password updated';

  @override
  String get accountProfile => 'Profile';

  @override
  String get addressListTitle => 'My Addresses';

  @override
  String get addressListEmpty => 'No saved addresses.';

  @override
  String get addressFallback => 'Address';

  @override
  String get addressDefaultShipping => 'Default shipping address assigned';

  @override
  String get addressDefaultBilling => 'Default billing address assigned';

  @override
  String get addressEdit => 'Edit';

  @override
  String get addressSetDefaultShipping => 'Set as Default Shipping';

  @override
  String get addressSetDefaultBilling => 'Set as Default Billing';

  @override
  String get addressDelete => 'Delete';

  @override
  String get addressEditTitle => 'Edit Address';

  @override
  String get addressNewTitle => 'New Address';

  @override
  String get addressStreet => 'Street';

  @override
  String get addressPostalCode => 'Postal Code';

  @override
  String get addressCity => 'City';

  @override
  String get addressSalutation => 'Salutation';

  @override
  String get addressSalutationSelect => 'Select';

  @override
  String get addressCountry => 'Country';

  @override
  String get addressStateOptional => 'State (optional)';

  @override
  String get addressState => 'State';

  @override
  String get addressPhoneOptional => 'Phone (optional)';

  @override
  String addressFieldRequired(String label) {
    return '$label required';
  }

  @override
  String get wishlistTitle => 'My Wishlist';

  @override
  String get wishlistEmpty => 'Your wishlist is empty';

  @override
  String get reviewsTitle => 'Product Reviews';

  @override
  String get reviewsAdded => 'Review added';

  @override
  String get reviewsRating => 'Rating:';

  @override
  String reviewsRatingValue(String points) {
    return 'Rating: $points';
  }

  @override
  String get reviewsTitleLabel => 'Title';

  @override
  String get reviewsReviewLabel => 'Review';

  @override
  String get reviewsEmpty => 'No reviews yet';

  @override
  String get settingsTitle => 'Language & Currency';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsUpdated => 'Settings updated successfully';

  @override
  String get settingsSave => 'Save Settings';

  @override
  String get orderListTitle => 'My Orders';

  @override
  String get orderListEmpty => 'You have no orders yet';

  @override
  String get orderListStartShopping => 'Start Shopping';

  @override
  String orderNumber(String number) {
    return 'Order #$number';
  }

  @override
  String get orderChangePayment => 'Change Payment Method';

  @override
  String get orderViewList => 'View Order List';

  @override
  String get dateUnknown => 'Date unknown';

  @override
  String get orderDetailTitle => 'Order Details';

  @override
  String get orderDetailNotFound => 'Order not found';

  @override
  String orderDetailShippingStatus(String status) {
    return 'Shipping: $status';
  }

  @override
  String get orderDetailItems => 'Order Items';

  @override
  String get orderDetailNoItems => 'No order items found';

  @override
  String orderDetailQuantity(String quantity) {
    return 'Quantity: $quantity';
  }

  @override
  String get orderDetailBillingAddress => 'Billing Address';

  @override
  String get orderDetailShippingAddress => 'Shipping Address';

  @override
  String get orderDetailSummary => 'Order Summary';

  @override
  String get orderDetailNetTotal => 'Net Total';

  @override
  String orderDetailVatPlus(String rate) {
    return 'Plus $rate% VAT';
  }

  @override
  String get orderDetailVat => 'VAT';

  @override
  String orderDetailDownload(String docType) {
    return 'Download $docType';
  }

  @override
  String get passwordResetTitle => 'Password Reset';

  @override
  String get passwordResetHeading => 'Did you forget your password?';

  @override
  String get passwordResetInstructions =>
      'Enter your email address, we will send you a password reset link.';

  @override
  String get passwordResetSendLink => 'Send Password Reset Link';

  @override
  String get passwordResetEmailSent => 'Email Sent';

  @override
  String passwordResetCheckEmail(String email) {
    return 'Please check your email at $email.';
  }

  @override
  String get passwordResetReturnLogin => 'Return to Login Page';

  @override
  String get passwordConfirmTitle => 'Set New Password';

  @override
  String get passwordConfirmInstructions =>
      'Select a secure password. It must be at least 8 characters long.';

  @override
  String get passwordConfirmNewPasswordConfirm => 'New Password (Confirm)';

  @override
  String get passwordConfirmRequired => 'Please enter your password';

  @override
  String get passwordConfirmMinLength =>
      'Password must be at least 8 characters long';

  @override
  String get passwordConfirmAgainRequired => 'Please enter your password again';

  @override
  String get passwordConfirmMismatch => 'Passwords do not match';

  @override
  String get passwordConfirmUpdate => 'Update Password';

  @override
  String get passwordConfirmSuccessTitle => 'Password Updated Successfully';

  @override
  String get passwordConfirmSuccessBody =>
      'You can now login with your new password.';

  @override
  String get guestOrderTitle => 'Guest Order Lookup';

  @override
  String get guestOrderHeading => 'Lookup Your Orders';

  @override
  String get guestOrderSubtitle =>
      'Your email address and postal code can be used to view your orders.';

  @override
  String get guestOrderPostalCode => 'Postal Code';

  @override
  String get guestOrderCodeOptional => 'Order Code (Optional)';

  @override
  String get guestOrderLookup => 'Lookup Orders';

  @override
  String get guestOrderYourOrders => 'Your Orders';

  @override
  String get contactTitle => 'Contact';

  @override
  String get contactHeading => 'Contact Us';

  @override
  String get contactSubtitle => 'Contact us for your questions or suggestions.';

  @override
  String get contactSubject => 'Subject *';

  @override
  String get contactMessage => 'Your Message *';

  @override
  String get contactSend => 'Send';

  @override
  String get contactEmailRequired => 'Please enter your email address';

  @override
  String get contactEmailInvalid => 'Please enter a valid email address';

  @override
  String get contactSubjectRequired => 'Please enter a subject';

  @override
  String get contactMessageRequired => 'Please enter your message';

  @override
  String get contactSuccessTitle => 'Your Message Sent';

  @override
  String get contactSuccessBody =>
      'We have received your message. We will get back to you as soon as possible.';

  @override
  String get contactSendNew => 'Send New Message';

  @override
  String get bootstrapErrorTitle => 'Unable to connect';

  @override
  String get bootstrapErrorBody =>
      'The app could not authenticate with the store. Please verify the sales channel ID, app secret, and that the mobile app is enabled in Shopware admin.';

  @override
  String get urlRequired => 'URL is required';

  @override
  String get paymentStatusOpen => 'Open';

  @override
  String get paymentStatusPaid => 'Paid';

  @override
  String get paymentStatusPartiallyPaid => 'Partially paid';

  @override
  String get paymentStatusInProgress => 'In progress';

  @override
  String get paymentStatusAuthorized => 'Authorized';

  @override
  String get paymentStatusCancelled => 'Cancelled';

  @override
  String get paymentStatusRefunded => 'Refunded';

  @override
  String get paymentStatusPartiallyRefunded => 'Partially refunded';

  @override
  String get paymentStatusReminded => 'Reminded';

  @override
  String get paymentStatusFailed => 'Failed';

  @override
  String get paymentStatusReopened => 'Reopened';

  @override
  String get paymentStatusUnknown => 'Unknown';

  @override
  String get shippingStatusOpen => 'Open';

  @override
  String get shippingStatusShipped => 'Shipped';

  @override
  String get shippingStatusPartiallyShipped => 'Partially shipped';

  @override
  String get shippingStatusCancelled => 'Cancelled';

  @override
  String get shippingStatusReturned => 'Returned';

  @override
  String get shippingStatusPartiallyReturned => 'Partially returned';

  @override
  String get shippingStatusReopened => 'Reopened';

  @override
  String get shippingStatusUnknown => 'Unknown';
}
