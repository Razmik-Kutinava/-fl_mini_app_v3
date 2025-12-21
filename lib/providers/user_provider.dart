import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  
  String? get userName {
    if (_user == null) return null;
    final username = _user!['telegramUsername'] as String?;
    if (username != null && username.isNotEmpty) {
      return '@$username';
    }
    final telegramId = _user!['telegramId'] as String?;
    if (telegramId != null) {
      return 'User $telegramId';
    }
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

