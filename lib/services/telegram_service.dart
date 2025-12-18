import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class TelegramService {
  static TelegramService? _instance;
  static TelegramService get instance => _instance ??= TelegramService._();

  TelegramService._();

  bool get isInTelegram {
    if (!kIsWeb) return false;
    try {
      return js.context.hasProperty('Telegram') &&
          js.context['Telegram'].hasProperty('WebApp');
    } catch (e) {
      return false;
    }
  }

  void init() {
    if (!isInTelegram) return;
    try {
      js.context['Telegram']['WebApp'].callMethod('ready');
      js.context['Telegram']['WebApp'].callMethod('expand');
    } catch (e) {
      debugPrint('Telegram init error: $e');
    }
  }

  Map<String, dynamic>? getUser() {
    if (!isInTelegram) return null;
    try {
      final initDataUnsafe = js.context['Telegram']['WebApp']['initDataUnsafe'];
      final user = initDataUnsafe['user'];
      if (user != null) {
        return {
          'id': user['id'],
          'firstName': user['first_name'],
          'lastName': user['last_name'],
          'username': user['username'],
        };
      }
    } catch (e) {
      debugPrint('Telegram getUser error: $e');
    }
    return null;
  }

  void showMainButton(String text, Function callback) {
    if (!isInTelegram) return;
    try {
      final mainButton = js.context['Telegram']['WebApp']['MainButton'];
      mainButton.callMethod('setText', [text]);
      mainButton.callMethod('show');
      mainButton['onClick'] = js.allowInterop(callback);
    } catch (e) {
      debugPrint('Telegram showMainButton error: $e');
    }
  }

  void hideMainButton() {
    if (!isInTelegram) return;
    try {
      js.context['Telegram']['WebApp']['MainButton'].callMethod('hide');
    } catch (e) {
      debugPrint('Telegram hideMainButton error: $e');
    }
  }

  void close() {
    if (!isInTelegram) return;
    try {
      js.context['Telegram']['WebApp'].callMethod('close');
    } catch (e) {
      debugPrint('Telegram close error: $e');
    }
  }
}

