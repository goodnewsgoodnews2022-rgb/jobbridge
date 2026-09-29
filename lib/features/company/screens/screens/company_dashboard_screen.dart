// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbridge/core/services/supabase_service.dart';
import 'package:jobbridge/features/auth/providers/auth_provider.dart';
import 'package:jobbridge/features/company/providers/company_provider.dart';
import 'package:jobbridge/shared/widgets/empty_state.dart';


class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final company = ref.watch(currentCompanyProvider);
    final jobs = ref.watch(companyJobsProvider);
    final apps = ref.watch(companyApplicationsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${auth.displayName ?? 'Company'}',
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text('Manage your jobs and hiring.',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/company/jobs/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Post New Job'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              company.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
                data: (c) {
                  if (c == null) {
                    return const Text('No company profile found.');
                  }
                  final totalJobs = jobs.valueOrNull?.length ?? 0;
                  final active = jobs.valueOrNull
                          ?.where((j) => j['status'] == 'active')
                          .length ??
                      0;
                  final totalApps = apps.valueOrNull?.length ?? 0;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _stat('Jobs Posted', '$totalJobs',
                          Icons.work_outline, const Color(0xFF2563EB)),
                      _stat('Active Jobs', '$active',
                          Icons.check_circle_outline,
                          const Color(0xFF059669)),
                      _stat('Applications', '$totalApps',
                          Icons.send_outlined, const Color(0xFF7C3AED)),
                    ],
                  );
                },
              ),
              // ── Billing Overview ──
const SizedBox(height: 24),
FutureBuilder(
  future: SupabaseService.client
      .from('job_orders')
      .select()
      .eq('company_id', company.valueOrNull?['id'])
      .order('created_at', ascending: false)
      .limit(5),
  builder: (context, snap) {
    final orders = (snap.data as List?) ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.receipt_long, color: Color(0xFF2563EB)),
              const SizedBox(width: 10),
              const Text('Recent Purchases',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.go('/pricing'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Buy Package'),
              ),
            ]),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              Text('No purchases yet.',
                  style: TextStyle(color: Colors.grey[600]))
            else
              ...orders.map((o) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          o['payment_status'] == 'paid'
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          size: 18,
                          color: o['payment_status'] == 'paid'
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(o['package'] ?? '')),
                        Text('₦${o['amount']}'),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: o['payment_status'] == 'paid'
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (o['payment_status'] ?? '').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: o['payment_status'] == 'paid'
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFEA580C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  },
),
              const SizedBox(height: 32),
              const Text('Recent Jobs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              jobs.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
                data: (list) => list.isEmpty
                    ? EmptyState(
                        icon: Icons.work_outline,
                        title: 'No jobs posted yet',
                        subtitle: 'Post your first job to attract candidates.',
                        action: ElevatedButton(
                          onPressed: () =>
                              context.go('/company/jobs/create'),
                          child: const Text('Post a Job'),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final j = list[i];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.work_outline,
                                    color: Color(0xFF2563EB)),
                              ),
                              title: Text(j['title'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                    '${j['location'] ?? ''} · ${j['status']}'),
                              ),
                              trailing: TextButton(
                                onPressed: () =>
                                    context.go('/company/jobs'),
                                child: const Text('Manage'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color c) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
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
                Text(value,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800)),
                Text(label, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}