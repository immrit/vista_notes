import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista_notes2/main.dart';
import '../services/supabase_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return supabase.auth.onAuthStateChange.map((event) => event.session?.user);
});
final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authStateProvider).when(
        data: (user) => user,
        loading: () => null,
        error: (err, stack) => null,
      );
  if (user == null) {
    throw Exception('User is not logged in');
  }

  final response =
      await supabase.from('profiles').select().eq('id', user.id).maybeSingle();

  if (response == null) {
    throw Exception('Profile not found');
  }

  return response;
});
