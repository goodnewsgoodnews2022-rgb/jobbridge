import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/job_card.dart';
import '../../../shared/widgets/loading_grid.dart';
import '../providers/jobs_provider.dart';

class CategoryJobsScreen extends ConsumerStatefulWidget {
  final String category;
  const CategoryJobsScreen({super.key, required this.category});
  @override
  ConsumerState<CategoryJobsScreen> createState() => _State();
}

class _State extends ConsumerState<CategoryJobsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobFiltersProvider.notifier).state =
          JobFilters(category: widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(allJobsProvider);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(widget.category,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 24),
                jobs.when(
                  loading: () => const LoadingGrid(),
                  error: (e, _) => Text('Error: $e'),
                  data: (list) => list.isEmpty
                      ? const EmptyState(
                          icon: Icons.work_off_outlined,
                          title: 'No jobs in this category yet',
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 480,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            mainAxisExtent: 300,
                          ),
                          itemCount: list.length,
                          itemBuilder: (_, i) => JobCard(job: list[i]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}