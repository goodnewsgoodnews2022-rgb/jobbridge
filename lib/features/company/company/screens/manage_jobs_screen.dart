import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbridge/core/services/supabase_service.dart';
import 'package:jobbridge/features/company/providers/company_provider.dart';
import 'package:jobbridge/shared/widgets/empty_state.dart';


class ManageJobsScreen extends ConsumerWidget {
  const ManageJobsScreen({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref,
      Map<String, dynamic> job) async {
    final newStatus = job['status'] == 'active' ? 'closed' : 'active';
    await SupabaseService.client
        .from('jobs')
        .update({'status': newStatus}).eq('id', job['id']);
    ref.invalidate(companyJobsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await SupabaseService.client.from('jobs').delete().eq('id', id);
      ref.invalidate(companyJobsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(companyJobsProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(children: [
                const Expanded(
                  child: Text('My Jobs',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800)),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/company/jobs/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Post Job'),
                ),
              ]),
              const SizedBox(height: 24),
              jobs.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
                data: (list) => list.isEmpty
                    ? const EmptyState(
                        icon: Icons.work_outline,
                        title: 'No jobs yet',
                        subtitle: 'Post your first job to get started.',
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _row(context, ref, list[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, Map<String, dynamic> j) {
    final active = j['status'] == 'active';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.work_outline, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(j['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                      '${j['location'] ?? ''} · ${j['employment_type'] ?? ''}',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            Chip(
              label: Text(active ? 'Active' : 'Closed'),
              backgroundColor:
                  active ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                color: active
                    ? const Color(0xFF059669)
                    : const Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _toggle(context, ref, j),
              icon: Icon(active ? Icons.pause : Icons.play_arrow),
              tooltip: active ? 'Close' : 'Reopen',
            ),
            IconButton(
              onPressed: () => _delete(context, ref, j['id']),
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFDC2626)),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}