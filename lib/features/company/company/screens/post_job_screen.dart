// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbridge/core/constants/app_constants.dart';
import 'package:jobbridge/core/services/supabase_service.dart';
import 'package:jobbridge/features/company/providers/company_provider.dart';


class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});
  @override
  ConsumerState<PostJobScreen> createState() => _State();
}

class _State extends ConsumerState<PostJobScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _req = TextEditingController();
  final _skills = TextEditingController();
  final _location = TextEditingController();
  final _salaryMin = TextEditingController();
  final _salaryMax = TextEditingController();
  final _applyUrl = TextEditingController();

  String _remote = 'Remote';
  String _employment = 'Full-time';
  String _category = AppConstants.categories.first;
  String _currency = 'NGN';
  bool _loading = false;

  // Package selection — default to basic
  String _package = 'job-basic';

  static const _packages = [
    {'id': 'job-basic',    'label': 'Basic — ₦3,000 (30 days)'},
    {'id': 'job-featured', 'label': 'Featured — ₦7,000 (30 days, top of list)'},
    {'id': 'job-premium',  'label': 'Premium — ₦15,000 (60 days, homepage)'},
  ];

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _req.dispose();
    _skills.dispose();
    _location.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
    _applyUrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final company = await ref.read(currentCompanyProvider.future);
      if (company == null) throw 'Company profile missing';
      final companyId = company['id'] as String;

      // ── 1. Check for bundle credits ──
      final bundles = await SupabaseService.client
          .from('bundles')
          .select()
          .eq('company_id', companyId)
          .eq('payment_status', 'paid')
          .limit(1);

      final hasCredits = (bundles as List).any(
        (b) =>
            (b['credits_used'] ?? 0) < (b['credits_total'] ?? 0) &&
            (b['expires_at'] == null ||
                DateTime.parse(b['expires_at']).isAfter(DateTime.now())),
      );

      // ── 2. Check for active subscription ──
      final subs = await SupabaseService.client
          .from('subscriptions')
          .select()
          .eq('company_id', companyId)
          .eq('status', 'active')
          .limit(1);

      final hasSub = (subs as List).isNotEmpty;

      // ── 3. Determine the job status ──
      // If they have credits/sub → publish instantly
      // Otherwise → create as draft and send to payment
      final needsPayment = !hasCredits && !hasSub;

      final jobStatus = needsPayment ? 'pending_payment' : 'active';
      final packageLabel = hasCredits
          ? 'bundle'
          : hasSub
              ? 'subscription'
              : _package;

      // ── 4. Insert the job ──
      final job = await SupabaseService.client
          .from('jobs')
          .insert({
            'source': 'company',
            'company_id': companyId,
            'company_name': company['name'],
            'company_logo': company['logo_url'],
            'title': _title.text.trim(),
            'description': _desc.text.trim(),
            'requirements': _req.text.trim(),
            'skills': _skills.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
            'location': _location.text.trim(),
            'remote_type': _remote,
            'employment_type': _employment,
            'category': _category,
            'salary_min': num.tryParse(_salaryMin.text),
            'salary_max': num.tryParse(_salaryMax.text),
            'salary_currency': _currency,
            'apply_url': _applyUrl.text.trim().isEmpty
                ? null
                : _applyUrl.text.trim(),
            'status': jobStatus,
            'package': packageLabel,
            'payment_status': needsPayment ? 'unpaid' : 'paid',
            'posted_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // ── 5. Consume a bundle credit if using a bundle ──
      if (hasCredits) {
        await SupabaseService.client
            .rpc('consume_bundle_credit', params: {'p_company_id': companyId});
      }

      ref.invalidate(companyJobsProvider);

      // ── 6. Route based on whether they paid ──
      if (!mounted) return;

      if (needsPayment) {
        // Send to checkout, passing the job id
        context.go(
          '/company/checkout?package=$_package&job=${job['id']}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job published successfully!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        context.go('/company/jobs');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('Post a New Job',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Fill out the details, then pay to make it live.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // ── INFO BANNER ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF2563EB), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your job will only appear publicly after payment. Unpaid drafts are auto-deleted after 24 hours.',
                          style: TextStyle(
                              color: Color(0xFF1E40AF),
                              fontSize: 13,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _step(1, 'Job Title'),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                      hintText: 'e.g. Flutter Developer'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                _step(2, 'Description'),
                TextFormField(
                  controller: _desc,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Describe the role…',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                _step(3, 'Requirements'),
                TextFormField(
                  controller: _req,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'List the requirements…',
                    alignLabelWithHint: true,
                  ),
                ),

                _step(4, 'Skills'),
                TextFormField(
                  controller: _skills,
                  decoration: const InputDecoration(
                    hintText: 'Flutter, Dart, Firebase',
                  ),
                ),

                _step(5, 'Location'),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(
                      hintText: 'Lagos, Nigeria / Remote'),
                ),

                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _remote,
                      decoration:
                          const InputDecoration(labelText: 'Remote Type'),
                      items: AppConstants.remoteTypes
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _remote = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _employment,
                      decoration: const InputDecoration(
                          labelText: 'Employment Type'),
                      items: AppConstants.employmentTypes
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _employment = v!),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AppConstants.categories
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),

                _step(7, 'Salary (optional)'),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMax,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration:
                          const InputDecoration(labelText: 'Currency'),
                      items: const ['NGN', 'USD', 'GBP', 'EUR']
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ]),

                _step(8, 'External Apply URL (optional)'),
                TextFormField(
                  controller: _applyUrl,
                  decoration: const InputDecoration(
                      hintText: 'https://your-company.com/careers/123'),
                ),

                // ── PACKAGE SELECTOR ──
                _step(9, 'Choose a Package'),
                ..._packages.map((p) => RadioListTile<String>(
                      value: p['id']!,
                      groupValue: _package,
                      onChanged: (v) => setState(() => _package = v!),
                      title: Text(p['label']!,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF2563EB),
                    )),

                const SizedBox(height: 32),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/company/jobs'),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _publish,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Publish Job'),
                    ),
                  ),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(int n, String label) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$n',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      );
}