import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/brand_logo.dart';

class CompanyRegisterScreen extends StatefulWidget {
  const CompanyRegisterScreen({super.key});
  @override
  State<CompanyRegisterScreen> createState() => _State();
}

class _State extends State<CompanyRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _industry = TextEditingController();
  final _location = TextEditingController();
  final _desc = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await SupabaseService.auth.signUp(
        email: _email.text.trim(),
        password: _pass.text,
        data: {
          'role': 'company',
          'company_name': _company.text.trim(),
        },
      );
      if (res.user != null) {
        await SupabaseService.client.from('companies').insert({
          'owner_id': res.user!.id,
          'name': _company.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'website': _website.text.trim(),
          'industry': _industry.text.trim(),
          'location': _location.text.trim(),
          'description': _desc.text.trim(),
        });
      }
      if (mounted) context.go('/company/dashboard');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Company Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
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
                  TextFormField(
                    controller: _company,
                    decoration:
                        const InputDecoration(labelText: 'Company Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Company Email'),
                    validator: (v) =>
                        !v!.contains('@') ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) =>
                        v!.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _website,
                    decoration:
                        const InputDecoration(labelText: 'Website URL'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _industry,
                    decoration: const InputDecoration(labelText: 'Industry'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _location,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _desc,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Company Description'),
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
                        : const Text('Create Company Account'),
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
}