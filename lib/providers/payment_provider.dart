import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/payment_request.dart';
import '../models/payment_draft.dart';

class PaymentProvider with ChangeNotifier {
  List<PaymentRequest> _paymentRequests = [];
  List<PaymentDraft> _paymentDrafts = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;

  List<PaymentRequest> get paymentRequests => _paymentRequests;
  List<PaymentDraft> get paymentDrafts => _paymentDrafts;
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;

  final Uuid _uuid = const Uuid();

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadPaymentRequests();
      await _loadPaymentDrafts();
      await _loadTransactions();
    } catch (e) {
      debugPrint('Error initializing payments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPaymentRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final requestsJson = prefs.getStringList('payment_requests') ?? [];
    
    _paymentRequests = requestsJson
        .map((json) => PaymentRequest.fromJson(Map<String, dynamic>.from(
            json as Map<String, dynamic>)))
        .toList();
  }

  Future<void> _loadPaymentDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final draftsJson = prefs.getStringList('payment_drafts') ?? [];
    
    _paymentDrafts = draftsJson
        .map((json) => PaymentDraft.fromJson(Map<String, dynamic>.from(
            json as Map<String, dynamic>)))
        .toList();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList('transactions') ?? [];
    
    _transactions = transactionsJson
        .map((json) => Map<String, dynamic>.from(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> _savePaymentRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final requestsJson = _paymentRequests.map((req) => req.toJson().toString()).toList();
    await prefs.setStringList('payment_requests', requestsJson);
  }

  Future<void> _savePaymentDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final draftsJson = _paymentDrafts.map((draft) => draft.toJson().toString()).toList();
    await prefs.setStringList('payment_drafts', draftsJson);
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = _transactions.map((t) => t.toString()).toList();
    await prefs.setStringList('transactions', transactionsJson);
  }

  Future<PaymentRequest> createPaymentRequest({
    required String groupId,
    required String requestedBy,
    required double totalAmount,
    required String description,
    required bool includeRequester,
    required List<String> exemptedMembers,
    required Map<String, double> customAmounts,
    required List<String> groupMembers,
    bool isRecurring = false,
    int? recurringInterval,
    RecurringFrequency? recurringFrequency,
  }) async {
    // Initialize payment status for all group members
    Map<String, PaymentStatus> paymentStatus = {};
    Map<String, double> partialPayments = {};
    for (String memberId in groupMembers) {
      if (!exemptedMembers.contains(memberId)) {
        paymentStatus[memberId] = PaymentStatus.pending;
        partialPayments[memberId] = 0.0;
      }
    }

    final paymentRequest = PaymentRequest(
      id: _uuid.v4(),
      groupId: groupId,
      requestedBy: requestedBy,
      totalAmount: totalAmount,
      description: description,
      includeRequester: includeRequester,
      exemptedMembers: exemptedMembers,
      customAmounts: customAmounts,
      paymentStatus: paymentStatus,
      partialPayments: partialPayments,
      createdAt: DateTime.now(),
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
      recurringFrequency: recurringFrequency,
    );

    _paymentRequests.add(paymentRequest);
    await _savePaymentRequests();
    notifyListeners();

    return paymentRequest;
  }

  Future<void> updatePaymentStatus(
    String paymentRequestId,
    String userId,
    PaymentStatus status,
  ) async {
    final requestIndex = _paymentRequests.indexWhere((req) => req.id == paymentRequestId);
    if (requestIndex != -1) {
      final request = _paymentRequests[requestIndex];
      final updatedStatus = Map<String, PaymentStatus>.from(request.paymentStatus);
      updatedStatus[userId] = status;

      final updatedRequest = request.copyWith(paymentStatus: updatedStatus);
      _paymentRequests[requestIndex] = updatedRequest;

      // If all payments are completed, mark as completed
      if (updatedRequest.isCompleted) {
        _paymentRequests[requestIndex] = updatedRequest.copyWith(
          completedAt: DateTime.now(),
        );
      }

      await _savePaymentRequests();
      notifyListeners();
    }
  }

  Future<void> updatePartialPayment(
    String paymentRequestId,
    String userId,
    double partialAmount,
  ) async {
    final requestIndex = _paymentRequests.indexWhere((req) => req.id == paymentRequestId);
    if (requestIndex != -1) {
      final request = _paymentRequests[requestIndex];
      final updatedPartialPayments = Map<String, double>.from(request.partialPayments);
      final updatedStatus = Map<String, PaymentStatus>.from(request.paymentStatus);
      
      // Update partial payment amount
      updatedPartialPayments[userId] = partialAmount;
      
      // Determine the new status based on the partial amount
      final totalAmount = request.getAmountForUser(userId, request.paymentStatus.keys.toList());
      if (partialAmount >= totalAmount) {
        updatedStatus[userId] = PaymentStatus.paid;
      } else if (partialAmount > 0) {
        updatedStatus[userId] = PaymentStatus.partial;
      } else {
        updatedStatus[userId] = PaymentStatus.pending;
      }

      final updatedRequest = request.copyWith(
        paymentStatus: updatedStatus,
        partialPayments: updatedPartialPayments,
      );
      
      _paymentRequests[requestIndex] = updatedRequest;

      // If all payments are completed, mark as completed
      if (updatedRequest.isCompleted) {
        _paymentRequests[requestIndex] = updatedRequest.copyWith(
          completedAt: DateTime.now(),
        );
      }

      await _savePaymentRequests();
      notifyListeners();
    }
  }

  // Mark a payment request as invalid for a specific user
  Future<void> markRequestAsInvalid(
    String paymentRequestId,
    String userId,
    String reason,
  ) async {
    final requestIndex = _paymentRequests.indexWhere((req) => req.id == paymentRequestId);
    if (requestIndex != -1) {
      final request = _paymentRequests[requestIndex];
      final updatedValidityStatus = Map<String, RequestValidityStatus>.from(request.validityStatus);
      final updatedInvalidationReasons = Map<String, String>.from(request.invalidationReasons);
      final updatedInvalidationTimestamps = Map<String, DateTime>.from(request.invalidationTimestamps);
      
      updatedValidityStatus[userId] = RequestValidityStatus.invalid;
      updatedInvalidationReasons[userId] = reason;
      updatedInvalidationTimestamps[userId] = DateTime.now();

      final updatedRequest = request.copyWith(
        validityStatus: updatedValidityStatus,
        invalidationReasons: updatedInvalidationReasons,
        invalidationTimestamps: updatedInvalidationTimestamps,
      );
      
      _paymentRequests[requestIndex] = updatedRequest;
      await _savePaymentRequests();
      notifyListeners();
    }
  }

  // Report a payment request for fraud
  Future<void> reportRequest(
    String paymentRequestId,
    String userId,
    String reason,
  ) async {
    final requestIndex = _paymentRequests.indexWhere((req) => req.id == paymentRequestId);
    if (requestIndex != -1) {
      final request = _paymentRequests[requestIndex];
      final updatedValidityStatus = Map<String, RequestValidityStatus>.from(request.validityStatus);
      final updatedReportReasons = Map<String, String>.from(request.reportReasons);
      final updatedReportTimestamps = Map<String, DateTime>.from(request.reportTimestamps);
      
      updatedValidityStatus[userId] = RequestValidityStatus.reported;
      updatedReportReasons[userId] = reason;
      updatedReportTimestamps[userId] = DateTime.now();

      final updatedRequest = request.copyWith(
        validityStatus: updatedValidityStatus,
        reportReasons: updatedReportReasons,
        reportTimestamps: updatedReportTimestamps,
      );
      
      _paymentRequests[requestIndex] = updatedRequest;
      await _savePaymentRequests();
      notifyListeners();
    }
  }

  // Get the validity status for a specific user and request
  RequestValidityStatus getRequestValidityStatus(String paymentRequestId, String userId) {
    final request = getPaymentRequestById(paymentRequestId);
    if (request != null) {
      return request.validityStatus[userId] ?? RequestValidityStatus.valid;
    }
    return RequestValidityStatus.valid;
  }

  // Get invalidation reason for a specific user and request
  String? getInvalidationReason(String paymentRequestId, String userId) {
    final request = getPaymentRequestById(paymentRequestId);
    if (request != null) {
      return request.invalidationReasons[userId];
    }
    return null;
  }

  // Get report reason for a specific user and request
  String? getReportReason(String paymentRequestId, String userId) {
    final request = getPaymentRequestById(paymentRequestId);
    if (request != null) {
      return request.reportReasons[userId];
    }
    return null;
  }

  Future<void> payAmount(
    String paymentRequestId,
    String fromUserId,
    String toUserId,
    double amount,
  ) async {
    // Update payment status
    await updatePaymentStatus(paymentRequestId, fromUserId, PaymentStatus.paid);

    // Record transaction
    final transaction = {
      'id': _uuid.v4(),
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'paymentRequestId': paymentRequestId,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'group_payment',
    };

    _transactions.add(transaction);
    await _saveTransactions();
    notifyListeners();
  }

  List<PaymentRequest> getPaymentRequestsForUser(String userId) {
    return _paymentRequests.where((req) => 
      (req.requestedBy == userId || 
      req.paymentStatus.containsKey(userId)) && req.isActive
    ).toList();
  }

  List<PaymentRequest> getPaymentRequestsForGroup(String groupId) {
    return _paymentRequests.where((req) => req.groupId == groupId && req.isActive).toList();
  }

  List<PaymentRequest> getPendingPaymentRequestsForUser(String userId) {
    return _paymentRequests.where((req) => 
      req.paymentStatus[userId] == PaymentStatus.pending && req.isActive
    ).toList();
  }

  double getTotalOwedByUser(String userId) {
    double total = 0.0;
    for (final request in _paymentRequests) {
      if (request.paymentStatus[userId] == PaymentStatus.pending && request.isActive) {
        // Check if the user has marked this request as invalid or fraudulent
        final validityStatus = request.validityStatus[userId] ?? RequestValidityStatus.valid;
        if (validityStatus == RequestValidityStatus.valid) {
          // Don't include requests where the user is the requester
          if (request.requestedBy != userId) {
            // Get the specific amount this user owes for this request
            final amount = request.getAmountForUser(userId, request.paymentStatus.keys.toList());
            total += amount;
          }
        }
        // If marked as invalid or fraudulent, don't include in total owed
      }
    }
    return total;
  }

  double getTotalOwedToUser(String userId) {
    double total = 0.0;
    for (final request in _paymentRequests) {
      if (request.requestedBy == userId && !request.isCompleted && request.isActive) {
        // Calculate the amount owed based on pending payments only
        for (final entry in request.paymentStatus.entries) {
          final memberId = entry.key;
          final status = entry.value;
          
          if (status == PaymentStatus.pending) {
            // Don't include the requester's own share in the total owed to them
            if (memberId != userId) {
              // Get the amount this specific member owes
              final amount = request.getAmountForUser(memberId, request.paymentStatus.keys.toList());
              total += amount;
            }
          }
        }
      }
    }
    return total;
  }

  List<Map<String, dynamic>> getTransactionsForUser(String userId) {
    return _transactions.where((t) => 
      t['fromUserId'] == userId || t['toUserId'] == userId
    ).toList();
  }

  Future<void> deletePaymentRequest(String paymentRequestId) async {
    _paymentRequests.removeWhere((req) => req.id == paymentRequestId);
    await _savePaymentRequests();
    notifyListeners();
  }

  PaymentRequest? getPaymentRequestById(String paymentRequestId) {
    try {
      return _paymentRequests.firstWhere((req) => req.id == paymentRequestId);
    } catch (e) {
      return null;
    }
  }

  // Get all recurring payment requests
  List<PaymentRequest> getRecurringPaymentRequests() {
    return _paymentRequests.where((req) => req.isRecurring && req.isActive).toList();
  }

  // Get recurring payment requests for a specific user
  List<PaymentRequest> getRecurringPaymentRequestsForUser(String userId) {
    return _paymentRequests.where((req) => 
      req.isRecurring && 
      req.isActive && 
      (req.requestedBy == userId || req.paymentStatus.containsKey(userId))
    ).toList();
  }

  // Kill a recurring payment request (set isActive to false)
  Future<void> killRecurringRequest(String paymentRequestId) async {
    final requestIndex = _paymentRequests.indexWhere((req) => req.id == paymentRequestId);
    if (requestIndex != -1) {
      final request = _paymentRequests[requestIndex];
      final updatedRequest = request.copyWith(isActive: false);
      _paymentRequests[requestIndex] = updatedRequest;
      await _savePaymentRequests();
      notifyListeners();
    }
  }

  // Draft management methods
  Future<PaymentDraft> createDraft({
    required String userId,
    required DraftType type,
    String? groupId,
    double? totalAmount,
    String? description,
    List<String> selectedUserIds = const [],
    Map<String, double> customAmounts = const {},
    bool includeSelf = false,
  }) async {
    final draft = PaymentDraft(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      groupId: groupId,
      totalAmount: totalAmount,
      description: description,
      selectedUserIds: selectedUserIds,
      customAmounts: customAmounts,
      includeSelf: includeSelf,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _paymentDrafts.add(draft);
    await _savePaymentDrafts();
    notifyListeners();

    return draft;
  }

  // Convert draft to payment request and delete the draft
  Future<PaymentRequest> convertDraftToRequest({
    required String draftId,
    required String groupId,
    required String requestedBy,
    required List<String> groupMembers,
    List<String> exemptedMembers = const [],
    bool isRecurring = false,
    int? recurringInterval,
    RecurringFrequency? recurringFrequency,
  }) async {
    final draft = getDraftById(draftId);
    if (draft == null) {
      throw Exception('Draft not found');
    }

    // Create the payment request
    final paymentRequest = await createPaymentRequest(
      groupId: groupId,
      requestedBy: requestedBy,
      totalAmount: draft.totalAmount ?? 0.0,
      description: draft.description ?? 'Payment request',
      includeRequester: draft.includeSelf,
      exemptedMembers: exemptedMembers,
      customAmounts: draft.customAmounts,
      groupMembers: groupMembers,
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
      recurringFrequency: recurringFrequency,
    );

    // Delete the draft
    await deleteDraft(draftId);

    return paymentRequest;
  }

  Future<void> updateDraft(PaymentDraft draft) async {
    final index = _paymentDrafts.indexWhere((d) => d.id == draft.id);
    if (index != -1) {
      _paymentDrafts[index] = draft.copyWith(updatedAt: DateTime.now());
      await _savePaymentDrafts();
      notifyListeners();
    }
  }

  Future<void> deleteDraft(String draftId) async {
    _paymentDrafts.removeWhere((draft) => draft.id == draftId);
    await _savePaymentDrafts();
    notifyListeners();
  }

  List<PaymentDraft> getDraftsForUser(String userId) {
    return _paymentDrafts.where((draft) => draft.userId == userId).toList();
  }

  PaymentDraft? getDraftById(String draftId) {
    try {
      return _paymentDrafts.firstWhere((draft) => draft.id == draftId);
    } catch (e) {
      return null;
    }
  }

  // Get all payment requests (active and inactive)
  List<PaymentRequest> getAllPaymentRequests() {
    return _paymentRequests;
  }

  // Get all payment requests for a specific user
  List<PaymentRequest> getAllPaymentRequestsForUser(String userId) {
    return _paymentRequests
        .where((request) => request.requestedBy == userId)
        .toList();
  }

  // Kill/Delete a payment request (mark as inactive)
  void killPaymentRequest(String requestId) {
    final requestIndex = _paymentRequests.indexWhere((req) => req.id == requestId);
    if (requestIndex != -1) {
      final request = _paymentRequests[requestIndex];
      _paymentRequests[requestIndex] = request.copyWith(isActive: false);
      _savePaymentRequests();
      notifyListeners();
    }
  }

  // Kill/Delete all payment requests
  void killAllPaymentRequests() {
    for (int i = 0; i < _paymentRequests.length; i++) {
      _paymentRequests[i] = _paymentRequests[i].copyWith(isActive: false);
    }
    _savePaymentRequests();
    notifyListeners();
  }

  // Demo method to create sample payment requests
  Future<void> createDemoPaymentRequests() async {
    // Get the current user ID from auth provider
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    String currentUserId = 'user_1'; // Default fallback
    
    print('User JSON: $userJson');
    
    if (userJson != null) {
      try {
        // Parse the JSON string to Map
        final userData = Map<String, dynamic>.from(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
        currentUserId = userData['id'] ?? 'user_1';
        print('Current user ID: $currentUserId');
      } catch (e) {
        debugPrint('Error parsing user data: $e');
      }
    }
    
    final demoRequests = [
      PaymentRequest(
        id: 'demo-request-1',
        groupId: 'personal',
        requestedBy: 'user_2', // Jane Smith
        totalAmount: 35.50,
        description: 'Lunch at Italian restaurant',
        includeRequester: true,
        exemptedMembers: [],
        customAmounts: {currentUserId: 35.50}, // Current user owes $35.50
        paymentStatus: {currentUserId: PaymentStatus.pending},
        partialPayments: {currentUserId: 0.0},
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isActive: true,
        validityStatus: {},
        invalidationReasons: {},
        reportReasons: {},
        invalidationTimestamps: {},
        reportTimestamps: {},
      ),
      PaymentRequest(
        id: 'demo-request-2',
        groupId: 'personal',
        requestedBy: 'user_4', // Sarah Wilson
        totalAmount: 120.00,
        description: 'Weekend trip expenses',
        includeRequester: true,
        exemptedMembers: [],
        customAmounts: {currentUserId: 60.00}, // Current user owes $60.00
        paymentStatus: {currentUserId: PaymentStatus.pending},
        partialPayments: {currentUserId: 0.0},
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
        validityStatus: {},
        invalidationReasons: {},
        reportReasons: {},
        invalidationTimestamps: {},
        reportTimestamps: {},
      ),
      PaymentRequest(
        id: 'demo-request-3',
        groupId: 'personal',
        requestedBy: 'user_6', // Emily Davis
        totalAmount: 45.75,
        description: 'Coffee and snacks for team meeting',
        includeRequester: true,
        exemptedMembers: [],
        customAmounts: {currentUserId: 45.75}, // Current user owes $45.75
        paymentStatus: {currentUserId: PaymentStatus.pending},
        partialPayments: {currentUserId: 0.0},
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        isActive: true,
        validityStatus: {},
        invalidationReasons: {},
        reportReasons: {},
        invalidationTimestamps: {},
        reportTimestamps: {},
      ),
      PaymentRequest(
        id: 'demo-request-4',
        groupId: 'personal',
        requestedBy: 'user_8', // Lisa Anderson
        totalAmount: 85.00,
        description: 'Movie tickets and dinner',
        includeRequester: true,
        exemptedMembers: [],
        customAmounts: {currentUserId: 42.50}, // Current user owes $42.50
        paymentStatus: {currentUserId: PaymentStatus.pending},
        partialPayments: {currentUserId: 0.0},
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isActive: true,
        validityStatus: {},
        invalidationReasons: {},
        reportReasons: {},
        invalidationTimestamps: {},
        reportTimestamps: {},
      ),
      PaymentRequest(
        id: 'demo-request-5',
        groupId: 'personal',
        requestedBy: 'user_3', // Mike Johnson
        totalAmount: 28.00,
        description: 'Uber ride to airport',
        includeRequester: true,
        exemptedMembers: [],
        customAmounts: {currentUserId: 28.00}, // Current user owes $28.00
        paymentStatus: {currentUserId: PaymentStatus.pending},
        partialPayments: {currentUserId: 0.0},
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isActive: true,
        validityStatus: {},
        invalidationReasons: {},
        reportReasons: {},
        invalidationTimestamps: {},
        reportTimestamps: {},
      ),
    ];

    _paymentRequests.addAll(demoRequests);
    await _savePaymentRequests();
    notifyListeners();
  }

  // Demo method to create sample transaction data
  Future<void> createDemoTransactions() async {
    // Get the current user ID from auth provider
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    String currentUserId = 'user_1'; // Default fallback
    
    if (userJson != null) {
      try {
        // Parse the JSON string to Map
        final userData = Map<String, dynamic>.from(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
        currentUserId = userData['id'] ?? 'user_1';
      } catch (e) {
        debugPrint('Error parsing user data: $e');
      }
    }
    
    final demoTransactions = [
      {
        'id': 'demo-1',
        'fromUserId': currentUserId,
        'toUserId': 'user_2',
        'amount': 25.50,
        'paymentRequestId': 'demo-request-1',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'type': 'direct_transfer',
        'description': 'Lunch payment',
      },
      {
        'id': 'demo-2',
        'fromUserId': 'user_3',
        'toUserId': currentUserId,
        'amount': 15.75,
        'paymentRequestId': 'demo-request-2',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'type': 'direct_transfer',
        'description': 'Coffee payment',
      },
      {
        'id': 'demo-3',
        'fromUserId': currentUserId,
        'toUserId': 'user_4',
        'amount': 45.00,
        'paymentRequestId': 'demo-request-3',
        'timestamp': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        'type': 'direct_transfer',
        'description': 'Dinner split',
      },
      {
        'id': 'demo-4',
        'fromUserId': 'user_2',
        'toUserId': currentUserId,
        'amount': 12.30,
        'paymentRequestId': 'demo-request-4',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'type': 'direct_transfer',
        'description': 'Movie tickets',
      },
      {
        'id': 'demo-5',
        'fromUserId': currentUserId,
        'toUserId': 'user_3',
        'amount': 8.50,
        'paymentRequestId': 'demo-request-5',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        'type': 'direct_transfer',
        'description': 'Snack payment',
      },
      {
        'id': 'demo-6',
        'fromUserId': 'user_6',
        'toUserId': currentUserId,
        'amount': 18.75,
        'paymentRequestId': 'demo-request-6',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'type': 'direct_transfer',
        'description': 'Coffee and pastry',
      },
      {
        'id': 'demo-7',
        'fromUserId': currentUserId,
        'toUserId': 'user_7',
        'amount': 32.00,
        'paymentRequestId': 'demo-request-7',
        'timestamp': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'type': 'direct_transfer',
        'description': 'Lunch meeting',
      },
      {
        'id': 'demo-8',
        'fromUserId': 'user_8',
        'toUserId': currentUserId,
        'amount': 25.50,
        'paymentRequestId': 'demo-request-8',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'type': 'direct_transfer',
        'description': 'Dinner split',
      },
    ];

    _transactions.addAll(demoTransactions);
    await _saveTransactions();
    notifyListeners();
  }

  // Method to send money directly to another user
  Future<void> sendMoney({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String description,
  }) async {
    final transaction = {
      'id': _uuid.v4(),
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'paymentRequestId': null, // Direct transfer, not part of a payment request
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'direct_transfer',
      'description': description,
    };

    _transactions.add(transaction);
    await _saveTransactions();
    notifyListeners();
  }

  // Method to clear all demo data
  Future<void> clearDemoData() async {
    _paymentRequests.clear();
    _paymentDrafts.clear();
    _transactions.clear();
    
    await _savePaymentRequests();
    await _savePaymentDrafts();
    await _saveTransactions();
    
    notifyListeners();
  }
} 