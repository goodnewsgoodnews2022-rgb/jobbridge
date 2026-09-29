import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';

final currentCompanyProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final u = SupabaseService.currentUser;
  if (u == null) return null;
  return await SupabaseService.client
      .from('companies')
      .select()
      .eq('owner_id', u.id)
      .maybeSingle();
});

final companyJobsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final c = await ref.watch(currentCompanyProvider.future);
  if (c == null) return [];
  final res = await SupabaseService.client
      .from('jobs')
      .select()
      .eq('company_id', c['id'])
      .order('created_at', ascending: false);
  return (res as List).cast<Map<String, dynamic>>();
});

final companyApplicationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final c = await ref.watch(currentCompanyProvider.future);
  if (c == null) return [];
  final res = await SupabaseService.client
      .from('applications')
      .select('''
        *,
        jobs(title, source, location),
        profiles!applications_job_seeker_id_profiles_fkey(
          full_name, email, phone, cv_url
        )
      ''')
      .eq('company_id', c['id'])
      .order('created_at', ascending: false);
  return (res as List).cast<Map<String, dynamic>>();
});