import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/budget_model.dart';

class BudgetsNotifier extends StateNotifier<List<BudgetModel>> {
  BudgetsNotifier(this._ref) : super([]);

  final Ref _ref;

  void clear() {
    state = [];
  }

  Future<void> sync() async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get<List<dynamic>>('/api/budgets');
    state = (response.data ?? [])
        .map((j) => BudgetModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/budgets — server returns 201 with the created object including
  /// the server-assigned id and live `spent` value.
  Future<void> create({
    required String category,
    required double allocated,
    required String colorHex,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.post<Map<String, dynamic>>(
      '/api/budgets',
      data: {'category': category, 'allocated': allocated, 'color': colorHex},
    );
    final created = BudgetModel.fromJson(response.data!);
    state = [...state, created];
  }

  /// PATCH /api/budgets/{id} — only sends fields that changed.
  Future<void> update(
    String id, {
    double? allocated,
    String? colorHex,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final body = <String, dynamic>{
      if (allocated != null) 'allocated': allocated,
      if (colorHex != null) 'color': colorHex,
    };
    final response = await dio.patch<Map<String, dynamic>>(
      '/api/budgets/$id',
      data: body,
    );
    final updated = BudgetModel.fromJson(response.data!);
    state = [
      for (final b in state)
        if (b.id == id) updated else b,
    ];
  }

  /// DELETE /api/budgets/{id} — server returns 204 No Content.
  Future<void> delete(String id) async {
    final dio = _ref.read(apiClientProvider);
    await dio.delete<void>('/api/budgets/$id');
    state = state.where((b) => b.id != id).toList();
  }
}

final budgetsProvider =
    StateNotifierProvider<BudgetsNotifier, List<BudgetModel>>(
  (ref) => BudgetsNotifier(ref),
);
