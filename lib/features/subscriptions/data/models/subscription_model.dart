import 'package:flutter/material.dart';

enum SubscriptionStatus { active, paused, canceled }

enum RecurrenceUnit { day, week, month, year }

class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.name,
    required this.merchantName,
    required this.category,
    required this.expectedAmount,
    required this.minAmount,
    required this.maxAmount,
    required this.recurrenceInterval,
    required this.recurrenceUnit,
    required this.startDate,
    required this.endDate,
    required this.nextDueDate,
    required this.status,
    required this.autoLinkEnabled,
    required this.matchingNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? merchantName;
  final String? category;
  final double? expectedAmount;
  final double? minAmount;
  final double? maxAmount;
  final int recurrenceInterval;
  final RecurrenceUnit recurrenceUnit;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? nextDueDate;
  final SubscriptionStatus status;
  final bool autoLinkEnabled;
  final String? matchingNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get recurrenceLabel {
    final interval = recurrenceInterval > 1 ? '${recurrenceInterval} ' : '';
    return switch (recurrenceUnit) {
      RecurrenceUnit.day => '${interval}day${recurrenceInterval > 1 ? 's' : ''}',
      RecurrenceUnit.week => '${interval}week${recurrenceInterval > 1 ? 's' : ''}',
      RecurrenceUnit.month => '${interval}month${recurrenceInterval > 1 ? 's' : ''}',
      RecurrenceUnit.year => '${interval}year${recurrenceInterval > 1 ? 's' : ''}',
    };
  }

  String get statusLabel => switch (status) {
    SubscriptionStatus.active => 'Active',
    SubscriptionStatus.paused => 'Paused',
    SubscriptionStatus.canceled => 'Canceled',
  };

  Color get statusColor => switch (status) {
    SubscriptionStatus.active => const Color(0xFF4CAF50),
    SubscriptionStatus.paused => const Color(0xFFFFA726),
    SubscriptionStatus.canceled => const Color(0xFFEF5350),
  };

  static SubscriptionStatus _parseStatus(String value) {
    return SubscriptionStatus.values
        .firstWhere((s) => s.toString().split('.').last == value);
  }

  static RecurrenceUnit _parseRecurrenceUnit(String value) {
    return RecurrenceUnit.values
        .firstWhere((u) => u.toString().split('.').last == value);
  }

  SubscriptionModel copyWith({
    String? id,
    String? name,
    String? merchantName,
    String? category,
    double? expectedAmount,
    double? minAmount,
    double? maxAmount,
    int? recurrenceInterval,
    RecurrenceUnit? recurrenceUnit,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    SubscriptionStatus? status,
    bool? autoLinkEnabled,
    String? matchingNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SubscriptionModel(
        id: id ?? this.id,
        name: name ?? this.name,
        merchantName: merchantName ?? this.merchantName,
        category: category ?? this.category,
        expectedAmount: expectedAmount ?? this.expectedAmount,
        minAmount: minAmount ?? this.minAmount,
        maxAmount: maxAmount ?? this.maxAmount,
        recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
        recurrenceUnit: recurrenceUnit ?? this.recurrenceUnit,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        status: status ?? this.status,
        autoLinkEnabled: autoLinkEnabled ?? this.autoLinkEnabled,
        matchingNotes: matchingNotes ?? this.matchingNotes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      merchantName: json['merchant_name'] as String?,
      category: json['category'] as String?,
      expectedAmount: json['expected_amount'] != null
          ? (json['expected_amount'] as num).toDouble()
          : null,
      minAmount: json['min_amount'] != null
          ? (json['min_amount'] as num).toDouble()
          : null,
      maxAmount: json['max_amount'] != null
          ? (json['max_amount'] as num).toDouble()
          : null,
      recurrenceInterval: json['recurrence_interval'] as int? ?? 1,
      recurrenceUnit:
          _parseRecurrenceUnit(json['recurrence_unit'] as String? ?? 'month'),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'] as String)
          : null,
      status: _parseStatus(json['status'] as String? ?? 'active'),
      autoLinkEnabled: json['auto_link_enabled'] as bool? ?? true,
      matchingNotes: json['matching_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'merchant_name': merchantName,
    'category': category,
    'expected_amount': expectedAmount,
    'min_amount': minAmount,
    'max_amount': maxAmount,
    'recurrence_interval': recurrenceInterval,
    'recurrence_unit': recurrenceUnit.toString().split('.').last,
    'start_date': startDate?.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'next_due_date': nextDueDate?.toIso8601String(),
    'status': status.toString().split('.').last,
    'auto_link_enabled': autoLinkEnabled,
    'matching_notes': matchingNotes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
