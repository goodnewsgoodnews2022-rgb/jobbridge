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

  Future<void> _publish() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final company = await ref.read(currentCompanyProvider.future);
      if (company == null) throw 'Company profile missing';

      await SupabaseService.client.from('jobs').insert({
        'source': 'company',
        'company_id': company['id'],
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
        'status': 'active',
        'posted_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(companyJobsProvider);
      if (mounted) context.go('/company/jobs');
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
                Text('Fill out the details below to publish.',
                    style: TextStyle(color: Colors.grey[600])),
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