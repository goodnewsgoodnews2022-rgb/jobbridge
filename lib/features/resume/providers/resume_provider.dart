import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobbridge/features/resume/resume_model.dart';
import '../../../core/services/supabase_service.dart';


/// All resumes belonging to the current user.
final myResumesProvider = FutureProvider<List<ResumeModel>>((ref) async {
  final u = SupabaseService.currentUser;
  if (u == null) return [];
  final res = await SupabaseService.client
      .from('resumes')
      .select()
      .eq('user_id', u.id)
      .order('created_at', ascending: false);
  return (res as List).map((e) => ResumeModel.fromMap(e)).toList();
});

/// A single resume by id.
final resumeByIdProvider =
    FutureProvider.family<ResumeModel?, String>((ref, id) async {
  final res = await SupabaseService.client
      .from('resumes')
      .select()
      .eq('id', id)
      .maybeSingle();
  return res == null ? null : ResumeModel.fromMap(res);
});