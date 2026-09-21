import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/job_card.dart';
import '../../../shared/widgets/loading_grid.dart';
import '../providers/jobs_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});
  @override
  ConsumerState<SearchScreen> createState() => _State();
}

class _State extends ConsumerState<SearchScreen> {
  late final TextEditingController _c;
  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery.isNotEmpty) {
        ref.read(jobFiltersProvider.notifier).update(
            (s) => s.copyWith(query: widget.initialQuery));
      }
    });
  }

  void _apply() {
    ref.read(jobFiltersProvider.notifier).update(
        (s) => s.copyWith(query: _c.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(allJobsProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Search Jobs',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(Icons.search, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _c,
                          onSubmitted: (_) => _apply(),
                          decoration: const InputDecoration(
                            hintText: 'Search jobs…',
                            border: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                      ElevatedButton(
                          onPressed: _apply, child: const Text('Search')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              jobs.when(
                loading: () => const LoadingGrid(),
                error: (e, _) => Text('Error: $e'),
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(60),
                        child: Center(child: Text('No results found.')),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 480,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 2.1,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => JobCard(job: list[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}