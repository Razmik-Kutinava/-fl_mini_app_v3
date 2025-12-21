import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('Telegram.WebApp')
external TelegramWebApp? get telegramWebApp;

@JS()
@staticInterop
class TelegramWebApp {}

extension TelegramWebAppExt on TelegramWebApp {
  external void ready();
  external void expand();
  external void close();
  external TelegramInitDataUnsafe? get initDataUnsafe;
  external TelegramMainButton get MainButton;
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
}
