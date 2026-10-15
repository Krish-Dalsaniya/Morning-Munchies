import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get supabase => Supabase.instance.client;

String todayStr() => DateTime.now().toIso8601String().substring(0, 10);

/// Bump to make admin tabs reload their data.
final refreshTick = ValueNotifier<int>(0);
void refresh() => refreshTick.value++;
