import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which main-shell tab is currently selected.
/// Any widget can read or write this to switch tabs without
/// touching the router — avoids navigator conflicts entirely.
final shellIndexProvider = StateProvider<int>((ref) => 0);
