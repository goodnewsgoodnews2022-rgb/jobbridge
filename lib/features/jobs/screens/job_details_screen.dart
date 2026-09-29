import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/job_apply_dialog.dart';
import '../models/job_model.dart';
import '../providers/jobs_provider.dart';

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
                    _headerCard(context, job),
                    const SizedBox(height: 20),

                    if (job.description?.isNotEmpty == true)
                      _section('Description', _clean(job.description!)),

                    if (job.requirements?.isNotEmpty == true)
                      _section('Requirements', _clean(job.requirements!)),

                    if (job.skills.isNotEmpty) _skillsCard(job),

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

  // ═══════════════════════════════════════════════════════════════
  // HEADER CARD (title, company, chips, salary, apply, save)
  // ═══════════════════════════════════════════════════════════════

  Widget _headerCard(BuildContext context, JobModel job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),

            // Company name — link to profile if internal
            if (job.companyId != null && !job.isExternal)
              InkWell(
                onTap: () => context.go('/companies/${job.companyId}'),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        job.companyName ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_outward,
                          size: 14, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              )
            else
              Text(
                job.companyName ?? '',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),

            const SizedBox(height: 16),

            // Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.location_on_outlined, job.location ?? 'N/A'),
                if (job.remoteType != null)
                  _chip(Icons.wifi, job.remoteType!),
                if (job.employmentType != null)
                  _chip(Icons.schedule, job.employmentType!),
                if (job.category != null)
                  _chip(Icons.category_outlined, job.category!),
              ],
            ),

            // Salary
            if (job.salaryLabel != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      size: 18, color: Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Text(
                    job.salaryLabel!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Apply + Save
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    onPressed: () => _handleApply(context, job),
                    label: Text(job.isExternal
                        ? 'Apply on ${job.source.toUpperCase()}'
                        : 'Apply Now'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _save(context, job.id),
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('Save'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                  ),
                ),
              ],
            ),

            // Login hint
            if (SupabaseService.currentUser == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Color(0xFFD97706)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You must log in to apply for jobs.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // External source note
            if (job.isExternal) ...[
              const SizedBox(height: 12),
              Text(
                'Note: This job is sourced from ${job.source.toUpperCase()} and applications are handled on their site.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION (description / requirements)
  // ═══════════════════════════════════════════════════════════════

  Widget _section(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: const TextStyle(height: 1.6, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      );

  // ═══════════════════════════════════════════════════════════════
  // SKILLS CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _skillsCard(JobModel job) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Skills',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
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
      );

  // ═══════════════════════════════════════════════════════════════
  // CHIP
  // ═══════════════════════════════════════════════════════════════

  Widget _chip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF475569)),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════
  // HTML CLEANER
  // ═══════════════════════════════════════════════════════════════

  String _clean(String html) {
    var s = html;
    // Replace block-level tags with newlines
    s = s.replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n');
    s = s.replaceAll(
        RegExp(r'<\s*/\s*(p|div|li|h[1-6])\s*>', caseSensitive: false), '\n\n');
    s = s.replaceAll(
        RegExp(r'<\s*(p|div|h[1-6])(\s+[^>]*)?>', caseSensitive: false), '');
    // List items get a bullet
    s = s.replaceAll(
        RegExp(r'<\s*li(\s+[^>]*)?>', caseSensitive: false), '• ');
    // Strip remaining tags
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    // Decode common HTML entities
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '…');
    // Decode numeric entities (&#x26; &#38;)
    s = s.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
    );
    s = s.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m[1]!)),
    );
    // Collapse excessive blank lines
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  // ═══════════════════════════════════════════════════════════════
  // APPLY — gate behind login
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handleApply(BuildContext context, JobModel job) async {
    final user = SupabaseService.currentUser;

    // ── NOT LOGGED IN → show dialog ──
    if (user == null) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (dialogCtx) => _loginRequiredDialog(
          context: dialogCtx,
          title: 'Account Required',
          message:
              'You need a JobBridge account to apply for jobs. It takes less than 30 seconds to sign up.',
          icon: Icons.lock_outline,
          jobId: job.id,
          showSignUp: true,
        ),
      );
      return;
    }

    // ── LOGGED IN AS COMPANY → wrong role ──
    final role = user.userMetadata?['role'] as String?;
    if (role == 'company') {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are logged in as a company. Log in with a job seeker account to apply.',
          ),
          backgroundColor: Color(0xFFEA580C),
        ),
      );
      return;
    }

    // ── LOGGED IN AS JOB SEEKER → proceed ──
    if (job.isExternal) {
      final url = job.applyUrl ?? job.jobUrl;
      if (url == null || url.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No application link available.')),
        );
        return;
      }
      try {
        final ok = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the application page.'),
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
      return;
    }

    // ── Internal job → show apply dialog ──
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => JobApplyDialog(jobId: job.id),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SAVE — also gated behind login
  // ═══════════════════════════════════════════════════════════════

  Future<void> _save(BuildContext context, String jobId) async {
    if (SupabaseService.currentUser == null) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (dialogCtx) => _loginRequiredDialog(
          context: dialogCtx,
          title: 'Log in to save jobs',
          message:
              'Save jobs to your account and apply anytime. Takes 30 seconds to sign up.',
          icon: Icons.bookmark_border,
          jobId: jobId,
          showSignUp: true,
        ),
      );
      return;
    }

    try {
      await SupabaseService.client.from('saved_jobs').insert({
        'user_id': SupabaseService.currentUser!.id,
        'job_id': jobId,
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Job saved'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already saved')),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // REUSABLE LOGIN/REGISTER DIALOG
  // ═══════════════════════════════════════════════════════════════

  Widget _loginRequiredDialog({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required String jobId,
    bool showSignUp = true,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[700], height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/login?redirect=/jobs/$jobId');
              },
              child: const Text('Log In'),
            ),
          ),
          if (showSignUp) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(
                      '/register/job-seeker?redirect=/jobs/$jobId');
                },
                child: const Text('Create an Account'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}