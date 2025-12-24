import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

@JS('Telegram.WebApp')
external TelegramWebApp? get telegramWebApp;

@JS()
@staticInterop
class TelegramWebApp {}

extension TelegramWebAppExt on TelegramWebApp {
  external void ready();
  external void expand();
  external void close();
  external void sendData(String data);
  @JS('requestLocation')
  external void requestLocationRaw(JSFunction? callback);
  external TelegramInitDataUnsafe? get initDataUnsafe;
  external TelegramMainButton get MainButton;
}

@JS()
@staticInterop
class TelegramLocationResult {}

extension TelegramLocationResultExt on TelegramLocationResult {
  external double? get latitude;
  external double? get longitude;
}

@JS()
@staticInterop
class TelegramInitDataUnsafe {}

extension TelegramInitDataUnsafeExt on TelegramInitDataUnsafe {
  external TelegramUser? get user;
}

@JS()
@staticInterop
class TelegramUser {}

extension TelegramUserExt on TelegramUser {
  external int? get id;
  @JS('first_name')
  external String? get firstName;
  @JS('last_name')
  external String? get lastName;
  external String? get username;
}

@JS()
@staticInterop
class TelegramMainButton {}

extension TelegramMainButtonExt on TelegramMainButton {
  external void setText(String text);
  external void show();
  external void hide();
}

class TelegramService {
  static TelegramService? _instance;
  static TelegramService get instance => _instance ??= TelegramService._();

  TelegramService._();

  bool get isInTelegram {
    if (!kIsWeb) return false;
    try {
      return telegramWebApp != null;
    } catch (e) {
      return false;
    }
  }

  void init() {
    if (!isInTelegram) return;
    try {
      telegramWebApp?.ready();
      telegramWebApp?.expand();
    } catch (e) {
      debugPrint('Telegram init error: $e');
    }
  }

  Map<String, dynamic>? getUser() {
    print('🔍 Checking Telegram availability...');
    print('🔍 isInTelegram: $isInTelegram');
    
    if (!isInTelegram) {
      print('⚠️ Not in Telegram context');
      return null;
    }
    
    try {
      print('🔍 Accessing telegramWebApp...');
      final webApp = telegramWebApp;
      print('🔍 telegramWebApp: ${webApp != null ? "exists" : "null"}');
      
      final initData = webApp?.initDataUnsafe;
      print('🔍 initDataUnsafe: ${initData != null ? "exists" : "null"}');
      
      final user = initData?.user;
      print('🔍 user: ${user != null ? "exists" : "null"}');
      
      if (user != null) {
        final userData = {
          'id': user.id,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'username': user.username,
        };
        print('✅ Telegram user data retrieved: $userData');
        return userData;
      } else {
        print('⚠️ Telegram user is null');
      }
    } catch (e, stackTrace) {
      print('❌ Telegram getUser error: $e');
      print('❌ Stack trace: $stackTrace');
      debugPrint('Telegram getUser error: $e');
    }
    return null;
  }

  void showMainButton(String text, Function callback) {
    if (!isInTelegram) return;
    try {
      telegramWebApp?.MainButton.setText(text);
      telegramWebApp?.MainButton.show();
    } catch (e) {
      debugPrint('Telegram showMainButton error: $e');
    }
  }

  void hideMainButton() {
    if (!isInTelegram) return;
    try {
      telegramWebApp?.MainButton.hide();
    } catch (e) {
      debugPrint('Telegram hideMainButton error: $e');
    }
  }

  void close() {
    if (!isInTelegram) return;
    try {
      telegramWebApp?.close();
    } catch (e) {
      debugPrint('Telegram close error: $e');
    }
  }

  /// Отправка данных в бота (web_app_data)
  void sendData(String data) {
    if (!isInTelegram) return;
    try {
      telegramWebApp?.sendData(data);
      debugPrint('Telegram sendData: $data');
    } catch (e) {
      debugPrint('Telegram sendData error: $e');
    }
  }

  /// Запрос геопозиции через Telegram WebApp
  Future<Map<String, double>?> requestLocation() async {
    if (!isInTelegram) return null;
    final completer = Completer<Map<String, double>?>();
    try {
      telegramWebApp?.requestLocationRaw(
        ((JSAny? result) {
          try {
            final res = result as TelegramLocationResult?;
            final lat = res?.latitude;
            final lon = res?.longitude;
            if (lat != null && lon != null) {
              completer.complete({'lat': lat, 'lon': lon});
            } else {
              completer.complete(null);
            }
          } catch (_) {
            completer.complete(null);
          }
        }).toJS,
      );
    } catch (e, st) {
      debugPrint('Telegram requestLocation error: $e\n$st');
      return null;
    }
    return completer.future;
  }

  /// Получает location_id из hash параметров URL
  /// Бот передаёт параметры через fragment (#) вида:
  /// #location_id=xxx&latitude=55.7558&longitude=37.6173&location_name=Арбак
  String? getLocationIdFromHash() {
    if (!kIsWeb) return null;

    try {
      // ИСПРАВЛЕНИЕ: Сначала пробуем прочитать через JavaScript window.location.hash
      // так как Uri.base.fragment может быть пустым в момент первой загрузки
      String hash = '';

      try {
        // Используем JS interop для чтения напрямую из window.location.hash
        final jsHash = _getWindowLocationHash();
        if (jsHash != null && jsHash.isNotEmpty) {
          // Убираем # в начале если есть
          hash = jsHash.startsWith('#') ? jsHash.substring(1) : jsHash;
          print('🔍 Hash from window.location.hash: $hash');
        }
      } catch (e) {
        print('⚠️ Failed to read from window.location.hash: $e');
      }

      // Fallback: пробуем Uri.base.fragment
      if (hash.isEmpty) {
        hash = Uri.base.fragment;
        print('🔍 Hash from Uri.base.fragment: $hash');
      }

      if (hash.isEmpty) {
        print('⚠️ No hash parameters found in URL');
        return null;
      }

      print('🔍 Parsing hash: $hash');

      // Парсим параметры из hash
      final params = Uri.splitQueryString(hash);
      final locationId = params['location_id'];

      if (locationId != null) {
        print('✅ Found location_id in hash: $locationId');
        return locationId;
      } else {
        print('⚠️ No location_id parameter in hash');
        print('   Available parameters: ${params.keys.join(", ")}');
      }
    } catch (e) {
      print('❌ Error parsing hash parameters: $e');
      debugPrint('Error parsing hash: $e');
    }

    return null;
  }

  /// Читает window.location.hash через JavaScript
  String? _getWindowLocationHash() {
    if (!kIsWeb) return null;
    try {
      return web.window.location.hash;
    } catch (e) {
      return null;
    }
  }

  /// Получает все параметры локации из hash
  Map<String, String>? getLocationDataFromHash() {
    if (!kIsWeb) return null;

    try {
      // Используем тот же подход что и в getLocationIdFromHash
      String hash = '';

      try {
        final jsHash = _getWindowLocationHash();
        if (jsHash != null && jsHash.isNotEmpty) {
          hash = jsHash.startsWith('#') ? jsHash.substring(1) : jsHash;
        }
      } catch (e) {
        print('⚠️ Failed to read from window.location.hash: $e');
      }

      if (hash.isEmpty) {
        hash = Uri.base.fragment;
      }

      if (hash.isEmpty) {
        return null;
      }

      print('🔍 Parsing location data from hash: $hash');

      // Парсим все параметры
      final params = Uri.splitQueryString(hash);

      if (params.containsKey('location_id')) {
        print('✅ Location data found in hash:');
        print('   - location_id: ${params['location_id']}');
        print('   - latitude: ${params['latitude']}');
        print('   - longitude: ${params['longitude']}');
        print('   - location_name: ${params['location_name']}');

        return params;
      }
    } catch (e) {
      print('❌ Error parsing location data from hash: $e');
      debugPrint('Error parsing location data: $e');
    }

    return null;
  }
}
