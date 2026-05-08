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
  List<String>? _categories;

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
    _categories = catRows.map((r) => r['name'] as String).toList();

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
