import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbridge/features/resume/resume_model.dart';
import 'package:jobbridge/features/resume/services/resume_pdf_service.dart';
import 'package:printing/printing.dart';
import '../../../core/services/payment_service.dart';
import '../providers/resume_provider.dart';


class ResumePreviewScreen extends ConsumerStatefulWidget {
  final String resumeId;
  const ResumePreviewScreen({super.key, required this.resumeId});

  @override
  ConsumerState<ResumePreviewScreen> createState() => _State();
}

class _State extends ConsumerState<ResumePreviewScreen> {
  String _template = 'modern';
  bool _paying = false;

  final _templates = const [
    {'id': 'modern', 'label': 'Modern', 'locked': false},
    {'id': 'classic', 'label': 'Classic', 'locked': true},
    {'id': 'minimal', 'label': 'Minimal', 'locked': true},
  ];

  Future<void> _download(ResumeModel r, bool isPro) async {
    if (!isPro) {
      _showUpgradeDialog(r);
      return;
    }
    final bytes =
        await ResumePdfService.generate(r, template: _template);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${r.fullName.replaceAll(' ', '_')}_Resume.pdf',
    );
  }

  Future<void> _upgrade(ResumeModel r) async {
    setState(() => _paying = true);
    try {
      final result = await PaymentService.startResumeCheckout(
        packageId: 'resume-pro',
        resumeId: r.id!,
      );
      if (!mounted) return;
      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Payment failed')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Complete the payment in the opened tab.'),
            backgroundColor: Color(0xFF2563EB),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _showUpgradeDialog(ResumeModel r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium,
                size: 48, color: Color(0xFF2563EB)),
            const SizedBox(height: 16),
            const Text('Upgrade to Professional',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Download your resume as PDF, use premium templates, and apply with confidence.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text('₦2,500',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF059669))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _paying
                    ? null
                    : () {
                        Navigator.pop(context);
                        _upgrade(r);
                      },
                child: Text(_paying ? 'Processing…' : 'Pay ₦2,500'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe later'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(resumeByIdProvider(widget.resumeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Preview'),
        actions: [
          IconButton(
            onPressed: () => context
                .go('/resume/create?editId=${widget.resumeId}'),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (r) {
          if (r == null) {
            return const Center(child: Text('Resume not found'));
          }
          final isPro = r.isPro;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPro)
                      _statusBanner(
                        icon: Icons.verified,
                        color: const Color(0xFF059669),
                        bg: const Color(0xFFECFDF5),
                        text: 'Pro Resume — All templates unlocked',
                      )
                    else
                      _statusBanner(
                        icon: Icons.info_outline,
                        color: const Color(0xFFD97706),
                        bg: const Color(0xFFFFFBEB),
                        text: 'Free version — Upgrade to download PDF',
                      ),
                    const SizedBox(height: 24),
                    const Text('Choose a Template',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _templates.map((t) {
                        final isLocked = (t['locked'] as bool) && !isPro;
                        final selected = _template == t['id'];
                        return InkWell(
                          onTap: () {
                            if (isLocked) {
                              _showUpgradeDialog(r);
                              return;
                            }
                            setState(
                                () => _template = t['id'] as String);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF2563EB)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLocked)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.lock,
                                        size: 14,
                                        color: Color(0xFF94A3B8)),
                                  ),
                                Text(
                                  t['label'] as String,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text('Preview',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Container(
                      height: 600,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: PdfPreview(
                        build: (format) => ResumePdfService.generate(r,
                            template: _template),
                        allowPrinting: isPro,
                        allowSharing: isPro,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/my-resumes'),
                            icon: const Icon(Icons.list_alt),
                            label: const Text('All My Resumes'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: isPro
                                ? () => _download(r, isPro)
                                : () => _showUpgradeDialog(r),
                            icon: Icon(isPro
                                ? Icons.download
                                : Icons.lock_outline),
                            label: Text(isPro
                                ? 'Download PDF'
                                : 'Upgrade to Download'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusBanner({
    required IconData icon,
    required Color color,
    required Color bg,
    required String text,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}