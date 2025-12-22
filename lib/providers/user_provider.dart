import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  
  // Возвращает имя пользователя как в Telegram (first_name)
  String? get userName {
    print('🔍 Getting userName, _user: $_user');
    if (_user == null) {
      print('⚠️ _user is null');
      return null;
    }
    
    // Приоритет: first_name -> username -> telegram_user_id
    final firstName = _user!['first_name'] as String?;
    print('🔍 first_name: $firstName');
    if (firstName != null && firstName.isNotEmpty) {
      print('✅ Returning first_name: $firstName');
      return firstName;
    }
    
    final username = _user!['username'] as String?;
    print('🔍 username: $username');
    if (username != null && username.isNotEmpty) {
      print('✅ Returning @$username');
      return '@$username';
    }
    
    final telegramId = _user!['telegram_user_id'] as String?;
    print('🔍 telegram_user_id: $telegramId');
    if (telegramId != null) {
      print('✅ Returning User $telegramId');
      return 'User $telegramId';
    }
    
    print('⚠️ No name found');
    return null;
  }
  
  String? get firstName => _user?['first_name'] as String?;
  String? get username => _user?['username'] as String?;
  String? get telegramId => _user?['telegram_user_id'] as String?;
  String? get userId => _user?['id'] as String?;

  void setUser(Map<String, dynamic>? user) {
    print('👤 UserProvider.setUser called with: $user');
    _user = user;
    print('👤 _user updated, notifying listeners...');
    notifyListeners();
    print('👤 Listeners notified. Current userName: $userName');
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}

