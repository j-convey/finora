import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the desktop sidebar is collapsed or expanded.
/// True = expanded (shows labels), False = collapsed (icons only).
final sidebarExpandedProvider = StateProvider<bool>((ref) => true);
