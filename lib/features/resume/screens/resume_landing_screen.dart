// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/supabase_service.dart';
import '../providers/resume_provider.dart';

class ResumeLandingScreen extends ConsumerWidget {
  const ResumeLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumes = ref.watch(myResumesProvider);
    final loggedIn = SupabaseService.currentUser != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Resume Builder',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Create a beautiful, ATS-friendly resume in minutes. Download as PDF. Apply with confidence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey[600], fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _planCard(
                    context: context,
                    title: 'Free Resume',
                    price: '₦0',
                    tagline: 'Try it out',
                    color: const Color(0xFF64748B),
                    features: const [
                      '1 basic template',
                      'Add all your details',
                      'Live preview',
                      'No PDF download',
                    ],
                    ctaLabel: 'Start Free',
                    loggedIn: loggedIn,
                  ),
                  _planCard(
                    context: context,
                    title: 'Professional',
                    price: '₦2,500',
                    tagline: 'Most popular',
                    color: const Color(0xFF2563EB),
                    highlighted: true,
                    features: const [
                      '3 premium templates',
                      'ATS-friendly formatting',
                      'Professional summary help',
                      'PDF download',
                      'Edit anytime',
                    ],
                    ctaLabel: 'Upgrade Now',
                    loggedIn: loggedIn,
                  ),
                  _planCard(
                    context: context,
                    title: 'Career Pack',
                    price: '₦5,000',
                    tagline: 'Best value',
                    color: const Color(0xFF7C3AED),
                    features: const [
                      'Everything in Professional',
                      'Cover letter generator',
                      'LinkedIn summary',
                      'Priority support',
                    ],
                    ctaLabel: 'Get Career Pack',
                    loggedIn: loggedIn,
                  ),
                ],
              ),
              if (loggedIn) ...[
                const SizedBox(height: 60),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'My Resumes',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 16),
                resumes.when(
                  loading: () => const Center(
                      child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )),
                  error: (e, _) => Text('Error: $e'),
                  data: (list) {
                    if (list.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(Icons.description_outlined,
                                  size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              const Text(
                                'No resumes yet',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Build your first professional resume',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => context.go('/resume/create'),
                                icon: const Icon(Icons.add),
                                label: const Text('Build Resume'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 180,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final r = list[i];
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () =>
                                context.go('/resume/preview?id=${r.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: r.isPro
                                              ? const Color(0xFFEFF6FF)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.description,
                                          color: r.isPro
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF64748B),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              r.fullName.isEmpty
                                                  ? 'No name'
                                                  : r.fullName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: r.isPro
                                              ? const Color(0xFFECFDF5)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          r.isPro ? 'PRO' : 'DRAFT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: r.isPro
                                                ? const Color(0xFF059669)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () => context
                                            .go('/resume/preview?id=${r.id}'),
                                        icon: const Icon(Icons.visibility,
                                            size: 16),
                                        label: const Text('Open'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planCard({
    required BuildContext context,
    required String title,
    required String price,
    required String tagline,
    required Color color,
    required List<String> features,
    required String ctaLabel,
    required bool loggedIn,
    bool highlighted = false,
  }) {
    return SizedBox(
      width: 340,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlighted ? color : const Color(0xFFE2E8F0),
            width: highlighted ? 2 : 1,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlighted)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(tagline,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 16),
            Text(
              price,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 20),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, size: 18, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      highlighted ? color : const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  if (!loggedIn) {
                    context.go('/login?redirect=/resume/create');
                    return;
                  }
                  context.go('/resume/create');
                },
                child: Text(ctaLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}