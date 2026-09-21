import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/supabase_service.dart';

class JobApplyDialog extends ConsumerStatefulWidget {
  final String jobId;
  const JobApplyDialog({super.key, required this.jobId});
  @override
  ConsumerState<JobApplyDialog> createState() => _State();
}

class _State extends ConsumerState<JobApplyDialog> {
  final _cover = TextEditingController();
  bool _loading = false;
  PlatformFile? _cv;
  String? _error;

  Future<void> _pick() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (r != null && r.files.isNotEmpty) {
      setState(() => _cv = r.files.first);
    }
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = SupabaseService.currentUser!;
      String? cvUrl;
      if (_cv != null && _cv!.bytes != null) {
        final path =
            'resumes/${user.id}/${DateTime.now().millisecondsSinceEpoch}_${_cv!.name}';
        await SupabaseService.client.storage
            .from('resumes')
            .uploadBinary(path, _cv!.bytes!);
        cvUrl = SupabaseService.client.storage
            .from('resumes')
            .getPublicUrl(path);
      }

      final job = await SupabaseService.client
          .from('jobs')
          .select('company_id')
          .eq('id', widget.jobId)
          .maybeSingle();

      await SupabaseService.client.from('applications').insert({
        'job_id': widget.jobId,
        'job_seeker_id': user.id,
        'company_id': job?['company_id'],
        'cover_letter': _cover.text.trim(),
        'cv_url': cvUrl,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted!')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apply for this Job',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Upload your CV and add a cover letter.',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFDC2626))),
                ),
              OutlinedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.upload_file),
                label: Text(_cv?.name ?? 'Upload CV (PDF, DOC)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cover,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Cover Letter (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Application'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}