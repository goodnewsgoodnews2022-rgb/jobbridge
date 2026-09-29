// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/job_card.dart';
import '../../jobs/providers/jobs_provider.dart';
import '../../../shared/widgets/resume_builder_cta.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _State();
}

class _State extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _goSearch([String? override]) {
    final q = (override ?? _search.text).trim();
    context.go('/search?q=${Uri.encodeComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    final latest = ref.watch(latestJobsProvider);
    final stats = ref.watch(sourceStatsProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ═══════════════════════════════════════════════════════
          // HERO
          // ═══════════════════════════════════════════════════════
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 48 : 80,
              horizontal: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  children: [
                    // ── LIVE JOB COUNT BADGE ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: stats.when(
                        loading: () => const _HeroBadgeText('🚀 Loading jobs…'),
                        error: (_, __) =>
                            const _HeroBadgeText('🚀 Live opportunities'),
                        data: (m) {
                          final total =
                              m.values.fold<int>(0, (a, b) => a + b);
                          final display =
                              total >= 1000 ? '${(total / 1000).toStringAsFixed(1)}k+' : '$total';
                          return _HeroBadgeText('🚀 $display live opportunities');
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Find your next\ncareer move',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 36 : 52,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Search thousands of jobs from top companies, plus remote roles worldwide — all in one place.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: isMobile ? 15 : 17,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── SEARCH BAR ──
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.search, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _search,
                              onSubmitted: (_) => _goSearch(),
                              decoration: const InputDecoration(
                                hintText: 'Job title, keyword, or company…',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _goSearch(),
                            child: const Text('Search'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── QUICK TAG CHIPS (custom, no theme conflict) ──
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Flutter',
                        'Designer',
                        'Marketing',
                        'Remote',
                        'Finance',
                        'Developer',
                      ]
                          .map(
                            (tag) => _QuickTagChip(
                              label: tag,
                              onTap: () => _goSearch(tag),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════
          // CATEGORIES
          // ═══════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Explore by Category',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/categories'),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 80,
                    ),
                    itemCount: 8,
                    itemBuilder: (_, i) {
                      final c = AppConstants.categories[i];
                      return _CategoryTile(name: c);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════
          // LATEST JOBS
          // ═══════════════════════════════════════════════════════
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Latest Jobs',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/jobs'),
                        child: const Text('Browse all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  latest.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('Error: $e'),
                    data: (jobs) {
                      if (jobs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'No jobs yet. Check back soon!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 480,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 320,
                        ),
                        itemCount: jobs.length,
                        itemBuilder: (_, i) => JobCard(job: jobs[i]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
            // RESUME BUILDER CTA
          // ═══════════════════════════════════════════════════════
          const ResumeBuilderCta(),

          // ═══════════════════════════════════════════════════════
          // REMOTE CTA
          // ═══════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Work from anywhere 🌍',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Explore thousands of remote jobs from companies hiring worldwide.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2563EB),
                            ),
                            onPressed: () => context.go('/remote-jobs'),
                            child: const Text('Browse Remote Jobs'),
                          ),
                        ],
                      ),
                    ),
                    if (MediaQuery.of(context).size.width > 700)
                      const Icon(Icons.public,
                          size: 140, color: Colors.white24),
                  ],
                ),
              ),
            ),
          ),
                    // ═══════════════════════════════════════════════════════
         

          // ═══════════════════════════════════════════════════════
          // FOOTER
          // ═══════════════════════════════════════════════════════
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.all(40),
            child: const Center(
              child: Text(
                '© 2026 JobBridge. Connecting talent with opportunity.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HERO BADGE TEXT
// ═══════════════════════════════════════════════════════════════════

class _HeroBadgeText extends StatelessWidget {
  final String text;
  const _HeroBadgeText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// QUICK TAG CHIP — custom container, immune to theme override
// ═══════════════════════════════════════════════════════════════════

class _QuickTagChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickTagChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CATEGORY TILE
// ═══════════════════════════════════════════════════════════════════

class _CategoryTile extends StatelessWidget {
  final String name;
  const _CategoryTile({required this.name});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () =>
            context.go('/category/${Uri.encodeComponent(name)}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}