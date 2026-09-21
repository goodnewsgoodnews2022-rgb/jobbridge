// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/brand_logo.dart';

class JobSeekerRegisterScreen extends ConsumerStatefulWidget {
  const JobSeekerRegisterScreen({super.key});
  @override
  ConsumerState<JobSeekerRegisterScreen> createState() => _State();
}

class _State extends ConsumerState<JobSeekerRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _skills = TextEditingController();
  final _password = TextEditingController();
  String _experience = 'Entry';
  String _employment = 'Full-time';
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await SupabaseService.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {
          'role': 'job_seeker',
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'location': _location.text.trim(),
          'skills': _skills.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          'experience_level': _experience,
          'preferred_employment_type': _employment,
        },
      );
      if (res.user != null) {
        await SupabaseService.client.from('profiles').upsert({
          'id': res.user!.id,
          'role': 'job_seeker',
          'full_name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'location': _location.text.trim(),
          'skills': _skills.text.split(',').map((s) => s.trim()).toList(),
          'experience_level': _experience,
          'preferred_employment_type': _employment,
        });
      }
      if (mounted) context.go('/job-seeker/dashboard');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Job Seeker Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandLogo(size: 48)),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(color: Color(0xFF991B1B))),
                    ),
                  _sectionTitle('Personal Information'),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        !v!.contains('@') ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration:
                        const InputDecoration(labelText: 'Phone (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _location,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Professional Details'),
                  TextFormField(
                    controller: _skills,
                    decoration: const InputDecoration(
                      labelText: 'Skills (comma separated)',
                      hintText: 'Flutter, Dart, Firebase, Supabase',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _experience,
                    decoration:
                        const InputDecoration(labelText: 'Experience Level'),
                    items: const ['Entry', 'Mid', 'Senior', 'Lead']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _experience = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _employment,
                    decoration: const InputDecoration(
                        labelText: 'Preferred Employment Type'),
                    items: AppConstants.employmentTypes
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _employment = v!),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Security'),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) =>
                        v!.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Create Account'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
      );
}