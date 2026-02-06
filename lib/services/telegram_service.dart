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
  external TelegramMainButton? get MainButton;
  external void disableVerticalSwipes();
  external void enableVerticalSwipes();
  
  /// Проверка готовности WebApp API
  @JS('isReady')
  external bool? get isReady;
  
  @JS('version')
  external String? get version;
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
      final webApp = telegramWebApp;
      if (webApp == null) return false;
      
      // Дополнительная проверка: пытаемся проверить что объект действительно доступен
      try {
        // Просто проверяем что объект существует, не вызывая методы
        return true;
      } catch (e) {
        debugPrint('⚠️ Telegram WebApp object check failed: $e');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ Telegram WebApp availability check failed: $e');
      return false;
    }
  }

  void init() {
    if (!isInTelegram) {
      debugPrint('⚠️ Not in Telegram context, skipping init');
      return;
    }
    
    try {
      final webApp = telegramWebApp;
      if (webApp == null) {
        debugPrint('⚠️ Telegram WebApp is null, cannot initialize');
        return;
      }
      
      // Проверяем версию API если доступна
      try {
        final version = webApp.version;
        debugPrint('📱 Telegram WebApp version: ${version ?? "unknown"}');
      } catch (e) {
        // Игнорируем ошибку версии
      }
      
      // Вызываем ready() с защитой от ошибок
      try {
        webApp.ready();
        debugPrint('✅ Telegram WebApp ready() called');
      } catch (e) {
        debugPrint('⚠️ Telegram ready() error: $e');
      }
      
      // Вызываем expand() с защитой
      try {
        webApp.expand();
        debugPrint('✅ Telegram WebApp expand() called');
      } catch (e) {
        debugPrint('⚠️ Telegram expand() error: $e');
      }
      
      // ⭐ КРИТИЧЕСКИ ВАЖНО: Отключаем вертикальные свайпы Telegram
      // чтобы наши свайпы работали корректно
      try {
        webApp.disableVerticalSwipes();
        print('✅ Telegram WebApp: vertical swipes disabled');
      } catch (e) {
        print('⚠️ Could not disable Telegram vertical swipes: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Telegram init error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
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

  /// Безопасное получение MainButton с проверками
  TelegramMainButton? _getMainButton() {
    if (!isInTelegram) return null;
    try {
      final webApp = telegramWebApp;
      if (webApp == null) return null;
      
      try {
        final mainButton = webApp.MainButton;
        // Дополнительная проверка через JS interop
        if (mainButton == null) {
          debugPrint('⚠️ Telegram MainButton is null');
          return null;
        }
        return mainButton;
      } catch (e) {
        debugPrint('⚠️ Error accessing Telegram MainButton: $e');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ Error getting Telegram MainButton: $e');
      return null;
    }
  }

  void showMainButton(String text, Function callback) {
    if (!isInTelegram) return;
    
    final mainButton = _getMainButton();
    if (mainButton == null) {
      debugPrint('⚠️ Cannot show MainButton: MainButton is null');
      return;
    }
    
    try {
      mainButton.setText(text);
      mainButton.show();
      debugPrint('✅ Telegram MainButton shown: $text');
    } catch (e, stackTrace) {
      debugPrint('❌ Telegram showMainButton error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  void hideMainButton() {
    if (!isInTelegram) return;
    
    final mainButton = _getMainButton();
    if (mainButton == null) {
      debugPrint('⚠️ Cannot hide MainButton: MainButton is null');
      return;
    }
    
    try {
      mainButton.hide();
      debugPrint('✅ Telegram MainButton hidden');
    } catch (e, stackTrace) {
      debugPrint('❌ Telegram hideMainButton error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  void close() {
    if (!isInTelegram) return;
    try {
      final webApp = telegramWebApp;
      if (webApp == null) {
        debugPrint('⚠️ Telegram WebApp is null, cannot close');
        return;
      }
      
      try {
        webApp.close();
      } catch (e) {
        debugPrint('Telegram close error: $e');
      }
    } catch (e) {
      debugPrint('Telegram close outer error: $e');
    }
  }

  /// Отправка данных в бота (web_app_data)
  void sendData(String data) {
    if (!isInTelegram) return;
    try {
      final webApp = telegramWebApp;
      if (webApp == null) {
        debugPrint('⚠️ Telegram WebApp is null, cannot send data');
        return;
      }
      
      try {
        webApp.sendData(data);
        debugPrint('Telegram sendData: $data');
      } catch (e) {
        debugPrint('Telegram sendData error: $e');
      }
    } catch (e) {
      debugPrint('Telegram sendData outer error: $e');
    }
  }

  /// Запрос геопозиции через Telegram WebApp
  Future<Map<String, double>?> requestLocation() async {
    if (!isInTelegram) return null;
    
    final webApp = telegramWebApp;
    if (webApp == null) {
      debugPrint('⚠️ Telegram WebApp is null, cannot request location');
      return null;
    }
    
    final completer = Completer<Map<String, double>?>();
    try {
      webApp.requestLocationRaw(
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
      completer.complete(null);
    }
    return completer.future;
  }

  /// Получает location_id из hash параметров URL с повторными попытками
  /// Бот передаёт параметры через fragment (#) вида:
  /// #location_id=xxx&latitude=55.7558&longitude=37.6173&location_name=Арбак
  /// Telegram может устанавливать hash асинхронно, поэтому нужны повторные попытки
  Future<String?> getLocationIdFromHashWithRetry({
    int maxAttempts = 5,
    Duration initialDelay = const Duration(milliseconds: 300),
  }) async {
    if (!kIsWeb) return null;

    print('🔍 Starting hash reading with $maxAttempts attempts...');

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // Первая попытка сразу, остальные с задержкой
      if (attempt > 0) {
        // Увеличиваем задержку с каждой попыткой: 300ms, 600ms, 900ms, 1200ms
        final delay = initialDelay * attempt;
        print(
          '🔄 Attempt ${attempt + 1}/$maxAttempts: Waiting ${delay.inMilliseconds}ms before reading hash...',
        );
        await Future.delayed(delay);
      } else {
        print(
          '🔍 Attempt 1/$maxAttempts: Reading hash immediately (no delay)...',
        );
      }

      // Читаем hash
      final locationId = getLocationIdFromHash();

      if (locationId != null && locationId.isNotEmpty) {
        print(
          '✅ SUCCESS! Found location_id in hash on attempt ${attempt + 1}: $locationId',
        );
        return locationId;
      }

      // Логируем если это не последняя попытка
      if (attempt < maxAttempts - 1) {
        print(
          '⚠️ Attempt ${attempt + 1}/$maxAttempts: Hash not available yet, will retry...',
        );
        print('   Current URL fragment: ${Uri.base.fragment}');
        try {
          final jsHash = _getWindowLocationHash();
          print('   window.location.hash: ${jsHash ?? "null"}');
        } catch (e) {
          print('   Could not read window.location.hash: $e');
        }
      }
    }

    print(
      '❌ FAILED: Could not read location_id from hash after $maxAttempts attempts',
    );
    print('   Final URL: ${Uri.base.toString()}');
    print('   Final fragment: ${Uri.base.fragment}');
    try {
      final jsHash = _getWindowLocationHash();
      print('   Final window.location.hash: ${jsHash ?? "null"}');
    } catch (e) {
      print('   Could not read final window.location.hash: $e');
    }
    return null;
  }

  /// Получает location_id из hash параметров URL (синхронная версия)
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
          print(
            '🔍 Hash from window.location.hash (length: ${hash.length}): ${hash.length > 150 ? hash.substring(0, 150) + "..." : hash}',
          );
        }
      } catch (e) {
        print('⚠️ Failed to read from window.location.hash: $e');
      }

      // Fallback: пробуем Uri.base.fragment
      if (hash.isEmpty) {
        hash = Uri.base.fragment;
        if (hash.isNotEmpty) {
          print(
            '🔍 Hash from Uri.base.fragment (length: ${hash.length}): ${hash.length > 150 ? hash.substring(0, 150) + "..." : hash}',
          );
        }
      }

      if (hash.isEmpty) {
        // Не логируем здесь - это нормально для первых попыток
        return null;
      }

      print(
        '🔍 Parsing hash (length: ${hash.length}, first 200 chars: ${hash.length > 200 ? hash.substring(0, 200) + "..." : hash})',
      );

      // Парсим параметры из hash
      final params = Uri.splitQueryString(hash);
      print('🔍 Parsed hash parameters: ${params.keys.join(", ")}');

      // Логируем все параметры для отладки
      for (final key in params.keys) {
        final value = params[key];
        if (value != null && value.length > 100) {
          print(
            '   - $key: ${value.substring(0, 100)}... (length: ${value.length})',
          );
        } else {
          print('   - $key: $value');
        }
      }

      final locationId = params['location_id'];

      if (locationId != null && locationId.isNotEmpty) {
        print('✅ Found location_id in hash: $locationId');
        return locationId;
      } else {
        print('⚠️ No location_id parameter in hash');
        print('   Available parameters: ${params.keys.join(", ")}');
        // Если есть параметр data (base64), логируем это
        if (params.containsKey('data')) {
          print(
            '   ℹ️ Found "data" parameter (base64 encoded, length: ${params['data']?.length ?? 0})',
          );
          print(
            '   ⚠️ location_id should be in plain params, not only in base64 data',
          );
        }
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
        print('   - telegram_user_id: ${params['telegram_user_id']}');
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

  /// ⭐ КРИТИЧЕСКОЕ: Получает telegram_user_id из hash параметров URL
  /// Это FALLBACK когда Telegram.WebApp.initDataUnsafe.user = null!
  String? getTelegramUserIdFromHash() {
    if (!kIsWeb) return null;

    try {
      String hash = '';

      try {
        final jsHash = _getWindowLocationHash();
        if (jsHash != null && jsHash.isNotEmpty) {
          hash = jsHash.startsWith('#') ? jsHash.substring(1) : jsHash;
        }
      } catch (e) {
        print('⚠️ Failed to read window.location.hash: $e');
      }

      if (hash.isEmpty) {
        hash = Uri.base.fragment;
      }

      if (hash.isEmpty) {
        print('⚠️ No hash in URL');
        return null;
      }

      final params = Uri.splitQueryString(hash);
      final telegramUserId = params['telegram_user_id'];

      if (telegramUserId != null && telegramUserId.isNotEmpty) {
        print('✅ Found telegram_user_id in hash: $telegramUserId');
        return telegramUserId;
      } else {
        print('⚠️ No telegram_user_id in hash params');
      }
    } catch (e) {
      print('❌ Error getting telegram_user_id from hash: $e');
    }

    return null;
  }

  /// Получает action из hash параметров URL
  String? getActionFromHash() {
    if (!kIsWeb) return null;

    try {
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

      final params = Uri.splitQueryString(hash);
      return params['action'];
    } catch (e) {
      print('❌ Error parsing action from hash: $e');
      return null;
    }
  }

  /// Получает order_id из hash параметров URL
  String? getOrderIdFromHash() {
    if (!kIsWeb) return null;

    try {
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

      final params = Uri.splitQueryString(hash);
      return params['order_id'];
    } catch (e) {
      print('❌ Error parsing order_id from hash: $e');
      return null;
    }
  }
}
