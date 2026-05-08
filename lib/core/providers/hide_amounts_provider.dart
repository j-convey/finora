import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global toggle: when true, sensitive balance/amount fields are masked.
final hideAmountsProvider = StateProvider<bool>((ref) => false);
