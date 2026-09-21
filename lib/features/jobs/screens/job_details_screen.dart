import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/supabase_service.dart';
import '../providers/jobs_provider.dart';
import '../../../shared/widgets/job_apply_dialog.dart';

class JobDetailsScreen extends ConsumerWidget {
  final String jobId;
  const JobDetailsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobByIdProvider(jobId));
    return jobAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (job) {
        if (job == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Job')),
            body: const Center(child: Text('Job not found')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(job.title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.title,
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(job.companyName ?? '',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _chip(Icons.location_on_outlined,
                                    job.location ?? 'N/A'),
                                if (job.remoteType != null)
                                  _chip(Icons.wifi, job.remoteType!),
                                if (job.employmentType != null)
                                  _chip(Icons.schedule, job.employmentType!),
                                if (job.category != null)
                                  _chip(Icons.category_outlined,
                                      job.category!),
                              ],
                            ),
                            if (job.salaryLabel != null) ...[
                              const SizedBox(height: 16),
                              Text(job.salaryLabel!,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF059669))),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.send),
                                    onPressed: () =>
                                        _apply(context, job),
                                    label: Text(job.isExternal
                                        ? 'Apply on ${job.source.toUpperCase()}'
                                        : 'Apply Now'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _save(context, job.id),
                                  icon: const Icon(Icons.bookmark_border),
                                  label: const Text('Save'),
                                ),
                              ],
                            ),
                            if (job.isExternal) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Note: This job is sourced from ${job.source.toUpperCase()} and applications are handled on their site.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (job.description?.isNotEmpty == true)
                      _section('Description', job.description!),
                    if (job.requirements?.isNotEmpty == true)
                      _section('Requirements', job.requirements!),
                    if (job.skills.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Skills',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: job.skills
                                    .map((s) => Chip(label: Text(s)))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _section(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(body, style: const TextStyle(height: 1.6, fontSize: 15)),
              ],
            ),
          ),
        ),
      );

  Widget _chip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13)),
        ]),
      );

  Future<void> _apply(BuildContext context, job) async {
    if (job.isExternal) {
      final url = job.applyUrl ?? job.jobUrl;
      if (url != null) {
        await launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication);
      }
      return;
    }
    if (SupabaseService.currentUser == null) {
      context.go('/login');
      return;
    }
    showDialog(context: context, builder: (_) => JobApplyDialog(jobId: job.id));
  }

  Future<void> _save(BuildContext context, String jobId) async {
    if (SupabaseService.currentUser == null) {
      context.go('/login');
      return;
    }
    try {
      await SupabaseService.client
          .from('saved_jobs')
          .insert({'user_id': SupabaseService.currentUser!.id, 'job_id': jobId});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job saved')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already saved')),
        );
      }
    }
  }
}