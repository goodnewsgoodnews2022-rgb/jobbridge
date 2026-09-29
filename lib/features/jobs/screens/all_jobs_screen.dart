// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/job_card.dart';
import '../../../shared/widgets/loading_grid.dart';
import '../providers/jobs_provider.dart';

class AllJobsScreen extends ConsumerWidget {
  const AllJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(jobFiltersProvider);
    final jobs = ref.watch(allJobsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'All Jobs',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Browse jobs from companies, BOQQS, Himalayas and more.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // ─────────────────────────────────────────────
              // FILTER BAR
              // ─────────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _dropdown(
                        label: 'Category',
                        value: filters.category,
                        items: AppConstants.categories,
                        onChanged: (v) => ref
                            .read(jobFiltersProvider.notifier)
                            .update((s) => s.copyWith(category: v)),
                      ),
                      _dropdown(
                        label: 'Remote',
                        value: filters.remoteType,
                        items: AppConstants.remoteTypes,
                        onChanged: (v) => ref
                            .read(jobFiltersProvider.notifier)
                            .update((s) => s.copyWith(remoteType: v)),
                      ),
                      _dropdown(
                        label: 'Type',
                        value: filters.employmentType,
                        items: AppConstants.employmentTypes,
                        onChanged: (v) => ref
                            .read(jobFiltersProvider.notifier)
                            .update((s) => s.copyWith(employmentType: v)),
                      ),
                      _dropdown(
                        label: 'Source',
                        value: filters.source,
                      items: const [
  'company',
  'progigfinder',
  'arbeitnow',
  'himalayas',
  
  'boqqs',
],
                        onChanged: (v) => ref
                            .read(jobFiltersProvider.notifier)
                            .update((s) => s.copyWith(source: v)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => ref
                            .read(jobFiltersProvider.notifier)
                            .state = const JobFilters(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ─────────────────────────────────────────────
              // JOBS GRID
              // ─────────────────────────────────────────────
              jobs.when(
                loading: () => const LoadingGrid(),
                error: (e, _) => Text('Error: $e'),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.work_off_outlined,
                      title: 'No jobs match your filters',
                      subtitle: 'Try clearing some filters.',
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
                    itemCount: list.length,
                    itemBuilder: (_, i) => JobCard(job: list[i]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FILTER DROPDOWN
  // ─────────────────────────────────────────────
  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String?>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text('Any $label'),
          ),
          ...items.map(
            (e) => DropdownMenuItem<String?>(
              value: e,
              child: Text(e),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}