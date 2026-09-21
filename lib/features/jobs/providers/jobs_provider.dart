import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../models/job_model.dart';

class JobFilters {
  final String? query;
  final String? category;
  final String? country;
  final String? remoteType;
  final String? employmentType;
  final String? source;
  const JobFilters({
    this.query,
    this.category,
    this.country,
    this.remoteType,
    this.employmentType,
    this.source,
  });

  JobFilters copyWith({
    String? query,
    String? category,
    String? country,
    String? remoteType,
    String? employmentType,
    String? source,
  }) =>
      JobFilters(
        query: query ?? this.query,
        category: category ?? this.category,
        country: country ?? this.country,
        remoteType: remoteType ?? this.remoteType,
        employmentType: employmentType ?? this.employmentType,
        source: source ?? this.source,
      );
}

final jobFiltersProvider = StateProvider<JobFilters>((_) => const JobFilters());

final allJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final f = ref.watch(jobFiltersProvider);
  dynamic q = SupabaseService.client
      .from('jobs')
      .select()
      .eq('status', 'active');

  if (f.category != null) q = q.eq('category', f.category!);
  if (f.country != null) q = q.eq('country', f.country!);
  if (f.remoteType != null) q = q.eq('remote_type', f.remoteType!);
  if (f.employmentType != null) q = q.eq('employment_type', f.employmentType!);
  if (f.source != null) q = q.eq('source', f.source!);
  if (f.query != null && f.query!.isNotEmpty) {
    q = q.or('title.ilike.%${f.query}%,company_name.ilike.%${f.query}%');
  }

  q = q.order('posted_at', ascending: false).limit(200);

  final res = await q;
  return (res as List).map((e) => JobModel.fromMap(e)).toList();
});

final remoteJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final res = await SupabaseService.client
      .from('jobs')
      .select()
      .eq('status', 'active')
      .eq('remote_type', 'Remote')
      .order('posted_at', ascending: false)
      .limit(100);
  return (res as List).map((e) => JobModel.fromMap(e)).toList();
});

final nigeriaJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final res = await SupabaseService.client
      .from('jobs')
      .select()
      .eq('status', 'active')
      .or('country.eq.Nigeria,country.eq.NG,location.ilike.%nigeria%,location.ilike.%lagos%,location.ilike.%abuja%')
      .order('posted_at', ascending: false)
      .limit(100);
  return (res as List).map((e) => JobModel.fromMap(e)).toList();
});

final jobByIdProvider =
    FutureProvider.family<JobModel?, String>((ref, id) async {
  final res = await SupabaseService.client
      .from('jobs')
      .select()
      .eq('id', id)
      .maybeSingle();
  return res == null ? null : JobModel.fromMap(res);
});

final latestJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final res = await SupabaseService.client
      .from('jobs')
      .select()
      .eq('status', 'active')
      .order('posted_at', ascending: false)
      .limit(8);
  return (res as List).map((e) => JobModel.fromMap(e)).toList();
});