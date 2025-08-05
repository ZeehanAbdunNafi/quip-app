enum PaymentStatus { pending, paid, cancelled, partial }

enum RecurringFrequency { daily, weekly, monthly }

enum RequestValidityStatus { valid, invalid, reported }

class PaymentRequest {
  final String id;
  final String groupId;
  final String requestedBy;
  final double totalAmount;
  final String description;
  final bool includeRequester;
  final List<String> exemptedMembers;
  final Map<String, double> customAmounts; // userId -> amount
  final Map<String, PaymentStatus> paymentStatus; // userId -> status
  final Map<String, double> partialPayments; // userId -> partial amount paid
  final DateTime createdAt;
  final DateTime? completedAt;
  
  // Recurring request fields
  final bool isRecurring;
  final int? recurringInterval;
  final RecurringFrequency? recurringFrequency;
  final String? recurringParentId; // ID of the parent recurring request
  final bool isActive; // Whether the recurring request is still active

  // Invalidation and reporting fields
  final Map<String, RequestValidityStatus> validityStatus; // userId -> validity status
  final Map<String, String> invalidationReasons; // userId -> reason for invalidation
  final Map<String, String> reportReasons; // userId -> reason for reporting
  final Map<String, DateTime> invalidationTimestamps; // userId -> when marked as invalid
  final Map<String, DateTime> reportTimestamps; // userId -> when reported

  PaymentRequest({
    required this.id,
    required this.groupId,
    required this.requestedBy,
    required this.totalAmount,
    required this.description,
    required this.includeRequester,
    required this.exemptedMembers,
    required this.customAmounts,
    required this.paymentStatus,
    required this.partialPayments,
    required this.createdAt,
    this.completedAt,
    this.isRecurring = false,
    this.recurringInterval,
    this.recurringFrequency,
    this.recurringParentId,
    this.isActive = true,
    Map<String, RequestValidityStatus>? validityStatus,
    Map<String, String>? invalidationReasons,
    Map<String, String>? reportReasons,
    Map<String, DateTime>? invalidationTimestamps,
    Map<String, DateTime>? reportTimestamps,
  }) : 
    validityStatus = validityStatus ?? {},
    invalidationReasons = invalidationReasons ?? {},
    reportReasons = reportReasons ?? {},
    invalidationTimestamps = invalidationTimestamps ?? {},
    reportTimestamps = reportTimestamps ?? {};

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'],
      groupId: json['groupId'],
      requestedBy: json['requestedBy'],
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      description: json['description'],
      includeRequester: json['includeRequester'] ?? false,
      exemptedMembers: List<String>.from(json['exemptedMembers'] ?? []),
      customAmounts: Map<String, double>.from(
        (json['customAmounts'] ?? {}).map(
          (key, value) => MapEntry(key, (value ?? 0.0).toDouble()),
        ),
      ),
      paymentStatus: Map<String, PaymentStatus>.from(
        (json['paymentStatus'] ?? {}).map(
          (key, value) => MapEntry(key, PaymentStatus.values.firstWhere(
            (e) => e.toString() == 'PaymentStatus.$value',
            orElse: () => PaymentStatus.pending,
          )),
        ),
      ),
      partialPayments: Map<String, double>.from(
        (json['partialPayments'] ?? {}).map(
          (key, value) => MapEntry(key, (value ?? 0.0).toDouble()),
        ),
      ),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      isRecurring: json['isRecurring'] ?? false,
      recurringInterval: json['recurringInterval'],
      recurringFrequency: json['recurringFrequency'] != null 
          ? RecurringFrequency.values.firstWhere(
              (e) => e.toString() == 'RecurringFrequency.${json['recurringFrequency']}',
              orElse: () => RecurringFrequency.weekly,
            )
          : null,
      recurringParentId: json['recurringParentId'],
      isActive: json['isActive'] ?? true,
      validityStatus: Map<String, RequestValidityStatus>.from(
        (json['validityStatus'] ?? {}).map(
          (key, value) => MapEntry(key, RequestValidityStatus.values.firstWhere(
            (e) => e.toString() == 'RequestValidityStatus.$value',
            orElse: () => RequestValidityStatus.valid,
          )),
        ),
      ),
      invalidationReasons: Map<String, String>.from(json['invalidationReasons'] ?? {}),
      reportReasons: Map<String, String>.from(json['reportReasons'] ?? {}),
      invalidationTimestamps: Map<String, DateTime>.from(
        (json['invalidationTimestamps'] ?? {}).map(
          (key, value) => MapEntry(key, DateTime.parse(value)),
        ),
      ),
      reportTimestamps: Map<String, DateTime>.from(
        (json['reportTimestamps'] ?? {}).map(
          (key, value) => MapEntry(key, DateTime.parse(value)),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'requestedBy': requestedBy,
      'totalAmount': totalAmount,
      'description': description,
      'includeRequester': includeRequester,
      'exemptedMembers': exemptedMembers,
      'customAmounts': customAmounts,
      'paymentStatus': paymentStatus.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'partialPayments': partialPayments,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isRecurring': isRecurring,
      'recurringInterval': recurringInterval,
      'recurringFrequency': recurringFrequency?.toString().split('.').last,
      'recurringParentId': recurringParentId,
      'isActive': isActive,
      'validityStatus': validityStatus.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'invalidationReasons': invalidationReasons,
      'reportReasons': reportReasons,
      'invalidationTimestamps': invalidationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'reportTimestamps': reportTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }

  // Calculate the amount each person should pay
  double calculateAmountPerPerson(List<String> groupMembers) {
    List<String> payingMembers = groupMembers
        .where((memberId) => !exemptedMembers.contains(memberId))
        .toList();

    if (!includeRequester) {
      payingMembers.remove(requestedBy);
    }

    if (payingMembers.isEmpty) return 0.0;

    // If custom amounts are specified, use them
    if (customAmounts.isNotEmpty) {
      double customTotal = customAmounts.values.fold(0.0, (sum, amount) => sum + amount);
      if (customTotal > 0) {
        return customTotal / payingMembers.length;
      }
    }

    // Otherwise, divide equally
    return totalAmount / payingMembers.length;
  }

  // Get the amount a specific user should pay
  double getAmountForUser(String userId, List<String> groupMembers) {
    if (exemptedMembers.contains(userId)) return 0.0;
    
    if (customAmounts.containsKey(userId)) {
      return customAmounts[userId]!;
    }

    return calculateAmountPerPerson(groupMembers);
  }

  // Check if all payments are completed
  bool get isCompleted {
    return paymentStatus.values.every((status) => status == PaymentStatus.paid);
  }

  // Get pending payments count
  int get pendingPaymentsCount {
    return paymentStatus.values.where((status) => status == PaymentStatus.pending).length;
  }

  // Get the amount a user has partially paid
  double getPartialPaymentAmount(String userId) {
    return partialPayments[userId] ?? 0.0;
  }

  // Get the remaining amount a user needs to pay
  double getRemainingAmount(String userId, List<String> groupMembers) {
    final totalAmount = getAmountForUser(userId, groupMembers);
    final partialAmount = getPartialPaymentAmount(userId);
    return (totalAmount - partialAmount).clamp(0.0, totalAmount);
  }

  // Check if a user has made any partial payment
  bool hasPartialPayment(String userId) {
    return partialPayments.containsKey(userId) && partialPayments[userId]! > 0;
  }

  PaymentRequest copyWith({
    String? id,
    String? groupId,
    String? requestedBy,
    double? totalAmount,
    String? description,
    bool? includeRequester,
    List<String>? exemptedMembers,
    Map<String, double>? customAmounts,
    Map<String, PaymentStatus>? paymentStatus,
    Map<String, double>? partialPayments,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isRecurring,
    int? recurringInterval,
    RecurringFrequency? recurringFrequency,
    String? recurringParentId,
    bool? isActive,
    Map<String, RequestValidityStatus>? validityStatus,
    Map<String, String>? invalidationReasons,
    Map<String, String>? reportReasons,
    Map<String, DateTime>? invalidationTimestamps,
    Map<String, DateTime>? reportTimestamps,
  }) {
    return PaymentRequest(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      requestedBy: requestedBy ?? this.requestedBy,
      totalAmount: totalAmount ?? this.totalAmount,
      description: description ?? this.description,
      includeRequester: includeRequester ?? this.includeRequester,
      exemptedMembers: exemptedMembers ?? this.exemptedMembers,
      customAmounts: customAmounts ?? this.customAmounts,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      partialPayments: partialPayments ?? this.partialPayments,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      recurringParentId: recurringParentId ?? this.recurringParentId,
      isActive: isActive ?? this.isActive,
      validityStatus: validityStatus ?? this.validityStatus,
      invalidationReasons: invalidationReasons ?? this.invalidationReasons,
      reportReasons: reportReasons ?? this.reportReasons,
      invalidationTimestamps: invalidationTimestamps ?? this.invalidationTimestamps,
      reportTimestamps: reportTimestamps ?? this.reportTimestamps,
    );
  }
} 