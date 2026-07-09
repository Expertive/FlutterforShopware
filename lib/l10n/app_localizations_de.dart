// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Shop';

  @override
  String get navHome => 'Startseite';

  @override
  String get navCart => 'Warenkorb';

  @override
  String get navAccount => 'Konto';

  @override
  String commonError(String message) {
    return 'Fehler: $message';
  }

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonTryAgain => 'Nochmal versuchen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonLogin => 'Anmelden';

  @override
  String get commonLogout => 'Abmelden';

  @override
  String get commonLoggedOut => 'Abgemeldet';

  @override
  String get commonRegister => 'Registrieren';

  @override
  String get commonEmail => 'E-Mail';

  @override
  String get commonPassword => 'Passwort';

  @override
  String get commonSubmit => 'Absenden';

  @override
  String get commonSearch => 'Suche';

  @override
  String get commonCategories => 'Kategorien';

  @override
  String get commonProduct => 'Produkt';

  @override
  String get commonTotal => 'Gesamt';

  @override
  String get commonSubtotal => 'Zwischensumme';

  @override
  String get commonShipping => 'Versand';

  @override
  String get commonPayment => 'Zahlung';

  @override
  String get commonOrders => 'Bestellungen';

  @override
  String get commonUnknown => 'Unbekannt';

  @override
  String get commonLoading => 'Wird geladen...';

  @override
  String get cookieTitle => 'Cookie-Nutzung';

  @override
  String get cookieMessage =>
      'Diese Website verwendet Cookies, um Ihre Erfahrung zu verbessern. Durch die weitere Nutzung unserer Website stimmen Sie unserer Cookie-Richtlinie zu.';

  @override
  String get cookieDecline => 'Ablehnen';

  @override
  String get cookieAccept => 'Akzeptieren';

  @override
  String get homeContentUnavailable => 'Startseiteninhalt ist nicht verfügbar.';

  @override
  String get homeLayoutError => 'Fehler beim Laden des Layouts';

  @override
  String get languageCurrencyUpdated => 'Sprache/Währung aktualisiert';

  @override
  String languageCurrencyUpdateError(String message) {
    return 'Aktualisierungsfehler: $message';
  }

  @override
  String get languageLabel => 'Sprache';

  @override
  String get currencyLabel => 'Währung';

  @override
  String get categoriesNotAvailable => 'Kategorien nicht verfügbar';

  @override
  String get categoryNotFound => 'Kategorie nicht gefunden';

  @override
  String get showProductsTooltip => 'Produkte anzeigen';

  @override
  String get unnamedCategory => 'Unbenannte Kategorie';

  @override
  String get unknownCategory => 'Unbekannte Kategorie';

  @override
  String get loginTitle => 'Kundenanmeldung';

  @override
  String get loginEmailRequired => 'E-Mail erforderlich';

  @override
  String get loginPasswordRequired => 'Passwort erforderlich';

  @override
  String get loginForgotPassword => 'Passwort vergessen';

  @override
  String get loginSuccessful => 'Anmeldung erfolgreich';

  @override
  String get passwordRecovery => 'Passwort-Wiederherstellung';

  @override
  String get registerTitle => 'Neues Konto registrieren';

  @override
  String get registerEmailAddress => 'E-Mail-Adresse';

  @override
  String get registerNewPassword => 'Neues Passwort';

  @override
  String get registerFirstNameOptional => 'Vorname (optional)';

  @override
  String get registerLastName => 'Nachname';

  @override
  String get registerSalutationId => 'Anrede-ID';

  @override
  String get registerEmailRequired => 'E-Mail-Adresse erforderlich';

  @override
  String get registerPasswordRequired => 'Neues Passwort erforderlich';

  @override
  String get registerFirstNameRequired => 'Vorname erforderlich';

  @override
  String get registerLastNameRequired => 'Nachname erforderlich';

  @override
  String get registerSalutationRequired => 'Anrede-ID erforderlich';

  @override
  String get registerSuccessful => 'Registrierung erfolgreich';

  @override
  String get cartTitle => 'Warenkorb';

  @override
  String get cartEmpty => 'Ihr Warenkorb ist leer';

  @override
  String cartUnitPrice(String price) {
    return 'Einzelpreis: $price';
  }

  @override
  String cartLineTotal(String price) {
    return 'Gesamt: $price';
  }

  @override
  String get cartAppliedDiscounts => 'Angewandte Rabatte';

  @override
  String get cartDiscount => 'Rabatt';

  @override
  String cartVatPercent(String rate) {
    return 'MwSt. ($rate%)';
  }

  @override
  String get cartExcludingVat => 'Ohne MwSt.';

  @override
  String get cartCompleteOrder => 'Bestellung abschließen';

  @override
  String get checkoutTitle => 'Kasse';

  @override
  String get checkoutFillAllFields => 'Bitte füllen Sie alle Felder aus';

  @override
  String get checkoutLoginRequired =>
      'Bitte melden Sie sich an, um eine Bestellung aufzugeben.';

  @override
  String get checkoutShippingBlocked =>
      'Diese Versandart kann für die ausgewählte Lieferadresse nicht verwendet werden. Bitte wählen Sie eine andere Adresse oder Versandart.';

  @override
  String get checkoutOrderCreatedMissingPayment =>
      'Bestellung erstellt. Erforderliche Zahlungsinformationen konnten nicht abgerufen werden.';

  @override
  String get checkoutOrderCreatedPaymentRetry =>
      'Ihre Bestellung wurde erfolgreich erstellt. Bitte versuchen Sie die Zahlung später erneut oder kontaktieren Sie den Kundenservice.';

  @override
  String checkoutPaymentError(String message) {
    return 'Zahlungsfehler: $message';
  }

  @override
  String get checkoutPaymentStepFailed => 'Zahlungsschritt fehlgeschlagen.';

  @override
  String get checkoutLoginAndTryAgain => 'Anmelden und erneut versuchen.';

  @override
  String get checkoutShippingAddress => 'Lieferadresse';

  @override
  String get checkoutBillingAddress => 'Rechnungsadresse';

  @override
  String get checkoutShippingMethod => 'Versandart';

  @override
  String get checkoutPaymentMethod => 'Zahlungsart';

  @override
  String get checkoutOrderCreated => 'Bestellung erstellt';

  @override
  String checkoutOrderId(String orderId) {
    return 'Bestellnummer: $orderId';
  }

  @override
  String checkoutTransactionId(String transactionId) {
    return 'Transaktions-ID: $transactionId';
  }

  @override
  String checkoutPaymentStatus(String status) {
    return 'Zahlungsstatus: $status';
  }

  @override
  String get checkoutOrderCreatedSuccess =>
      'Ihre Bestellung wurde erfolgreich erstellt.';

  @override
  String get checkoutOrderIdNotFound => 'Bestellnummer nicht gefunden';

  @override
  String get checkoutCompletePayment => 'Zahlung abschließen';

  @override
  String get checkoutCompleteOrder => 'Bestellung abschließen';

  @override
  String get checkoutRedirectingPayment =>
      'Weiterleitung zum Zahlungsanbieter...';

  @override
  String checkoutInvalidRedirectUrl(String url) {
    return 'Ungültige Weiterleitungs-URL: $url';
  }

  @override
  String get productLoading => 'Produktinformationen werden geladen...';

  @override
  String get productNotFound => 'Produkt nicht gefunden';

  @override
  String get productOutOfStock => 'Nicht auf Lager';

  @override
  String get productInStock => 'Auf Lager';

  @override
  String get productLastOne => 'Letztes Stück';

  @override
  String get productVariantSelection => 'Variantenauswahl';

  @override
  String get productOption => 'Option';

  @override
  String get productDescription => 'Produktbeschreibung';

  @override
  String get productCategories => 'Kategorien';

  @override
  String get productRelated => 'Ähnliche Produkte';

  @override
  String productVariantNotFound(String message) {
    return 'Variante nicht gefunden: $message';
  }

  @override
  String productAddedToCart(String name) {
    return '$name zum Warenkorb hinzugefügt';
  }

  @override
  String get productAddToCart => 'In den Warenkorb';

  @override
  String get categoryLoading => 'Kategorieinformationen werden geladen...';

  @override
  String get categorySubcategories => 'Unterkategorien';

  @override
  String get categoryProducts => 'Produkte';

  @override
  String get categoryEmpty =>
      'In dieser Kategorie wurden noch keine Produkte oder Unterkategorien gefunden.';

  @override
  String get categoryMenu => 'Menü';

  @override
  String get categoryNoCategories => 'Keine Kategorien gefunden';

  @override
  String get searchTitle => 'Suche';

  @override
  String get searchHint => 'Produkte suchen...';

  @override
  String get searchSearching => 'Suche läuft...';

  @override
  String get searchError =>
      'Bei der Suche ist ein Fehler aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String get searchNoResults => 'Keine Suchergebnisse gefunden';

  @override
  String get searchTryDifferent => 'Versuchen Sie andere Suchbegriffe';

  @override
  String get searchPrompt =>
      'Verwenden Sie das Suchfeld oben, um nach Produkten zu suchen';

  @override
  String searchResultsCount(String query, int count) {
    return '\"$query\" — $count Ergebnisse gefunden';
  }

  @override
  String get accountTitle => 'Mein Konto';

  @override
  String get accountPleaseLogin => 'Bitte melden Sie sich an';

  @override
  String accountHello(String firstName, String lastName) {
    return 'Hallo, $firstName $lastName';
  }

  @override
  String get accountMyOrders => 'Meine Bestellungen';

  @override
  String get accountMyAddresses => 'Meine Adressen';

  @override
  String get accountWishlist => 'Wunschliste';

  @override
  String get accountUpdateProfile => 'Profil aktualisieren';

  @override
  String get accountChangeEmail => 'E-Mail ändern';

  @override
  String get accountChangePassword => 'Passwort ändern';

  @override
  String get accountLanguageCurrency => 'Sprache & Währung';

  @override
  String get accountLogOut => 'Abmelden';

  @override
  String get accountFirstName => 'Vorname';

  @override
  String get accountLastName => 'Nachname';

  @override
  String get accountNewEmail => 'Neue E-Mail';

  @override
  String get accountConfirmEmail => 'E-Mail bestätigen';

  @override
  String get accountCurrentPassword => 'Aktuelles Passwort';

  @override
  String get accountNewPassword => 'Neues Passwort';

  @override
  String get accountConfirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get accountProfileUpdated => 'Profil aktualisiert';

  @override
  String get accountEmailUpdated => 'E-Mail aktualisiert';

  @override
  String get accountPasswordUpdated => 'Passwort aktualisiert';

  @override
  String get accountProfile => 'Profil';

  @override
  String get addressListTitle => 'Meine Adressen';

  @override
  String get addressListEmpty => 'Keine gespeicherten Adressen.';

  @override
  String get addressFallback => 'Adresse';

  @override
  String get addressDefaultShipping => 'Standard-Lieferadresse zugewiesen';

  @override
  String get addressDefaultBilling => 'Standard-Rechnungsadresse zugewiesen';

  @override
  String get addressEdit => 'Bearbeiten';

  @override
  String get addressSetDefaultShipping =>
      'Als Standard-Lieferadresse festlegen';

  @override
  String get addressSetDefaultBilling =>
      'Als Standard-Rechnungsadresse festlegen';

  @override
  String get addressDelete => 'Löschen';

  @override
  String get addressEditTitle => 'Adresse bearbeiten';

  @override
  String get addressNewTitle => 'Neue Adresse';

  @override
  String get addressStreet => 'Straße';

  @override
  String get addressPostalCode => 'Postleitzahl';

  @override
  String get addressCity => 'Stadt';

  @override
  String get addressSalutation => 'Anrede';

  @override
  String get addressSalutationSelect => 'Auswählen';

  @override
  String get addressCountry => 'Land';

  @override
  String get addressStateOptional => 'Bundesland (optional)';

  @override
  String get addressState => 'Bundesland';

  @override
  String get addressPhoneOptional => 'Telefon (optional)';

  @override
  String addressFieldRequired(String label) {
    return '$label erforderlich';
  }

  @override
  String get wishlistTitle => 'Meine Wunschliste';

  @override
  String get wishlistEmpty => 'Ihre Wunschliste ist leer';

  @override
  String get reviewsTitle => 'Produktbewertungen';

  @override
  String get reviewsAdded => 'Bewertung hinzugefügt';

  @override
  String get reviewsRating => 'Bewertung:';

  @override
  String reviewsRatingValue(String points) {
    return 'Bewertung: $points';
  }

  @override
  String get reviewsTitleLabel => 'Titel';

  @override
  String get reviewsReviewLabel => 'Bewertung';

  @override
  String get reviewsEmpty => 'Noch keine Bewertungen';

  @override
  String get settingsTitle => 'Sprache & Währung';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsCurrency => 'Währung';

  @override
  String get settingsUpdated => 'Einstellungen erfolgreich aktualisiert';

  @override
  String get settingsSave => 'Einstellungen speichern';

  @override
  String get orderListTitle => 'Meine Bestellungen';

  @override
  String get orderListEmpty => 'Sie haben noch keine Bestellungen';

  @override
  String get orderListStartShopping => 'Einkaufen starten';

  @override
  String orderNumber(String number) {
    return 'Bestellung #$number';
  }

  @override
  String get orderChangePayment => 'Zahlungsart ändern';

  @override
  String get orderViewList => 'Bestellliste anzeigen';

  @override
  String get dateUnknown => 'Datum unbekannt';

  @override
  String get orderDetailTitle => 'Bestelldetails';

  @override
  String get orderDetailNotFound => 'Bestellung nicht gefunden';

  @override
  String orderDetailShippingStatus(String status) {
    return 'Versand: $status';
  }

  @override
  String get orderDetailItems => 'Bestellpositionen';

  @override
  String get orderDetailNoItems => 'Keine Bestellpositionen gefunden';

  @override
  String orderDetailQuantity(String quantity) {
    return 'Menge: $quantity';
  }

  @override
  String get orderDetailBillingAddress => 'Rechnungsadresse';

  @override
  String get orderDetailShippingAddress => 'Lieferadresse';

  @override
  String get orderDetailSummary => 'Bestellübersicht';

  @override
  String get orderDetailNetTotal => 'Nettosumme';

  @override
  String orderDetailVatPlus(String rate) {
    return 'Plus $rate% MwSt.';
  }

  @override
  String get orderDetailVat => 'MwSt.';

  @override
  String orderDetailDownload(String docType) {
    return '$docType herunterladen';
  }

  @override
  String get passwordResetTitle => 'Passwort zurücksetzen';

  @override
  String get passwordResetHeading => 'Passwort vergessen?';

  @override
  String get passwordResetInstructions =>
      'Geben Sie Ihre E-Mail-Adresse ein, wir senden Ihnen einen Link zum Zurücksetzen des Passworts.';

  @override
  String get passwordResetSendLink => 'Link zum Zurücksetzen senden';

  @override
  String get passwordResetEmailSent => 'E-Mail gesendet';

  @override
  String passwordResetCheckEmail(String email) {
    return 'Bitte überprüfen Sie Ihre E-Mail unter $email.';
  }

  @override
  String get passwordResetReturnLogin => 'Zurück zur Anmeldeseite';

  @override
  String get passwordConfirmTitle => 'Neues Passwort festlegen';

  @override
  String get passwordConfirmInstructions =>
      'Wählen Sie ein sicheres Passwort. Es muss mindestens 8 Zeichen lang sein.';

  @override
  String get passwordConfirmNewPasswordConfirm =>
      'Neues Passwort (Bestätigung)';

  @override
  String get passwordConfirmRequired => 'Bitte geben Sie Ihr Passwort ein';

  @override
  String get passwordConfirmMinLength =>
      'Das Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get passwordConfirmAgainRequired =>
      'Bitte geben Sie Ihr Passwort erneut ein';

  @override
  String get passwordConfirmMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get passwordConfirmUpdate => 'Passwort aktualisieren';

  @override
  String get passwordConfirmSuccessTitle => 'Passwort erfolgreich aktualisiert';

  @override
  String get passwordConfirmSuccessBody =>
      'Sie können sich jetzt mit Ihrem neuen Passwort anmelden.';

  @override
  String get guestOrderTitle => 'Gast-Bestellabfrage';

  @override
  String get guestOrderHeading => 'Bestellungen nachschlagen';

  @override
  String get guestOrderSubtitle =>
      'Mit Ihrer E-Mail-Adresse und Postleitzahl können Sie Ihre Bestellungen einsehen.';

  @override
  String get guestOrderPostalCode => 'Postleitzahl';

  @override
  String get guestOrderCodeOptional => 'Bestellcode (optional)';

  @override
  String get guestOrderLookup => 'Bestellungen suchen';

  @override
  String get guestOrderYourOrders => 'Ihre Bestellungen';

  @override
  String get contactTitle => 'Kontakt';

  @override
  String get contactHeading => 'Kontaktieren Sie uns';

  @override
  String get contactSubtitle =>
      'Kontaktieren Sie uns bei Fragen oder Anregungen.';

  @override
  String get contactSubject => 'Betreff *';

  @override
  String get contactMessage => 'Ihre Nachricht *';

  @override
  String get contactSend => 'Senden';

  @override
  String get contactEmailRequired => 'Bitte geben Sie Ihre E-Mail-Adresse ein';

  @override
  String get contactEmailInvalid =>
      'Bitte geben Sie eine gültige E-Mail-Adresse ein';

  @override
  String get contactSubjectRequired => 'Bitte geben Sie einen Betreff ein';

  @override
  String get contactMessageRequired => 'Bitte geben Sie Ihre Nachricht ein';

  @override
  String get contactSuccessTitle => 'Nachricht gesendet';

  @override
  String get contactSuccessBody =>
      'Wir haben Ihre Nachricht erhalten. Wir melden uns so schnell wie möglich bei Ihnen.';

  @override
  String get contactSendNew => 'Neue Nachricht senden';

  @override
  String get bootstrapErrorTitle => 'Verbindung nicht möglich';

  @override
  String get bootstrapErrorBody =>
      'Die App konnte sich nicht mit dem Shop authentifizieren. Bitte überprüfen Sie die Verkaufskanal-ID, das App-Geheimnis und ob die mobile App in der Shopware-Verwaltung aktiviert ist.';

  @override
  String get urlRequired => 'URL ist erforderlich';

  @override
  String get paymentStatusOpen => 'Offen';

  @override
  String get paymentStatusPaid => 'Bezahlt';

  @override
  String get paymentStatusPartiallyPaid => 'Teilweise bezahlt';

  @override
  String get paymentStatusInProgress => 'In Bearbeitung';

  @override
  String get paymentStatusAuthorized => 'Autorisiert';

  @override
  String get paymentStatusCancelled => 'Storniert';

  @override
  String get paymentStatusRefunded => 'Erstattet';

  @override
  String get paymentStatusPartiallyRefunded => 'Teilweise erstattet';

  @override
  String get paymentStatusReminded => 'Erinnert';

  @override
  String get paymentStatusFailed => 'Fehlgeschlagen';

  @override
  String get paymentStatusReopened => 'Wiedereröffnet';

  @override
  String get paymentStatusUnknown => 'Unbekannt';

  @override
  String get shippingStatusOpen => 'Offen';

  @override
  String get shippingStatusShipped => 'Versendet';

  @override
  String get shippingStatusPartiallyShipped => 'Teilweise versendet';

  @override
  String get shippingStatusCancelled => 'Storniert';

  @override
  String get shippingStatusReturned => 'Zurückgesendet';

  @override
  String get shippingStatusPartiallyReturned => 'Teilweise zurückgesendet';

  @override
  String get shippingStatusReopened => 'Wiedereröffnet';

  @override
  String get shippingStatusUnknown => 'Unbekannt';
}
