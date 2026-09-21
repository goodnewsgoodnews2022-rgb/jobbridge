import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobbridge/core/services/supabase_service.dart';
import 'package:jobbridge/features/company/providers/company_provider.dart';
import 'package:jobbridge/shared/widgets/empty_state.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';


class CompanyApplicationsScreen extends ConsumerWidget {
  const CompanyApplicationsScreen({super.key});

  Future<void> _updateStatus(
      WidgetRef ref, String id, String status) async {
    await SupabaseService.client
        .from('applications')
        .update({'status': status}).eq('id', id);
    ref.invalidate(companyApplicationsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(companyApplicationsProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Applications',
                  style:
                      TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              apps.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
                data: (list) => list.isEmpty
                    ? const EmptyState(
                        icon: Icons.send_outlined,
                        title: 'No applications yet',
                        subtitle:
                            'Applications to your jobs will appear here.',
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _card(context, ref, list[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref,
      Map<String, dynamic> a) {
    final job = a['jobs'] ?? {};
    final seeker = a['profiles'] ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  (seeker['full_name'] ?? 'U')
                      .toString()
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seeker['full_name'] ?? 'Applicant',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(job['title'] ?? '',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              Chip(
                label: Text(a['status'] ?? 'submitted'),
                backgroundColor: const Color(0xFFEFF6FF),
                labelStyle: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ]),
            if ((a['cover_letter'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(a['cover_letter'],
                    style: const TextStyle(height: 1.5)),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if ((a['cv_url'] ?? '').toString().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () =>
                      launchUrl(Uri.parse(a['cv_url'])),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download CV'),
                ),
              if ((seeker['email'] ?? '').toString().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                      Uri.parse('mailto:${seeker['email']}')),
                  icon: const Icon(Icons.mail_outline, size: 16),
                  label: const Text('Email'),
                ),
              _statusMenu(context, ref, a),
              const Spacer(),
              Text(
                a['created_at'] != null
                    ? timeago.format(DateTime.parse(a['created_at']))
                    : '',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _statusMenu(BuildContext context, WidgetRef ref,
      Map<String, dynamic> a) {
    return PopupMenuButton<String>(
      onSelected: (s) => _updateStatus(ref, a['id'], s),
      child: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.flag_outlined, size: 16),
        label: const Text('Update Status'),
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'reviewing', child: Text('Mark Reviewing')),
        PopupMenuItem(value: 'shortlisted', child: Text('Shortlist')),
        PopupMenuItem(value: 'rejected', child: Text('Reject')),
        PopupMenuItem(value: 'hired', child: Text('Hired')),
      ],
    );
  }
}