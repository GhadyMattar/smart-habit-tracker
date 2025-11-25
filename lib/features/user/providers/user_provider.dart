import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get hasCompletedOnboarding => _user != null;

  static const String _userKey = 'user_data';

  UserProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        final Map<String, dynamic> userMap = json.decode(userJson);
        _user = User.fromJson(userMap);
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString(_userKey, userJson);

      _user = user;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(User user) async {
    await saveUser(user);
  }

  Future<void> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);

      _user = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing user: $e');
      rethrow;
    }
  }
}
