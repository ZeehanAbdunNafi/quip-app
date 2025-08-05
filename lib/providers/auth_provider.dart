import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      
      if (userJson != null) {
        try {
          // Parse the JSON string to Map
          final userData = Map<String, dynamic>.from(
            jsonDecode(userJson) as Map<String, dynamic>,
          );
          _currentUser = User.fromJson(userData);
        } catch (e) {
          debugPrint('Error parsing user data: $e');
        }
      }
      // Don't auto-create demo user - let user sign in properly
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // For demo purposes, create a mock user
      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@')[0],
        email: email,
        createdAt: DateTime.now(),
        balance: 1000.0, // Starting balance
      );

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));

      return true;
    } catch (e) {
      debugPrint('Error signing in: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        createdAt: DateTime.now(),
        balance: 0.0,
      );

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));

      return true;
    } catch (e) {
      debugPrint('Error signing up: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      _currentUser = null;
      
      // Clear demo data when signing out
      await prefs.remove('payment_requests');
      await prefs.remove('payment_drafts');
      await prefs.remove('transactions');
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBalance(double newBalance) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(balance: newBalance);
      
      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
      
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImage,
  }) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
      );
      
      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
      
      notifyListeners();
    }
  }
} 