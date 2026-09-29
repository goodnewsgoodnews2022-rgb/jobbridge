import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../models/job_model.dart';

// ═══════════════════════════════════════════════════════════════════
// FILTERS
// ═══════════════════════════════════════════════════════════════════

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

/// Returns true only if the filter value is meaningful.
bool _isReal(String? v) {
  if (v == null) return false;
  final t = v.trim().toLowerCase();
  if (t.isEmpty) return false;
  if (t.startsWith('any')) return false;
  return true;
}

final jobFiltersProvider =
    StateProvider<JobFilters>((_) => const JobFilters());

// ═══════════════════════════════════════════════════════════════════
// ALL JOBS — filters first, transforms last
// ═══════════════════════════════════════════════════════════════════

final allJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final f = ref.watch(jobFiltersProvider);

  // Start with base query — status filter first
  var q = SupabaseService.client
      .from('jobs')
      .select()
      .eq('status', 'active');

  // ── Apply filters (BEFORE order/limit) ──
  if (_isReal(f.category))       q = q.eq('category', f.category!);
  if (_isReal(f.country))        q = q.eq('country', f.country!);
  if (_isReal(f.remoteType))     q = q.eq('remote_type', f.remoteType!);
  if (_isReal(f.employmentType)) q = q.eq('employment_type', f.employmentType!);
  if (_isReal(f.source))         q = q.eq('source', f.source!);

  if (f.query != null && f.query!.trim().isNotEmpty) {
    final esc = f.query!.trim();
    q = q.or('title.ilike.%$esc%,company_name.ilike.%$esc%');
  }

  // ── Apply transforms (order + limit) LAST ──
final res = await q
    .order('featured', ascending: false)   // featured first
    .order('posted_at', ascending: false)
    .limit(1000);

  return (res as List).map((e) => JobModel.fromMap(e)).toList();
});

// ═══════════════════════════════════════════════════════════════════
// REMOTE JOBS
// ═══════════════════════════════════════════════════════════════════

final remoteJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final res = await SupabaseService.client
      .from('jobs')
      .select()
      .eq('status', 'active')
      .eq('remote_type', 'Remote')
      .order('posted_at', ascending: false)
      .limit(300);
  return (res as List).map((e) => JobModel.fromMap(e)).toList();
});

// ═══════════════════════════════════════════════════════════════════
// NIGERIA JOBS
// ═══════════════════════════════════════════════════════════════════

final nigeriaJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final res = await SupabaseService.client
      .from('jobs')
      .select()
      .eq('status', 'active')
      .or(
        'country.ilike.%nigeria%,'
        'country.eq.NG,'
        'location.ilike.%nigeria%,'
        'location.ilike.%lagos%,'
        'location.ilike.%abuja%,'
        'location.ilike.%port harcourt%,'
        'location.ilike.%ibadan%,'
        'location.ilike.%kano%,'
        'location.ilike.%benin city%,'
        'location.ilike.%enugu%',
      )
      .order('posted_at', ascending: false)
      .limit(300);
  return (res as List).map((e) => JobModel.fromMap(e)).toList();
});

// ═══════════════════════════════════════════════════════════════════
// AFRICA JOBS — from ProGigFinder
// ═══════════════════════════════════════════════════════════════════

final africaJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final res = await SupabaseService.client
      .from('jobs')
      .select()
      .eq('status', 'active')
      .eq('source', 'progigfinder')
      .order('posted_at', ascending: false)
      .limit(500);
  return (res as List).map((e) => JobModel.fromMap(e)).toList();
});

// ═══════════════════════════════════════════════════════════════════
// SINGLE JOB
// ═══════════════════════════════════════════════════════════════════

final jobByIdProvider =
    FutureProvider.family<JobModel?, String>((ref, id) async {
  final res = await SupabaseService.client
      .from('jobs')
      .select()
      .eq('id', id)
      .maybeSingle();
  return res == null ? null : JobModel.fromMap(res);
});

// ═══════════════════════════════════════════════════════════════════
// LATEST JOBS — for home page
// ═══════════════════════════════════════════════════════════════════

final latestJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final res = await SupabaseService.client
      .from('jobs')
      .select()
      .eq('status', 'active')
      .order('posted_at', ascending: false)
      .limit(8);
  return (res as List).map((e) => JobModel.fromMap(e)).toList();
});

// ═══════════════════════════════════════════════════════════════════
// SOURCE STATS — count per source
// ═══════════════════════════════════════════════════════════════════

final sourceStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final res = await SupabaseService.client
      .from('jobs')
      .select('source')
      .eq('status', 'active');

  final counts = <String, int>{};
  for (final row in (res as List)) {
    final src = (row['source'] ?? 'unknown') as String;
    counts[src] = (counts[src] ?? 0) + 1;
  }
  return counts;
});