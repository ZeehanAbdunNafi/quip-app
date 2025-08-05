enum DraftType { evenSplit, variedSplit }

class PaymentDraft {
  final String id;
  final String userId;
  final DraftType type;
  final String? groupId;
  final double? totalAmount;
  final String? description;
  final List<String> selectedUserIds;
  final Map<String, double> customAmounts;
  final bool includeSelf;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentDraft({
    required this.id,
    required this.userId,
    required this.type,
    this.groupId,
    this.totalAmount,
    this.description,
    required this.selectedUserIds,
    required this.customAmounts,
    required this.includeSelf,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentDraft.fromJson(Map<String, dynamic> json) {
    return PaymentDraft(
      id: json['id'],
      userId: json['userId'],
      type: DraftType.values.firstWhere(
        (e) => e.toString() == 'DraftType.${json['type']}',
        orElse: () => DraftType.evenSplit,
      ),
      groupId: json['groupId'],
      totalAmount: json['totalAmount']?.toDouble(),
      description: json['description'],
      selectedUserIds: List<String>.from(json['selectedUserIds'] ?? []),
      customAmounts: Map<String, double>.from(
        (json['customAmounts'] ?? {}).map(
          (key, value) => MapEntry(key, (value ?? 0.0).toDouble()),
        ),
      ),
      includeSelf: json['includeSelf'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'groupId': groupId,
      'totalAmount': totalAmount,
      'description': description,
      'selectedUserIds': selectedUserIds,
      'customAmounts': customAmounts,
      'includeSelf': includeSelf,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PaymentDraft copyWith({
    String? id,
    String? userId,
    DraftType? type,
    String? groupId,
    double? totalAmount,
    String? description,
    List<String>? selectedUserIds,
    Map<String, double>? customAmounts,
    bool? includeSelf,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentDraft(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      groupId: groupId ?? this.groupId,
      totalAmount: totalAmount ?? this.totalAmount,
      description: description ?? this.description,
      selectedUserIds: selectedUserIds ?? this.selectedUserIds,
      customAmounts: customAmounts ?? this.customAmounts,
      includeSelf: includeSelf ?? this.includeSelf,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isComplete {
    switch (type) {
      case DraftType.evenSplit:
        return totalAmount != null && totalAmount! > 0 && selectedUserIds.isNotEmpty;
      case DraftType.variedSplit:
        return customAmounts.isNotEmpty && selectedUserIds.isNotEmpty;
    }
  }

  String get displayTitle {
    return 'Split Request';
  }

  String get displaySubtitle {
    if (totalAmount != null && totalAmount! > 0) {
      return '\$${totalAmount!.toStringAsFixed(2)}';
    }
    return 'Draft';
  }
} 