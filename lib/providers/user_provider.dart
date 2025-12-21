import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  
  String? get userName {
    print('🔍 Getting userName, _user: $_user');
    if (_user == null) {
      print('⚠️ _user is null');
      return null;
    }
    final username = _user!['telegramUsername'] as String?;
    print('🔍 telegramUsername: $username');
    if (username != null && username.isNotEmpty) {
      print('✅ Returning @$username');
      return '@$username';
    }
    final telegramId = _user!['telegramId'] as String?;
    print('🔍 telegramId: $telegramId');
    if (telegramId != null) {
      print('✅ Returning User $telegramId');
      return 'User $telegramId';
    }
    print('⚠️ No username or telegramId found');
    return null;
  }
  
  String? get telegramId => _user?['telegramId'] as String?;
  String? get userId => _user?['id'] as String?;

  void setUser(Map<String, dynamic>? user) {
    _user = user;
    notifyListeners();
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

