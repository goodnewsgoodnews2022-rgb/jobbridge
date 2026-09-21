import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/brand_logo.dart';

class RegisterTypeScreen extends StatelessWidget {
  const RegisterTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                const BrandLogo(size: 56),
                const SizedBox(height: 24),
                Text('Join JobBridge',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('What do you want to do?',
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 40),
                LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 560;
                  final cards = [
                    _RoleCard(
                      icon: Icons.person_search_outlined,
                      title: 'Job Seeker',
                      subtitle: 'Find jobs, save jobs, apply for jobs',
                      items: const [
                        'Search & filter jobs',
                        'Save opportunities',
                        'Apply in one click',
                        'Track applications',
                      ],
                      onTap: () => context.go('/register/job-seeker'),
                    ),
                    _RoleCard(
                      icon: Icons.business_center_outlined,
                      title: 'Company',
                      subtitle: 'Post jobs, find candidates, manage hiring',
                      items: const [
                        'Post unlimited jobs',
                        'View live applicants',
                        'Manage hiring pipeline',
                        'See job analytics',
                      ],
                      onTap: () => context.go('/register/company'),
                    ),
                  ];
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 20),
                        Expanded(child: cards[1]),
                      ],
                    );
                  }
                  return Column(children: [
                    cards[0],
                    const SizedBox(height: 20),
                    cards[1],
                  ]);
                }),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account?'),
                  TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign in')),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final List<String> items;
  final VoidCallback onTap;
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 26),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ...items.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      const Icon(Icons.check_circle,
                          size: 18, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e)),
                    ]),
                  )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: onTap, child: Text('Continue as $title')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}