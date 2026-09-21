// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/empty_state.dart';

final myApplicationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final u = SupabaseService.currentUser;
  if (u == null) return [];
  final res = await SupabaseService.client
      .from('applications')
      .select('*, jobs(title, company_name, source, location)')
      .eq('job_seeker_id', u.id)
      .order('created_at', ascending: false);
  return (res as List).cast<Map<String, dynamic>>();
});

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(myApplicationsProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('My Applications',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              apps.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (list) => list.isEmpty
                    ? EmptyState(
                        icon: Icons.send_outlined,
                        title: 'No applications yet',
                        subtitle:
                            'When you apply for a job it will appear here.',
                        action: ElevatedButton(
                          onPressed: () => context.go('/jobs'),
                          child: const Text('Find Jobs'),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _appCard(context, list[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appCard(BuildContext context, Map<String, dynamic> a) {
    final job = a['jobs'] ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.work_outline,
                  color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job['title'] ?? 'Job',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(job['company_name'] ?? '',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  Text(
                    'Applied ${a['created_at'] != null ? timeago.format(DateTime.parse(a['created_at'])) : ''}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            _statusChip(a['status'] ?? 'submitted'),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String s) {
    final map = {
      'submitted': [Color(0xFF2563EB), Color(0xFFEFF6FF)],
      'reviewing': [Color(0xFF7C3AED), Color(0xFFF5F3FF)],
      'shortlisted': [Color(0xFF059669), Color(0xFFECFDF5)],
      'rejected': [Color(0xFFDC2626), Color(0xFFFEF2F2)],
      'hired': [Color(0xFF0F172A), Color(0xFFF1F5F9)],
    };
    final v = map[s] ?? map['submitted']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: v[1],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        s.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: v[0],
            letterSpacing: 0.5),
      ),
    );
  }
}