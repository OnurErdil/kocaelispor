import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
    Locale('en'),
    Locale('tr')
  ];

  /// Uygulamanın ana başlığı
  ///
  /// In tr, this message translates to:
  /// **'Kocaelispor Fan App'**
  String get appTitle;

  /// Hoş geldin mesajı
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldiniz'**
  String get welcome;

  /// Giriş yap butonu
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// Kayıt ol butonu
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get register;

  /// E-posta etiketi
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// Şifre etiketi
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// Şifre tekrar etiketi
  ///
  /// In tr, this message translates to:
  /// **'Şifre Tekrar'**
  String get confirmPassword;

  /// Şifremi unuttum linki
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Unuttum'**
  String get forgotPassword;

  /// Google ile giriş butonu
  ///
  /// In tr, this message translates to:
  /// **'Google ile Giriş'**
  String get googleSignIn;

  /// Veya ayırıcı metni
  ///
  /// In tr, this message translates to:
  /// **'veya'**
  String get or;

  /// Hesabınız yok mu metni
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız yok mu?'**
  String get dontHaveAccount;

  /// Zaten hesabınız var mı metni
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi hatırladınız mı?'**
  String get alreadyHaveAccount;

  /// Ana sayfa tab başlığı
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get homeTab;

  /// Kadro tab başlığı
  ///
  /// In tr, this message translates to:
  /// **'Kadro'**
  String get teamTab;

  /// Takvim tab başlığı
  ///
  /// In tr, this message translates to:
  /// **'Takvim'**
  String get fixtureTab;

  /// Profil tab başlığı
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profileTab;

  /// Takım kadrosu başlığı
  ///
  /// In tr, this message translates to:
  /// **'Takım Kadrosu'**
  String get teamRoster;

  /// Fikstür ve takvim başlığı
  ///
  /// In tr, this message translates to:
  /// **'Fikstür & Takvim'**
  String get fixtureResults;

  /// Puan durumu başlığı
  ///
  /// In tr, this message translates to:
  /// **'Puan Durumu'**
  String get standings;

  /// Bildirimler başlığı
  ///
  /// In tr, this message translates to:
  /// **'Bildiriler'**
  String get notifications;

  /// Bildirim ayarları başlığı
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Ayarları'**
  String get notificationSettings;

  /// Tema ayarları başlığı
  ///
  /// In tr, this message translates to:
  /// **'Tema Ayarları'**
  String get themeSettings;

  /// Dil ayarları başlığı
  ///
  /// In tr, this message translates to:
  /// **'Dil Ayarları'**
  String get languageSettings;

  /// Açık tema seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Açık Tema'**
  String get lightTheme;

  /// Koyu tema seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Koyu Tema'**
  String get darkTheme;

  /// Sistem teması seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Sistem Teması'**
  String get systemTheme;

  /// Türkçe dil seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// İngilizce dil seçeneği
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get english;

  /// Maç bildirimleri
  ///
  /// In tr, this message translates to:
  /// **'Maç Bildirimleri'**
  String get matchNotifications;

  /// Haber bildirimleri
  ///
  /// In tr, this message translates to:
  /// **'Haber Bildirimleri'**
  String get newsNotifications;

  /// Genel bildirimler
  ///
  /// In tr, this message translates to:
  /// **'Genel Bildirimler'**
  String get generalNotifications;

  /// Kaydet butonu
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// İptal butonu
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// Sil butonu
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// Düzenle butonu
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// Ekle butonu
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get add;

  /// Çıkış yap butonu
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// Onayla butonu
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// Yükleniyor mesajı
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// Hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get error;

  /// Başarı mesajı
  ///
  /// In tr, this message translates to:
  /// **'Başarılı'**
  String get success;

  /// Veri bulunamadı mesajı
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunamadı'**
  String get noDataFound;

  /// Tekrar dene butonu
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get tryAgain;

  /// Oyuncu
  ///
  /// In tr, this message translates to:
  /// **'Oyuncu'**
  String get player;

  /// Pozisyon
  ///
  /// In tr, this message translates to:
  /// **'Pozisyon'**
  String get position;

  /// Forma numarası
  ///
  /// In tr, this message translates to:
  /// **'Forma No'**
  String get jerseyNumber;

  /// Oynanan maç sayısı
  ///
  /// In tr, this message translates to:
  /// **'O'**
  String get played;

  /// Galibiyet sayısı
  ///
  /// In tr, this message translates to:
  /// **'G'**
  String get won;

  /// Beraberlik sayısı
  ///
  /// In tr, this message translates to:
  /// **'B'**
  String get draw;

  /// Mağlubiyet sayısı
  ///
  /// In tr, this message translates to:
  /// **'M'**
  String get lost;

  /// Puan
  ///
  /// In tr, this message translates to:
  /// **'Puan'**
  String get points;

  /// Averaj
  ///
  /// In tr, this message translates to:
  /// **'AV'**
  String get goalDifference;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
