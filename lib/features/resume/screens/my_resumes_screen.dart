import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/supabase_service.dart';
import '../providers/resume_provider.dart';

class MyResumesScreen extends ConsumerWidget {
  const MyResumesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumes = ref.watch(myResumesProvider);
    final loggedIn = SupabaseService.currentUser != null;

    if (!loggedIn) {
      return const Scaffold(
        body: Center(
            child: Text('Please log in to view your resumes.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Resumes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => context.go('/resume/create'),
              icon: const Icon(Icons.add),
              label: const Text('New Resume'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: resumes.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (list) {
                if (list.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Icon(Icons.description_outlined,
                              size: 60, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 16),
                          const Text('No resumes yet',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                              'Build your first professional resume in 2 minutes.',
                              style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () =>
                                context.go('/resume/create'),
                            icon: const Icon(Icons.add),
                            label: const Text('Build Resume'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final r = list[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: r.isPro
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.description,
                            color: r.isPro
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        title: Text(r.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${r.fullName} · ${r.isPro ? "Pro" : "Draft"}',
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: () =>
                              context.go('/resume/preview?id=${r.id}'),
                        ),
                        onTap: () =>
                            context.go('/resume/preview?id=${r.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}