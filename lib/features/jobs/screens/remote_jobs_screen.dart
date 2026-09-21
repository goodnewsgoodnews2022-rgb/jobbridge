import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/job_card.dart';
import '../../../shared/widgets/loading_grid.dart';
import '../providers/jobs_provider.dart';

class RemoteJobsScreen extends ConsumerWidget {
  const RemoteJobsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(remoteJobsProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Remote Jobs',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Work from anywhere — roles from Himalayas + more.',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              jobs.when(
                loading: () => const LoadingGrid(),
                error: (e, _) => Text('Error: $e'),
                data: (list) => GridView.builder(
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