import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/group.dart';
import '../models/user.dart';

class GroupProvider with ChangeNotifier {
  List<Group> _groups = [];
  List<User> _allUsers = [];
  bool _isLoading = false;

  List<Group> get groups => _groups;
  List<User> get allUsers => _allUsers;
  bool get isLoading => _isLoading;

  final Uuid _uuid = const Uuid();

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadGroups();
      await _loadUsers();
    } catch (e) {
      debugPrint('Error initializing groups: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getStringList('groups') ?? [];
    
    _groups = groupsJson
        .map((json) => Group.fromJson(Map<String, dynamic>.from(
            json as Map<String, dynamic>)))
        .toList();
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('users') ?? [];
    
    if (usersJson.isEmpty) {
      // Create some demo users
      _allUsers = [
        User(
          id: 'user_1',
          name: 'John Doe',
          email: 'john@example.com',
          phoneNumber: '+1234567890',
          createdAt: DateTime.now(),
          balance: 500.0,
        ),
        User(
          id: 'user_2',
          name: 'Jane Smith',
          email: 'jane@example.com',
          phoneNumber: '+1234567891',
          createdAt: DateTime.now(),
          balance: 750.0,
        ),
        User(
          id: 'user_3',
          name: 'Mike Johnson',
          email: 'mike@example.com',
          phoneNumber: '+1234567892',
          createdAt: DateTime.now(),
          balance: 300.0,
        ),
        User(
          id: 'user_4',
          name: 'Sarah Wilson',
          email: 'sarah@example.com',
          phoneNumber: '+1234567893',
          createdAt: DateTime.now(),
          balance: 1200.0,
        ),
        User(
          id: 'user_5',
          name: 'David Brown',
          email: 'david@example.com',
          phoneNumber: '+1234567894',
          createdAt: DateTime.now(),
          balance: 800.0,
        ),
        User(
          id: 'user_6',
          name: 'Emily Davis',
          email: 'emily@example.com',
          phoneNumber: '+1234567895',
          createdAt: DateTime.now(),
          balance: 650.0,
        ),
        User(
          id: 'user_7',
          name: 'Alex Chen',
          email: 'alex@example.com',
          phoneNumber: '+1234567896',
          createdAt: DateTime.now(),
          balance: 450.0,
        ),
        User(
          id: 'user_8',
          name: 'Lisa Anderson',
          email: 'lisa@example.com',
          phoneNumber: '+1234567897',
          createdAt: DateTime.now(),
          balance: 950.0,
        ),
      ];
      await _saveUsers();
    } else {
      _allUsers = usersJson
          .map((json) => User.fromJson(Map<String, dynamic>.from(
              json as Map<String, dynamic>)))
          .toList();
    }
  }

  Future<void> _saveGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = _groups.map((group) => group.toJson().toString()).toList();
    await prefs.setStringList('groups', groupsJson);
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = _allUsers.map((user) => user.toJson().toString()).toList();
    await prefs.setStringList('users', usersJson);
  }

  Future<Group> createGroup({
    required String name,
    required String description,
    required List<String> memberIds,
    required String createdBy,
  }) async {
    final group = Group(
      id: _uuid.v4(),
      name: name,
      description: description,
      memberIds: memberIds,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    _groups.add(group);
    await _saveGroups();
    notifyListeners();

    return group;
  }

  Future<void> updateGroup(Group group) async {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group.copyWith(updatedAt: DateTime.now());
      await _saveGroups();
      notifyListeners();
    }
  }

  Future<void> deleteGroup(String groupId) async {
    _groups.removeWhere((group) => group.id == groupId);
    await _saveGroups();
    notifyListeners();
  }

  Future<void> addMemberToGroup(String groupId, String userId) async {
    final groupIndex = _groups.indexWhere((group) => group.id == groupId);
    if (groupIndex != -1) {
      final group = _groups[groupIndex];
      if (!group.memberIds.contains(userId)) {
        final updatedGroup = group.copyWith(
          memberIds: [...group.memberIds, userId],
          updatedAt: DateTime.now(),
        );
        _groups[groupIndex] = updatedGroup;
        await _saveGroups();
        notifyListeners();
      }
    }
  }

  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    final groupIndex = _groups.indexWhere((group) => group.id == groupId);
    if (groupIndex != -1) {
      final group = _groups[groupIndex];
      final updatedMemberIds = group.memberIds.where((id) => id != userId).toList();
      final updatedGroup = group.copyWith(
        memberIds: updatedMemberIds,
        updatedAt: DateTime.now(),
      );
      _groups[groupIndex] = updatedGroup;
      await _saveGroups();
      notifyListeners();
    }
  }

  List<Group> getGroupsForUser(String userId) {
    return _groups.where((group) => group.memberIds.contains(userId)).toList();
  }

  List<User> getGroupMembers(String groupId) {
    if (groupId == 'personal') {
      return [];
    }
    try {
      final group = _groups.firstWhere((g) => g.id == groupId);
      return _allUsers.where((user) => group.memberIds.contains(user.id)).toList();
    } catch (e) {
      // Return empty list if group is not found
      return [];
    }
  }

  List<User> getAvailableUsers(String currentUserId) {
    return _allUsers.where((user) => user.id != currentUserId).toList();
  }

  List<User> getAllUsers() {
    return _allUsers;
  }

  User? getUserById(String userId) {
    try {
      return _allUsers.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  Future<void> addUser(User user) async {
    if (!_allUsers.any((u) => u.id == user.id)) {
      _allUsers.add(user);
      await _saveUsers();
      notifyListeners();
    }
  }
} 