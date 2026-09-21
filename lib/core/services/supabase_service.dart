import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  static User? get currentUser => auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
}