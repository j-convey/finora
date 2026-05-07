import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/subscription_model.dart';

class SubscriptionsNotifier extends StateNotifier<List<SubscriptionModel>> {
  SubscriptionsNotifier(this._ref) : super([]);

  final Ref _ref;

  void clear() {
    state = [];
  }

  Future<void> sync() async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get<List<dynamic>>('/api/subscriptions');
    state = (response.data ?? [])
        .map((j) => SubscriptionModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/subscriptions — server returns 201 with the created object
  Future<void> create({
    required String name,
    String? merchantName,
    String? category,
    double? expectedAmount,
    double? minAmount,
    double? maxAmount,
    int? recurrenceInterval,
    String? recurrenceUnit,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    String? status,
    bool? autoLinkEnabled,
    String? matchingNotes,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final body = <String, dynamic>{
      'name': name,
      'merchant_name': merchantName,
      'category': category,
      'expected_amount': expectedAmount,
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'recurrence_interval': recurrenceInterval ?? 1,
      'recurrence_unit': recurrenceUnit ?? 'month',
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'next_due_date': nextDueDate?.toIso8601String(),
      'status': status ?? 'active',
      'auto_link_enabled': autoLinkEnabled ?? true,
      'matching_notes': matchingNotes,
    };
    final response = await dio.post<Map<String, dynamic>>(
      '/api/subscriptions',
      data: body,
    );
    final created = SubscriptionModel.fromJson(response.data!);
    state = [...state, created];
  }

  /// PATCH /api/subscriptions/{id}
  Future<void> update(
    String id, {
    String? name,
    String? merchantName,
    String? category,
    double? expectedAmount,
    double? minAmount,
    double? maxAmount,
    int? recurrenceInterval,
    String? recurrenceUnit,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    String? status,
    bool? autoLinkEnabled,
    String? matchingNotes,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (merchantName != null) 'merchant_name': merchantName,
      if (category != null) 'category': category,
      if (expectedAmount != null) 'expected_amount': expectedAmount,
      if (minAmount != null) 'min_amount': minAmount,
      if (maxAmount != null) 'max_amount': maxAmount,
      if (recurrenceInterval != null) 'recurrence_interval': recurrenceInterval,
      if (recurrenceUnit != null) 'recurrence_unit': recurrenceUnit,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (nextDueDate != null) 'next_due_date': nextDueDate.toIso8601String(),
      if (status != null) 'status': status,
      if (autoLinkEnabled != null) 'auto_link_enabled': autoLinkEnabled,
      if (matchingNotes != null) 'matching_notes': matchingNotes,
    };
    final response = await dio.patch<Map<String, dynamic>>(
      '/api/subscriptions/$id',
      data: body,
    );
    final updated = SubscriptionModel.fromJson(response.data!);
    state = [
      for (final s in state)
        if (s.id == id) updated else s,
    ];
  }

  /// DELETE /api/subscriptions/{id}
  Future<void> delete(String id) async {
    final dio = _ref.read(apiClientProvider);
    await dio.delete<void>('/api/subscriptions/$id');
    state = state.where((s) => s.id != id).toList();
  }
}

final subscriptionsProvider =
    StateNotifierProvider<SubscriptionsNotifier, List<SubscriptionModel>>(
  (ref) => SubscriptionsNotifier(ref),
);
