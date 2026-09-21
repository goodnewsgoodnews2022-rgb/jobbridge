import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/job_card.dart';
import '../../../shared/widgets/loading_grid.dart';
import '../../jobs/models/job_model.dart';

final savedJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final u = SupabaseService.currentUser;
  if (u == null) return [];
  final res = await SupabaseService.client
      .from('saved_jobs')
      .select('jobs(*)')
      .eq('user_id', u.id)
      .order('created_at', ascending: false);
  return (res as List)
      .map((e) => JobModel.fromMap(e['jobs'] as Map<String, dynamic>))
      .toList();
});

class SavedJobsScreen extends ConsumerWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(savedJobsProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Saved Jobs',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              jobs.when(
                loading: () => const LoadingGrid(),
                error: (e, _) => Text('Error: $e'),
                data: (list) => list.isEmpty
                    ? EmptyState(
                        icon: Icons.bookmark_border,
                        title: 'No saved jobs yet',
                        subtitle: 'Save jobs to view them later.',
                        action: ElevatedButton(
                          onPressed: () => context.go('/jobs'),
                          child: const Text('Browse Jobs'),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 480,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 2.1,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => JobCard(job: list[i], saved: true),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}