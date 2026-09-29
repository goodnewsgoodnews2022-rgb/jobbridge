// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PricingScreen extends ConsumerWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 900;

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
                'Simple, Honest Pricing',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Post a single job, buy a bundle, or subscribe monthly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
              const SizedBox(height: 40),

              // ── SINGLE JOB POSTS ──
              _sectionTitle('Single Job Posts'),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _PlanCard(
                    title: 'Basic',
                    price: '₦3,000',
                    period: '/ 30 days',
                    tagline: 'Get your job live',
                    features: [
                      'Standard listing on /jobs',
                      'Appears in search',
                      'Basic applicant management',
                      '30-day visibility',
                    ],
                    packageId: 'job-basic',
                    highlighted: false,
                  ),
                  _PlanCard(
                    title: 'Featured',
                    price: '₦7,000',
                    period: '/ 30 days',
                    tagline: 'Stand out from the crowd',
                    features: [
                      'Everything in Basic',
                      'FEATURED badge on card',
                      'Priority in listings',
                      '30-day featured boost',
                      'Homepage appearance',
                    ],
                    packageId: 'job-featured',
                    highlighted: true,
                  ),
                  _PlanCard(
                    title: 'Premium',
                    price: '₦15,000',
                    period: '/ 60 days',
                    tagline: 'Maximum exposure',
                    features: [
                      'Everything in Featured',
                      'Pinned to top of homepage',
                      '60-day featured boost',
                      'Email blast to candidates',
                      'Priority support',
                    ],
                    packageId: 'job-premium',
                    highlighted: false,
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // ── BUNDLES ──
              _sectionTitle('Job Bundles — Save More'),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _PlanCard(
                    title: 'Starter',
                    price: '₦12,000',
                    period: '/ 5 jobs',
                    tagline: 'Save ₦3,000',
                    features: ['5 job postings', 'Valid for 12 months', 'Standard listings'],
                    packageId: 'bundle-5',
                    highlighted: false,
                  ),
                  _PlanCard(
                    title: 'Growth',
                    price: '₦20,000',
                    period: '/ 10 jobs',
                    tagline: 'Save ₦10,000',
                    features: ['10 job postings', 'Valid for 12 months', 'Standard listings'],
                    packageId: 'bundle-10',
                    highlighted: true,
                  ),
                  _PlanCard(
                    title: 'Scale',
                    price: '₦45,000',
                    period: '/ 25 jobs',
                    tagline: 'Save ₦30,000',
                    features: ['25 job postings', 'Valid for 12 months', 'Standard listings'],
                    packageId: 'bundle-25',
                    highlighted: false,
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // ── SUBSCRIPTIONS ──
              _sectionTitle('Monthly Subscriptions'),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _PlanCard(
                    title: 'Starter',
                    price: '₦10,000',
                    period: '/ month',
                    tagline: 'For small teams',
                    features: [
                      '3 active jobs at once',
                      'Verified company profile',
                      'Applicant management',
                      'Basic analytics',
                    ],
                    packageId: 'sub-starter',
                    highlighted: false,
                  ),
                  _PlanCard(
                    title: 'Business',
                    price: '₦25,000',
                    period: '/ month',
                    tagline: 'Most popular',
                    features: [
                      '10 active jobs at once',
                      'Featured listing included',
                      'Advanced analytics',
                      'Company branding tools',
                      'Priority support',
                    ],
                    packageId: 'sub-business',
                    highlighted: true,
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // ── EXTRAS ──
              _sectionTitle('Add-ons'),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _MiniCard(
                    icon: Icons.verified,
                    title: 'Verified Employer',
                    price: '₦10,000',
                    subtitle: 'Blue checkmark on your company profile forever',
                    packageId: 'verify-employer',
                  ),
                  _MiniCard(
                    icon: Icons.campaign,
                    title: 'Homepage Ad Banner',
                    price: '₦50,000 / month',
                    subtitle: 'Promote your brand at the top of the homepage',
                    packageId: 'ad-homepage',
                  ),
                  _MiniCard(
                    icon: Icons.ads_click,
                    title: 'Jobs Page Ad',
                    price: '₦25,000 / month',
                    subtitle: 'Sidebar banner shown on every jobs listing',
                    packageId: 'ad-jobs',
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // ── FAQ ──
              _sectionTitle('Common Questions'),
              const SizedBox(height: 24),
              const _Faq(
                q: 'Do I need to pay to post my first job?',
                a: 'Yes — but we offer a 7-day free trial for new companies. After that, choose any plan above.',
              ),
              const _Faq(
                q: 'How do I pay?',
                a: 'We accept cards, bank transfers, and USSD via Paystack. Payments are secure.',
              ),
              const _Faq(
                q: 'What happens if my job expires?',
                a: 'Expired jobs are hidden from public view. You can renew anytime from your dashboard.',
              ),
              const _Faq(
                q: 'Can I get a refund?',
                a: 'Yes — full refund within 48 hours if the job has received no applications.',
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      );
}

// ═══════════════════════════════════════════════════════════════════
// PLAN CARD
// ═══════════════════════════════════════════════════════════════════

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String tagline;
  final List<String> features;
  final String packageId;
  final bool highlighted;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.tagline,
    required this.features,
    required this.packageId,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlighted ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: highlighted ? 2 : 1,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.15),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(tagline,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price,
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(period,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 18, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f, style: const TextStyle(fontSize: 13.5)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: highlighted
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF0F172A),
                ),
                onPressed: () => context.go('/company/checkout?package=$packageId'),
                child: Text('Choose $title'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MINI CARD (for add-ons)
// ═══════════════════════════════════════════════════════════════════

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String price;
  final String subtitle;
  final String packageId;

  const _MiniCard({
    required this.icon,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.packageId,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 14),
              Text(price,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/company/checkout?package=$packageId'),
                  child: const Text('Buy Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// FAQ
// ═══════════════════════════════════════════════════════════════════

class _Faq extends StatelessWidget {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(a, style: TextStyle(color: Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }
}