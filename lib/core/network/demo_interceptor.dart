import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

/// Intercepts all Dio requests when Demo Mode is active and resolves them
/// with data loaded from the CSV files in assets/demo/.
///
/// Edit any file under assets/demo/ and rebuild to update the demo dataset.
/// The CSVs are parsed once and cached for the lifetime of the interceptor.
class DemoInterceptor extends Interceptor {
  // Parsed CSV data — null until first request arrives.
  List<Map<String, dynamic>>? _accounts;
  List<Map<String, dynamic>>? _transactions;
  List<Map<String, dynamic>>? _budgets;
  List<Map<String, dynamic>>? _subscriptions;
  List<Map<String, dynamic>>? _netWorthHistory;
  List<Map<String, dynamic>>? _categories;

  bool _loaded = false;

  // ── Loading ─────────────────────────────────────────────────────────────────

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    _accounts = await _loadCsv('assets/demo/accounts.csv');
    _transactions = await _loadCsv('assets/demo/transactions.csv');
    _budgets = await _loadCsv('assets/demo/budgets.csv');
    _subscriptions = await _loadCsv('assets/demo/subscriptions.csv');
    _netWorthHistory = await _loadCsv('assets/demo/net_worth_history.csv');

    final catRows = await _loadCsv('assets/demo/categories.csv');

    // Build grouped structure matching the real API: [{ group, type, categories }]
    // Each category is { id: int, name: string }. IDs start at 1 (sort_order + 1),
    // matching the canonical IDs assigned by server migration 012.
    final groupOrder = <String>[];
    final groupMap = <String, Map<String, dynamic>>{};
    int idCounter = 1;
    for (final row in catRows) {
      final group = row['group'] as String;
      final type = row['type'] as String;
      final name = row['name'] as String;
      if (!groupMap.containsKey(group)) {
        groupOrder.add(group);
        groupMap[group] = {'group': group, 'type': type, 'categories': <Map<String, dynamic>>[]};
      }
      (groupMap[group]!['categories'] as List<Map<String, dynamic>>)
          .add({'id': idCounter, 'name': name});
      idCounter++;
    }
    _categories = groupOrder.map((g) => groupMap[g]!).toList();

    // Apply computed fields that the backend normally derives.
    _transactions = _transactions!.map(_enrichTransaction).toList();
    _subscriptions = _subscriptions!.map(_enrichSubscription).toList();
    _accounts = _accounts!.map(_enrichAccount).toList();

    _loaded = true;
  }

  /// Parses a CSV asset file and returns a list of row maps keyed by header.
  static Future<List<Map<String, dynamic>>> _loadCsv(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final rows = const CsvToListConverter(eol: '\n').convert(raw);
    if (rows.length < 2) return [];

    final headers = rows.first.map((h) => h.toString().trim()).toList();
    return rows.skip(1).map((row) {
      final map = <String, dynamic>{};
      for (var i = 0; i < headers.length; i++) {
        final raw = i < row.length ? row[i] : null;
        map[headers[i]] = _coerce(raw);
      }
      return map;
    }).toList();
  }

  /// Coerces parsed CSV values to sensible Dart types.
  static dynamic _coerce(dynamic value) {
    if (value == null || value == '') return null;
    if (value is int || value is double || value is bool) return value;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    if (str == 'true') return true;
    if (str == 'false') return false;
    final num = double.tryParse(str);
    if (num != null) return num;
    return str;
  }

  // ── Field enrichment ────────────────────────────────────────────────────────

  static Map<String, dynamic> _enrichTransaction(Map<String, dynamic> r) => {
        ...r,
        'notes': null,
        'original_description': null,
        'merchant_name': null,
        'provider_transaction_id': null,
        'pending': false,
        'is_split_parent': false,
        'parent_transaction_id': null,
        'requires_user_review': false,
        'created_at': '${r['date']}T00:00:00',
        'updated_at': '${r['date']}T00:00:00',
      };

  static Map<String, dynamic> _enrichSubscription(Map<String, dynamic> r) => {
        ...r,
        'min_amount': null,
        'max_amount': null,
        'end_date': null,
        'matching_notes': null,
        'created_at': '${r['start_date']}T00:00:00',
        'updated_at': '${r['start_date']}T00:00:00',
      };

  static Map<String, dynamic> _enrichAccount(Map<String, dynamic> r) => {
        ...r,
        'color': null,
        'updated_at': '2026-05-08T10:00:00',
      };

  // ── Interceptor ─────────────────────────────────────────────────────────────

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    await _ensureLoaded();

    final path = options.path;
    final method = options.method.toUpperCase();

    if (method == 'GET') {
      final data = _fixture(path);
      if (data != null) {
        return handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: data),
        );
      }
    }

    // Write operations: acknowledge silently so the UI doesn't error.
    if (['POST', 'PATCH', 'PUT', 'DELETE'].contains(method)) {
      final body = options.data is Map<String, dynamic>
          ? options.data as Map<String, dynamic>
          : <String, dynamic>{};
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: method == 'DELETE' ? 204 : 200,
          data: _mockWriteResponse(path, method, body),
        ),
      );
    }

    handler.next(options);
  }

  // ── Route matching ──────────────────────────────────────────────────────────

  Object? _fixture(String path) {
    if (path == '/api/accounts') return _accounts;
    // Must be checked before the general /api/transactions catch-all.
    final reimburseMatch = _reimbursementsPathMatch(path);
    if (reimburseMatch != null) return _fakeReimbursementsResponse(reimburseMatch);
    if (path.startsWith('/api/transactions')) return _transactions;
    if (path == '/api/budgets') return _budgets;
    if (path == '/api/categories') return _categories;
    if (path.startsWith('/api/subscriptions')) return _subscriptions;
    if (path == '/api/users/me') return _user;
    if (path == '/api/simplefin/status') return _simplefinStatus;
    if (path.startsWith('/api/net-worth')) return _netWorthHistory;
    return null;
  }

  Object? _mockWriteResponse(
      String path, String method, Map<String, dynamic> body) {
    if (method == 'DELETE') return null;
    // Reimbursements: POST create or PUT update
    if (path == '/api/transactions/reimbursements' && method == 'POST') {
      return _fakeReimbursement(body);
    }
    if (path.startsWith('/api/transactions/reimbursements/') && method == 'PUT') {
      final id = path.split('/').last;
      return _fakeReimbursement(body, id: id);
    }
    // Split: POST /api/transactions/{id}/split → return two fake child rows
    if (path.contains('/split') && method == 'POST') {
      return _fakeSplitChildren(path, body);
    }
    if (path.startsWith('/api/transactions')) return _fakeTransaction(body);
    if (path.startsWith('/api/budgets')) return _fakeBudget(body);
    if (path.startsWith('/api/subscriptions')) return _fakeSubscription(body);
    if (path == '/api/users/me' || path == '/api/users/me/password') {
      return _user;
    }
    if (path == '/api/simplefin/fetch') {
      return {'new_transactions': [], 'accounts_updated': 0};
    }
    return <String, dynamic>{};
  }

  // ── Static fixtures (not in CSVs) ───────────────────────────────────────────

  static final _user = {
    'id': 9999,
    'household_id': 1,
    'email': 'demo@finora.app',
    'full_name': 'Demo User',
    'profile_picture_url': null,
    'is_active': true,
    'created_at': '2026-01-01T00:00:00',
  };

  static final _simplefinStatus = {
    'connected': false,
    'institutions': <String>[],
    'last_synced_at': null,
  };

  // ── Write-response stubs ────────────────────────────────────────────────────

  static Map<String, dynamic> _fakeTransaction(Map<String, dynamic> body) => {
        'id': 'demo-txn-new',
        'title': body['title'] ?? 'Demo Transaction',
        'amount': body['amount'] ?? 0.0,
        'type': body['type'] ?? 'expense',
        'category': body['category'] ?? 'Uncategorized',
        'date': body['date'] ?? DateTime.now().toIso8601String(),
        'account_id': body['account_id'],
        'notes': body['notes'],
        'original_description': null,
        'merchant_name': null,
        'provider_transaction_id': null,
        'pending': false,
        'is_split_parent': false,
        'parent_transaction_id': null,
        'requires_user_review': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Returns a list of fake child split transactions for demo mode.
  static List<Map<String, dynamic>> _fakeSplitChildren(
    String path,
    Map<String, dynamic> body,
  ) {
    // Extract the parent ID from the path: /api/transactions/{id}/split
    final segments = path.split('/');
    final parentId =
        segments.length >= 4 ? segments[3] : 'demo-parent';

    final splits = body['splits'] as List<dynamic>? ?? [];
    return splits.asMap().entries.map((entry) {
      final i = entry.key;
      final split = entry.value as Map<String, dynamic>;
      return {
        'id': 'demo-split-${DateTime.now().millisecondsSinceEpoch}-$i',
        'title': split['title'] ?? 'Split ${i + 1}',
        'amount': split['amount'] ?? 0.0,
        'type': 'expense',
        'category': split['category'] ?? 'Uncategorized',
        'date': DateTime.now().toIso8601String(),
        'account_id': null,
        'notes': split['notes'],
        'original_description': null,
        'merchant_name': null,
        'provider_transaction_id': null,
        'pending': false,
        'is_split_parent': false,
        'parent_transaction_id': parentId,
        'requires_user_review': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
    }).toList();
  }

  // ── Reimbursement fixtures ─────────────────────────────────────────────────

  /// Extracts the transaction ID from a `/api/transactions/{id}/reimbursements`
  /// path. Returns null if the path does not match that pattern.
  static String? _reimbursementsPathMatch(String path) {
    final segments = path.split('/');
    // e.g. ['', 'api', 'transactions', '{id}', 'reimbursements']
    if (segments.length == 5 &&
        segments[1] == 'api' &&
        segments[2] == 'transactions' &&
        segments[4] == 'reimbursements') {
      return segments[3];
    }
    return null;
  }

  /// Returns an empty `ReimbursementListResponse`-shaped map using the
  /// transaction's real amount so the UI shows the correct totals and the
  /// "Link Reimbursement" button is visible.
  Map<String, dynamic> _fakeReimbursementsResponse(String transactionId) {
    final txn = _transactions?.firstWhere(
      (t) => t['id'] == transactionId,
      orElse: () => {},
    );
    final amount = (txn?['amount'] as num?)?.toDouble() ?? 0.0;
    return {
      'transaction_id': transactionId,
      'transaction_amount': amount,
      'allocated_amount': 0.0,
      'remaining_amount': amount,
      'reimbursements': <Map<String, dynamic>>[],
    };
  }

  static Map<String, dynamic> _fakeReimbursement(
    Map<String, dynamic> body, {
    String? id,
  }) =>
      {
        'id': id ?? 'demo-reimb-${DateTime.now().millisecondsSinceEpoch}',
        'expense_transaction_id':
            body['expense_transaction_id'] ?? 'demo-expense',
        'income_transaction_id':
            body['income_transaction_id'] ?? 'demo-income',
        'amount': body['amount'] ?? 0.0,
        'notes': body['notes'],
        'created_by_user_id': 9999,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  static Map<String, dynamic> _fakeBudget(Map<String, dynamic> body) => {
        'id': 'demo-budget-new',
        'category': body['category'] ?? 'Other',
        'allocated': body['allocated'] ?? 0.0,
        'spent': 0.0,
        'color': body['color'] ?? '#009688',
      };

  static Map<String, dynamic> _fakeSubscription(Map<String, dynamic> body) => {
        'id': 'demo-sub-new',
        'name': body['name'] ?? 'Demo Subscription',
        'merchant_name': body['merchant_name'],
        'category': body['category'],
        'expected_amount': body['expected_amount'],
        'min_amount': null,
        'max_amount': null,
        'recurrence_interval': body['recurrence_interval'] ?? 1,
        'recurrence_unit': body['recurrence_unit'] ?? 'month',
        'start_date': body['start_date'],
        'end_date': null,
        'next_due_date': null,
        'status': 'active',
        'auto_link_enabled': false,
        'matching_notes': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
}
