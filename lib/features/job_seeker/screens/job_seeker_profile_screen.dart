import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/brand_logo.dart';

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final u = SupabaseService.currentUser;
  if (u == null) return null;
  return await SupabaseService.client
      .from('profiles')
      .select()
      .eq('id', u.id)
      .maybeSingle();
});

class JobSeekerProfileScreen extends ConsumerStatefulWidget {
  const JobSeekerProfileScreen({super.key});
  @override
  ConsumerState<JobSeekerProfileScreen> createState() => _State();
}

class _State extends ConsumerState<JobSeekerProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _loc = TextEditingController();
  final _skills = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  void _init(Map<String, dynamic>? p) {
    if (_initialized || p == null) return;
    _name.text = p['full_name'] ?? '';
    _phone.text = p['phone'] ?? '';
    _loc.text = p['location'] ?? '';
    _skills.text = (p['skills'] as List?)?.join(', ') ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final u = SupabaseService.currentUser!;
      await SupabaseService.client.from('profiles').update({
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'location': _loc.text.trim(),
        'skills': _skills.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      }).eq('id', u.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    return p.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (profile) {
        _init(profile);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('My Profile',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  Form(
                    key: _form,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const BrandLogo(size: 40),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _name,
                              decoration: const InputDecoration(
                                  labelText: 'Full Name'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phone,
                              decoration: const InputDecoration(
                                  labelText: 'Phone'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _loc,
                              decoration: const InputDecoration(
                                  labelText: 'Location'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _skills,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                  labelText: 'Skills (comma separated)'),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _saving ? null : _save,
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('Save Changes'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}