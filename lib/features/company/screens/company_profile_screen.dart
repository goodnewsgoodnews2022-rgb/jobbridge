import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/job_card.dart';
import '../../jobs/models/job_model.dart';

final companyProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final res =
      await SupabaseService.client.from('companies').select().eq('id', id).maybeSingle();
  return res;
});

final companyJobsProvider =
    FutureProvider.family<List<JobModel>, String>((ref, id) async {
  final res = await SupabaseService.client
      .from('jobs')
      .select()
      .eq('company_id', id)
      .eq('status', 'active')
      .order('posted_at', ascending: false);
  return (res as List).map((e) => JobModel.fromMap(e)).toList();
});

class CompanyProfileScreen extends ConsumerWidget {
  final String companyId;
  const CompanyProfileScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(companyProvider(companyId));
    final j = ref.watch(companyJobsProvider(companyId));

    return c.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (company) {
        if (company == null) {
          return const Scaffold(body: Center(child: Text('Company not found')));
        }
        return Scaffold(
          appBar: AppBar(title: Text(company['name'] ?? 'Company')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.business,
                                  size: 40, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(company['name'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  if (company['industry'] != null)
                                    Text(company['industry'],
                                        style: TextStyle(
                                            color: Colors.grey[700])),
                                  const SizedBox(height: 4),
                                  if (company['location'] != null)
                                    Row(children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(company['location'],
                                          style: TextStyle(
                                              color: Colors.grey[700])),
                                    ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (company['description'] != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('About',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              Text(company['description'],
                                  style: const TextStyle(height: 1.6)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text('Open Positions',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    j.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('$e'),
                      data: (list) => list.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('No open positions right now.'))
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
                              itemBuilder: (_, i) => JobCard(job: list[i]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}