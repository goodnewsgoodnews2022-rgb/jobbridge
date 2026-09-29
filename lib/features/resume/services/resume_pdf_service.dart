// Resume Builder — PDF generation service.
// Generates professional PDFs client-side. No server needed.

// ignore_for_file: prefer_const_constructors

import 'dart:typed_data';
import 'package:jobbridge/features/resume/resume_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;


class ResumePdfService {
  static Future<Uint8List> generate(
    ResumeModel r, {
    String template = 'modern',
  }) async {
    switch (template) {
      case 'classic':
        return _classic(r);
      case 'minimal':
        return _minimal(r);
      case 'modern':
      default:
        return _modern(r);
    }
  }

  // ═════════════════════════════════════════════════════════
  // MODERN TEMPLATE
  // ═════════════════════════════════════════════════════════
  static Future<Uint8List> _modern(ResumeModel r) async {
    final doc = pw.Document();
    final primary = PdfColor.fromInt(0xFF2563EB);
    final dark = PdfColor.fromInt(0xFF0F172A);
    final grey = PdfColor.fromInt(0xFF475569);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: primary, width: 2),
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        r.fullName.isEmpty ? 'Your Name' : r.fullName,
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: dark,
                        ),
                      ),
                      if (r.jobTitle.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          r.jobTitle,
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: primary,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (r.email.isNotEmpty) _contactLine(r.email, grey),
                    if (r.phone.isNotEmpty) _contactLine(r.phone, grey),
                    if (r.location.isNotEmpty) _contactLine(r.location, grey),
                    if (r.linkedin.isNotEmpty) _contactLine(r.linkedin, grey),
                    if (r.github.isNotEmpty) _contactLine(r.github, grey),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          if (r.summary.isNotEmpty) ...[
            _sectionHeader('PROFESSIONAL SUMMARY', primary),
            pw.SizedBox(height: 8),
            pw.Text(r.summary,
                style: pw.TextStyle(fontSize: 11, color: grey, lineSpacing: 3)),
            pw.SizedBox(height: 16),
          ],
          if (r.experience.isNotEmpty) ...[
            _sectionHeader('EXPERIENCE', primary),
            pw.SizedBox(height: 8),
            ...r.experience.map((e) => _experienceBlock(e, dark, grey)),
            pw.SizedBox(height: 12),
          ],
          if (r.education.isNotEmpty) ...[
            _sectionHeader('EDUCATION', primary),
            pw.SizedBox(height: 8),
            ...r.education.map((e) => _educationBlock(e, dark, grey)),
            pw.SizedBox(height: 12),
          ],
          if (r.skills.isNotEmpty) ...[
            _sectionHeader('SKILLS', primary),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: r.skills
                  .map((s) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFEFF6FF),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(s,
                            style: pw.TextStyle(
                                fontSize: 10, color: primary)),
                      ))
                  .toList(),
            ),
            pw.SizedBox(height: 16),
          ],
          if (r.projects.isNotEmpty) ...[
            _sectionHeader('PROJECTS', primary),
            pw.SizedBox(height: 8),
            ...r.projects.map((p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(p.name,
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: dark)),
                      if (p.link.isNotEmpty)
                        pw.Text(p.link,
                            style: pw.TextStyle(
                                fontSize: 10, color: primary)),
                      if (p.description.isNotEmpty)
                        pw.Text(p.description,
                            style: pw.TextStyle(
                                fontSize: 11, color: grey, lineSpacing: 2)),
                    ],
                  ),
                )),
            pw.SizedBox(height: 12),
          ],
          if (r.certifications.isNotEmpty) ...[
            _sectionHeader('CERTIFICATIONS', primary),
            pw.SizedBox(height: 8),
            ...r.certifications.map((c) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    children: [
                      pw.Text('• ',
                          style: pw.TextStyle(color: primary, fontSize: 11)),
                      pw.Expanded(
                        child: pw.Text(
                          '${c.name}${c.issuer.isNotEmpty ? " — ${c.issuer}" : ""}${c.year.isNotEmpty ? " (${c.year})" : ""}',
                          style: pw.TextStyle(fontSize: 11, color: grey),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
    return doc.save();
  }

  // ═════════════════════════════════════════════════════════
  // CLASSIC TEMPLATE
  // ═════════════════════════════════════════════════════════
  static Future<Uint8List> _classic(ResumeModel r) async {
    final doc = pw.Document();
    final dark = PdfColor.fromInt(0xFF0F172A);
    final grey = PdfColor.fromInt(0xFF475569);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  r.fullName.isEmpty ? 'Your Name' : r.fullName,
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: dark,
                    letterSpacing: 2,
                  ),
                ),
                if (r.jobTitle.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(r.jobTitle,
                      style: pw.TextStyle(
                          fontSize: 13, color: grey, letterSpacing: 1)),
                ],
                pw.SizedBox(height: 8),
                pw.Text(
                  [
                    if (r.email.isNotEmpty) r.email,
                    if (r.phone.isNotEmpty) r.phone,
                    if (r.location.isNotEmpty) r.location,
                  ].join('  •  '),
                  style: pw.TextStyle(fontSize: 10, color: grey),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: dark, thickness: 1),
          pw.SizedBox(height: 20),
          if (r.summary.isNotEmpty) ...[
            _sectionHeaderClassic('SUMMARY', dark),
            pw.SizedBox(height: 6),
            pw.Text(r.summary,
                style: pw.TextStyle(fontSize: 11, color: grey, lineSpacing: 3)),
            pw.SizedBox(height: 14),
          ],
          if (r.experience.isNotEmpty) ...[
            _sectionHeaderClassic('EXPERIENCE', dark),
            pw.SizedBox(height: 6),
            ...r.experience.map((e) => _experienceBlockClassic(e, dark, grey)),
            pw.SizedBox(height: 10),
          ],
          if (r.education.isNotEmpty) ...[
            _sectionHeaderClassic('EDUCATION', dark),
            pw.SizedBox(height: 6),
            ...r.education.map((e) => _educationBlockClassic(e, dark, grey)),
            pw.SizedBox(height: 10),
          ],
          if (r.skills.isNotEmpty) ...[
            _sectionHeaderClassic('SKILLS', dark),
            pw.SizedBox(height: 6),
            pw.Text(r.skills.join('  •  '),
                style: pw.TextStyle(fontSize: 11, color: grey)),
            pw.SizedBox(height: 10),
          ],
          if (r.projects.isNotEmpty) ...[
            _sectionHeaderClassic('PROJECTS', dark),
            pw.SizedBox(height: 6),
            ...r.projects.map((p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(p.name,
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: dark)),
                      pw.Text(p.description,
                          style: pw.TextStyle(fontSize: 11, color: grey)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
    return doc.save();
  }

  // ═════════════════════════════════════════════════════════
  // MINIMAL TEMPLATE
  // ═════════════════════════════════════════════════════════
  static Future<Uint8List> _minimal(ResumeModel r) async {
    final doc = pw.Document();
    final dark = PdfColor.fromInt(0xFF0F172A);
    final grey = PdfColor.fromInt(0xFF64748B);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (ctx) => [
          pw.Text(
            r.fullName.isEmpty ? 'Your Name' : r.fullName,
            style: pw.TextStyle(
              fontSize: 30,
              fontWeight: pw.FontWeight.normal,
              color: dark,
              letterSpacing: -0.5,
            ),
          ),
          if (r.jobTitle.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(r.jobTitle,
                style: pw.TextStyle(fontSize: 13, color: grey)),
          ],
          pw.SizedBox(height: 6),
          pw.Text(
            [
              if (r.email.isNotEmpty) r.email,
              if (r.phone.isNotEmpty) r.phone,
              if (r.location.isNotEmpty) r.location,
            ].join('   '),
            style: pw.TextStyle(fontSize: 10, color: grey),
          ),
          pw.SizedBox(height: 32),
          if (r.summary.isNotEmpty) ...[
            _sectionHeaderMinimal('About'),
            pw.SizedBox(height: 6),
            pw.Text(r.summary,
                style: pw.TextStyle(fontSize: 11, color: dark, lineSpacing: 4)),
            pw.SizedBox(height: 22),
          ],
          if (r.experience.isNotEmpty) ...[
            _sectionHeaderMinimal('Experience'),
            pw.SizedBox(height: 6),
            ...r.experience.map((e) => _experienceBlockClassic(e, dark, grey)),
            pw.SizedBox(height: 16),
          ],
          if (r.education.isNotEmpty) ...[
            _sectionHeaderMinimal('Education'),
            pw.SizedBox(height: 6),
            ...r.education.map((e) => _educationBlockClassic(e, dark, grey)),
            pw.SizedBox(height: 16),
          ],
          if (r.skills.isNotEmpty) ...[
            _sectionHeaderMinimal('Skills'),
            pw.SizedBox(height: 6),
            pw.Text(r.skills.join('   ·   '),
                style: pw.TextStyle(fontSize: 11, color: dark)),
          ],
        ],
      ),
    );
    return doc.save();
  }

  // ═════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════
  static pw.Widget _contactLine(String text, PdfColor color) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(text,
            style: pw.TextStyle(fontSize: 10, color: color)),
      );

  static pw.Widget _sectionHeader(String title, PdfColor color) =>
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: color, width: 1),
          ),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      );

  static pw.Widget _sectionHeaderClassic(String title, PdfColor color) =>
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 2,
        ),
      );

  static pw.Widget _sectionHeaderMinimal(String title) => pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF94A3B8),
          letterSpacing: 2,
        ),
      );

  static pw.Widget _experienceBlock(
          ExperienceItem e, PdfColor dark, PdfColor grey) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    e.role,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: dark,
                    ),
                  ),
                ),
                pw.Text(
                  '${e.start}${e.end.isNotEmpty ? " – ${e.end}" : ""}',
                  style: pw.TextStyle(fontSize: 10, color: grey),
                ),
              ],
            ),
            pw.Text(e.company,
                style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColor.fromInt(0xFF2563EB),
                    fontWeight: pw.FontWeight.bold)),
            if (e.description.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(e.description,
                  style: pw.TextStyle(
                      fontSize: 11, color: grey, lineSpacing: 2)),
            ],
          ],
        ),
      );

  static pw.Widget _experienceBlockClassic(
          ExperienceItem e, PdfColor dark, PdfColor grey) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(e.role,
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: dark)),
            pw.Text(
              '${e.company}${e.start.isNotEmpty ? " | ${e.start}" : ""}${e.end.isNotEmpty ? " – ${e.end}" : ""}',
              style: pw.TextStyle(fontSize: 10, color: grey),
            ),
            if (e.description.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(e.description,
                  style: pw.TextStyle(
                      fontSize: 11, color: grey, lineSpacing: 2)),
            ],
          ],
        ),
      );

  static pw.Widget _educationBlock(
          EducationItem e, PdfColor dark, PdfColor grey) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(e.degree,
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: dark)),
                  pw.Text(e.school,
                      style: pw.TextStyle(fontSize: 11, color: grey)),
                ],
              ),
            ),
            pw.Text(e.year,
                style: pw.TextStyle(fontSize: 10, color: grey)),
          ],
        ),
      );

  static pw.Widget _educationBlockClassic(
          EducationItem e, PdfColor dark, PdfColor grey) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(e.degree,
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: dark)),
            pw.Text(
              '${e.school}${e.year.isNotEmpty ? " | ${e.year}" : ""}',
              style: pw.TextStyle(fontSize: 10, color: grey),
            ),
          ],
        ),
      );
}