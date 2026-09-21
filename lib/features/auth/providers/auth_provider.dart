import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class AuthState extends ChangeNotifier {
  AuthState() {
    SupabaseService.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  User? get currentUser => SupabaseService.currentUser;
  bool get isLoggedIn => currentUser != null;

  String? get role {
    final meta = currentUser?.userMetadata;
    return meta?['role'] as String?;
  }

  String? get displayName {
    final meta = currentUser?.userMetadata;
    return (meta?['name'] ?? meta?['company_name']) as String?;
  }

  Future<void> signOut() async {
    await SupabaseService.auth.signOut();
  }
}

final authStateProvider = ChangeNotifierProvider<AuthState>((ref) => AuthState());