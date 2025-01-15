import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleManager.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) => ValueListenableBuilder<Locale>(
        valueListenable: LocaleManager.localeNotifier,
        builder: (final BuildContext context, final Locale locale, final _) =>
            MaterialApp(
          locale: locale,
          supportedLocales: const <Locale>[
            Locale("en"),
            Locale("es"),
            // Add other supported locales here
          ],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            // Add custom delegate for dynamic localization
            DynamicLocalizationDelegate(),
          ],
          home: const HomePage(),
        ),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(DynamicLocalization.of(context).translate("app_title")),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                DynamicLocalization.of(context).translate("welcome_message"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Toggle between English and Spanish for demonstration
                  final Locale newLocale =
                      LocaleManager.currentLocale.languageCode == "en"
                          ? const Locale("es")
                          : const Locale("ta");
                  await LocaleManager.setLocale(newLocale);
                },
                child: Text(
                  DynamicLocalization.of(context).translate("change_language"),
                ),
              ),
            ],
          ),
        ),
      );
}

class LocaleManager {
  LocaleManager._();
  static const String _localeKey = "locale";
  static late SharedPreferences _preferences;
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier<Locale>(const Locale("en"));

  static Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    final String localeCode = _preferences.getString(_localeKey) ?? "en";
    localeNotifier.value = Locale(localeCode);
    await DynamicLocalization.loadTranslations(localeNotifier.value);
  }

  static Locale get currentLocale => localeNotifier.value;

  static Future<void> setLocale(final Locale locale) async {
    localeNotifier.value = locale;
    await _preferences.setString(_localeKey, locale.languageCode);
    await DynamicLocalization.loadTranslations(locale);
  }
}

class DynamicLocalization {
  static Map<String, String> _localizedStrings = <String, String>{};

  static Future<void> loadTranslations(final Locale locale) async {
    final http.Response response = await http.get(
      Uri.parse("https://example.com/locales/${locale.languageCode}.json"),
    );
    if (response.statusCode == 200) {
      _localizedStrings = Map<String, String>.from(json.decode(response.body));
    } else {
      // Handle error or fallback
      _localizedStrings = <String, String>{};
    }
  }

  String translate(final String key) => _localizedStrings[key] ?? key;

  static DynamicLocalization of(final BuildContext context) =>
      Localizations.of<DynamicLocalization>(context, DynamicLocalization)!;
}

class DynamicLocalizationDelegate
    extends LocalizationsDelegate<DynamicLocalization> {
  const DynamicLocalizationDelegate();

  @override
  bool isSupported(final Locale locale) =>
      <String>["en", "es"].contains(locale.languageCode);

  @override
  Future<DynamicLocalization> load(final Locale locale) async {
    await DynamicLocalization.loadTranslations(locale);
    return DynamicLocalization();
  }

  @override
  bool shouldReload(final DynamicLocalizationDelegate old) => false;
}
