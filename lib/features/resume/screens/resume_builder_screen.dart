import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbridge/features/resume/resume_model.dart';
import '../../../core/services/supabase_service.dart';

import '../providers/resume_provider.dart';

class ResumeBuilderScreen extends ConsumerStatefulWidget {
  final String? editId;
  const ResumeBuilderScreen({super.key, this.editId});

  @override
  ConsumerState<ResumeBuilderScreen> createState() => _State();
}

class _State extends ConsumerState<ResumeBuilderScreen> {
  final _form = GlobalKey<FormState>();

  final _title = TextEditingController(text: 'My Resume');
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _linkedin = TextEditingController();
  final _github = TextEditingController();
  final _jobTitle = TextEditingController();
  final _summary = TextEditingController();
  final _skills = TextEditingController();

  final List<ExperienceItem> _experience = [];
  final List<EducationItem> _education = [];
  final List<ProjectItem> _projects = [];
  final List<CertificationItem> _certs = [];

  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final r = await ref.read(resumeByIdProvider(widget.editId!).future);
    if (r != null) {
      _title.text = r.title;
      _name.text = r.fullName;
      _email.text = r.email;
      _phone.text = r.phone;
      _location.text = r.location;
      _linkedin.text = r.linkedin;
      _github.text = r.github;
      _jobTitle.text = r.jobTitle;
      _summary.text = r.summary;
      _skills.text = r.skills.join(', ');
      _experience.addAll(r.experience);
      _education.addAll(r.education);
      _projects.addAll(r.projects);
      _certs.addAll(r.certifications);
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _title.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _location.dispose();
    _linkedin.dispose();
    _github.dispose();
    _jobTitle.dispose();
    _summary.dispose();
    _skills.dispose();
    super.dispose();
  }

  ResumeModel _buildModel() => ResumeModel(
        id: widget.editId,
        title: _title.text.trim(),
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        location: _location.text.trim(),
        linkedin: _linkedin.text.trim(),
        github: _github.text.trim(),
        jobTitle: _jobTitle.text.trim(),
        summary: _summary.text.trim(),
        skills: _skills.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        experience: _experience,
        education: _education,
        projects: _projects,
        certifications: _certs,
      );

  Future<void> _save({required bool preview}) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final user = SupabaseService.currentUser!;
      final data = _buildModel().toMap();
      data['user_id'] = user.id;

      final res = await SupabaseService.client
          .from('resumes')
          .upsert(data)
          .select()
          .single();

      final id = res['id'];
      ref.invalidate(myResumesProvider);

      if (mounted) {
        if (preview) {
          context.go('/resume/preview?id=$id');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Resume saved'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editId == null ? 'Build Resume' : 'Edit Resume'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tipBanner(),
                  const SizedBox(height: 24),

                  _sectionTitle('Resume Title'),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                        hintText: 'e.g. My Flutter Resume'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),

                  _sectionTitle('Personal Information'),
                  TextFormField(
                    controller: _name,
                    decoration:
                        const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _email,
                        decoration:
                            const InputDecoration(labelText: 'Email'),
                        validator: (v) =>
                            !v!.contains('@') ? 'Enter valid email' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        decoration:
                            const InputDecoration(labelText: 'Phone'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _location,
                    decoration:
                        const InputDecoration(labelText: 'Location'),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _linkedin,
                        decoration: const InputDecoration(
                            labelText: 'LinkedIn (optional)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _github,
                        decoration: const InputDecoration(
                            labelText: 'GitHub (optional)'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _jobTitle,
                    decoration: const InputDecoration(
                      labelText: 'Professional Title',
                      hintText: 'e.g. Flutter Developer',
                    ),
                  ),

                  _sectionTitle('Professional Summary'),
                  TextFormField(
                    controller: _summary,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Brief overview of your experience, skills, and career goals…',
                      alignLabelWithHint: true,
                    ),
                  ),

                  _sectionTitle('Skills'),
                  TextFormField(
                    controller: _skills,
                    decoration: const InputDecoration(
                      hintText: 'Flutter, Dart, Firebase, Supabase',
                      labelText: 'Comma-separated skills',
                    ),
                  ),

                  _listHeader('Work Experience', onAdd: _addExperience),
                  if (_experience.isEmpty)
                    _emptyHint('No experience added yet. Click Add.'),
                  ..._experience
                      .asMap()
                      .entries
                      .map((e) => _experienceRow(e.key, e.value)),

                  _listHeader('Education', onAdd: _addEducation),
                  if (_education.isEmpty)
                    _emptyHint('No education added yet. Click Add.'),
                  ..._education
                      .asMap()
                      .entries
                      .map((e) => _educationRow(e.key, e.value)),

                  _listHeader('Projects', onAdd: _addProject),
                  if (_projects.isEmpty)
                    _emptyHint('No projects added yet. Click Add.'),
                  ..._projects
                      .asMap()
                      .entries
                      .map((e) => _projectRow(e.key, e.value)),

                  _listHeader('Certifications', onAdd: _addCert),
                  if (_certs.isEmpty)
                    _emptyHint('No certifications added yet. Click Add.'),
                  ..._certs
                      .asMap()
                      .entries
                      .map((e) => _certRow(e.key, e.value)),

                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => _save(preview: false),
                          child: const Text('Save Draft'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _save(preview: true),
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.visibility),
                          label: Text(_saving
                              ? 'Saving…'
                              : 'Preview & Download'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tipBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          children: [
            Icon(Icons.tips_and_updates,
                color: Color(0xFF2563EB), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Fill in the details — you can preview and edit before downloading.',
                style:
                    TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800)),
      );

  Widget _listHeader(String title, {required VoidCallback onAdd}) =>
      Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
      );

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      );

  // ── Experience ──
  void _addExperience() =>
      setState(() => _experience.add(ExperienceItem()));

  Widget _experienceRow(int i, ExperienceItem e) => _listCard(
        index: i,
        onDelete: () => setState(() => _experience.removeAt(i)),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  initialValue: e.role,
                  decoration:
                      const InputDecoration(labelText: 'Role'),
                  onChanged: (v) => e.role = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: e.company,
                  decoration:
                      const InputDecoration(labelText: 'Company'),
                  onChanged: (v) => e.company = v,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  initialValue: e.start,
                  decoration: const InputDecoration(
                      labelText: 'Start (e.g. Jan 2023)'),
                  onChanged: (v) => e.start = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: e.end,
                  decoration: const InputDecoration(
                      labelText: 'End (or Present)'),
                  onChanged: (v) => e.end = v,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: e.description,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description', alignLabelWithHint: true),
              onChanged: (v) => e.description = v,
            ),
          ],
        ),
      );

  // ── Education ──
  void _addEducation() =>
      setState(() => _education.add(EducationItem()));

  Widget _educationRow(int i, EducationItem e) => _listCard(
        index: i,
        onDelete: () => setState(() => _education.removeAt(i)),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  initialValue: e.degree,
                  decoration: const InputDecoration(
                      labelText: 'Degree / Course'),
                  onChanged: (v) => e.degree = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: e.school,
                  decoration: const InputDecoration(
                      labelText: 'School / University'),
                  onChanged: (v) => e.school = v,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: e.year,
              decoration: const InputDecoration(
                  labelText: 'Year (e.g. 2020 – 2024)'),
              onChanged: (v) => e.year = v,
            ),
          ],
        ),
      );

  // ── Projects ──
  void _addProject() => setState(() => _projects.add(ProjectItem()));

  Widget _projectRow(int i, ProjectItem p) => _listCard(
        index: i,
        onDelete: () => setState(() => _projects.removeAt(i)),
        child: Column(
          children: [
            TextFormField(
              initialValue: p.name,
              decoration:
                  const InputDecoration(labelText: 'Project Name'),
              onChanged: (v) => p.name = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: p.link,
              decoration:
                  const InputDecoration(labelText: 'Link (optional)'),
              onChanged: (v) => p.link = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: p.description,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description', alignLabelWithHint: true),
              onChanged: (v) => p.description = v,
            ),
          ],
        ),
      );

  // ── Certs ──
  void _addCert() =>
      setState(() => _certs.add(CertificationItem()));

  Widget _certRow(int i, CertificationItem c) => _listCard(
        index: i,
        onDelete: () => setState(() => _certs.removeAt(i)),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: c.name,
                  decoration: const InputDecoration(
                      labelText: 'Certification'),
                  onChanged: (v) => c.name = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: c.year,
                  decoration:
                      const InputDecoration(labelText: 'Year'),
                  onChanged: (v) => c.year = v,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: c.issuer,
              decoration: const InputDecoration(
                  labelText: 'Issuing Organization'),
              onChanged: (v) => c.issuer = v,
            ),
          ],
        ),
      );

  Widget _listCard({
    required int index,
    required VoidCallback onDelete,
    required Widget child,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text('#${index + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8))),
                const Spacer(),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Color(0xFFDC2626)),
                  tooltip: 'Remove',
                ),
              ],
            ),
            child,
          ],
        ),
      );
}