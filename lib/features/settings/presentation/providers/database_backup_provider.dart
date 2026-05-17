import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_client.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/net_worth_history_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../transactions/presentation/providers/categories_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum DatabaseBackupStatus { idle, exporting, importing }

class DatabaseBackupState {
  const DatabaseBackupState({
    this.status = DatabaseBackupStatus.idle,
    this.errorMessage,
  });

  final DatabaseBackupStatus status;
  final String? errorMessage;

  bool get isBusy => status != DatabaseBackupStatus.idle;

  DatabaseBackupState copyWith({
    DatabaseBackupStatus? status,
    String? errorMessage,
  }) =>
      DatabaseBackupState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class DatabaseBackupNotifier extends StateNotifier<DatabaseBackupState> {
  DatabaseBackupNotifier(this._ref) : super(const DatabaseBackupState());

  final Ref _ref;

  /// Downloads the full database JSON from the server and shares/saves it as
  /// a timestamped file.
  Future<void> exportDatabase() async {
    state = state.copyWith(
      status: DatabaseBackupStatus.exporting,
      errorMessage: null,
    );
    try {
      final dio = _ref.read(apiClientProvider);
      final res =
          await dio.get<Map<String, dynamic>>('/api/admin/export-database');

      final jsonString = const JsonEncoder.withIndent('  ').convert(res.data);

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final fileName = 'finora_backup_$timestamp.json';

      // Save to app documents directory, then share so the user can save it
      // wherever they like (save to files, email, cloud storage, etc.).
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Finora database backup',
        ),
      );
    } catch (e) {
      state = state.copyWith(
        status: DatabaseBackupStatus.idle,
        errorMessage: e.toString(),
      );
      rethrow;
    }
    state = state.copyWith(status: DatabaseBackupStatus.idle);
  }

  /// Lets the user pick a previously exported JSON backup file, posts it to
  /// the server, then refreshes all providers so the UI reflects the imported
  /// data.
  Future<void> importDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    state = state.copyWith(
      status: DatabaseBackupStatus.importing,
      errorMessage: null,
    );
    try {
      final jsonString = await File(path).readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final dio = _ref.read(apiClientProvider);
      final res = await dio.post<Map<String, dynamic>>(
        '/api/admin/import-database',
        data: jsonData,
      );

      final ok = res.data?['ok'] as bool? ?? false;
      if (!ok) {
        throw Exception(
            res.data?['detail'] as String? ?? 'Import failed on server');
      }

      // Refresh all providers so the UI shows the newly imported data.
      await Future.wait([
        _ref.read(transactionsProvider.notifier).sync(),
        _ref.read(accountsProvider.notifier).sync(),
        _ref.read(budgetsProvider.notifier).sync(),
        _ref.read(subscriptionsProvider.notifier).sync(),
        _ref.read(categoryGroupsProvider.notifier).sync(),
        _ref.read(netWorthHistoryProvider.notifier).fetch(),
      ]);
    } catch (e) {
      state = state.copyWith(
        status: DatabaseBackupStatus.idle,
        errorMessage: e.toString(),
      );
      rethrow;
    }
    state = state.copyWith(status: DatabaseBackupStatus.idle);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final databaseBackupProvider =
    StateNotifierProvider<DatabaseBackupNotifier, DatabaseBackupState>(
  (ref) => DatabaseBackupNotifier(ref),
);
