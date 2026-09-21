// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/job_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../jobs/providers/jobs_provider.dart';

final savedCountProvider = FutureProvider<int>((ref) async {
  final u = SupabaseService.currentUser;
  if (u == null) return 0;
  final r = await SupabaseService.client
      .from('saved_jobs')
      .select('id')
      .eq('user_id', u.id);
  return (r as List).length;
});

final appCountProvider = FutureProvider<int>((ref) async {
  final u = SupabaseService.currentUser;
  if (u == null) return 0;
  final r = await SupabaseService.client
      .from('applications')
      .select('id')
      .eq('job_seeker_id', u.id);
  return (r as List).length;
});

class JobSeekerDashboardScreen extends ConsumerWidget {
  const JobSeekerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final latest = ref.watch(latestJobsProvider);
    final savedCount = ref.watch(savedCountProvider);
    final appCount = ref.watch(appCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Welcome, ${auth.displayName ?? 'there'} 👋',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Here is your activity snapshot.',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              LayoutBuilder(builder: (context, c) {
                final cards = [
                  _stat('Saved Jobs', savedCount, Icons.bookmark_outline,
                      const Color(0xFF2563EB), '/job-seeker/saved-jobs'),
                  _stat('Applications', appCount, Icons.send_outlined,
                      const Color(0xFF7C3AED), '/job-seeker/applications'),
                  _stat('Profile', const AsyncValue.data(1), Icons.person_outline,
                      const Color(0xFF059669), '/job-seeker/profile'),
                ];
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: cards
                      .map((e) => SizedBox(
                          width: c.maxWidth > 800
                              ? (c.maxWidth - 32) / 3
                              : c.maxWidth,
                          child: e))
                      .toList(),
                );
              }),
              const SizedBox(height: 32),
              Row(children: [
                const Text('Recommended Jobs',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(
                    onPressed: () => context.go('/jobs'),
                    child: const Text('Browse all')),
              ]),
              const SizedBox(height: 14),
              latest.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (list) => GridView.builder(
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
                  itemBuilder: (_, i) => JobCard(job: list[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, AsyncValue<int> value, IconData icon, Color c,
      String route) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => nav(route),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: c),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  value.when(
                    loading: () => const Text('…',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800)),
                    error: (_, __) => const Text('0'),
                    data: (v) => Text('$v',
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800)),
                  ),
                  Text(label, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void nav(String r) {
    // no-op: navigation handled via BuildContext in parent widget
  }
}