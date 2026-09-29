// ignore_for_file: prefer_const_constructors, unused_import

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../features/jobs/models/job_model.dart';
import 'safe_image.dart';                          // ✅ relative import // ← ADDED for CORS-safe image loading

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onSave;
  final bool saved;

  const JobCard({
    super.key,
    required this.job,
    this.onSave,
    this.saved = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/jobs/${job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─────────────────────────────────────────────
              // HEADER: logo + title + company + save button
              // ─────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _logo(job),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          job.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            height: 1.25,
                          ),
                        ),
                        if (job.featured)
  Positioned(
    top: 0, left: 0,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '★ FEATURED',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    ),
  ),
                        const SizedBox(height: 4),
                        Text(
                          job.companyName ?? 'Unknown Company',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onSave != null)
                    IconButton(
                      onPressed: onSave,
                      icon: Icon(
                        saved ? Icons.bookmark : Icons.bookmark_border,
                        color: saved
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                      ),
                      tooltip: saved ? 'Remove from saved' : 'Save job',
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // ─────────────────────────────────────────────
              // META PILLS: location, remote, type
              // ─────────────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (job.location != null && job.location!.trim().isNotEmpty)
                    _pill(Icons.location_on_outlined, job.location!.trim()),
                  if (job.remoteType != null &&
                      job.remoteType!.trim().isNotEmpty)
                    _pill(Icons.wifi, job.remoteType!.trim()),
                  if (job.employmentType != null &&
                      job.employmentType!.trim().isNotEmpty)
                    _pill(Icons.schedule, job.employmentType!.trim()),
                ],
              ),

              // ─────────────────────────────────────────────
              // SALARY (optional)
              // ─────────────────────────────────────────────
              if (job.salaryLabel != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        job.salaryLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // ─────────────────────────────────────────────
              // FOOTER: source badge + timestamp
              // ─────────────────────────────────────────────
              Row(
                children: [
                  Flexible(child: _sourceBadge(job.source)),
                  const Spacer(),
                  const SizedBox(width: 8),
                  Text(
                    job.postedAt != null
                        ? timeago.format(job.postedAt!, allowFromNow: true)
                        : 'Recently',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LOGO — now uses SafeImage for CORS-safe loading
  // ─────────────────────────────────────────────
  Widget _logo(JobModel j) {
    return  SafeImage(
      url: j.companyLogo,
      width: 52,
      height: 52,
      borderRadius: 10,
      placeholder: _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.business,
          color: Color(0xFF2563EB),
          size: 26,
        ),
      );

  // ─────────────────────────────────────────────
  // PILL (with max-width + ellipsis)
  // ─────────────────────────────────────────────
  Widget _pill(IconData icon, String text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF475569)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SOURCE BADGE (all 4 sources + fallback)
  // ─────────────────────────────────────────────
  Widget _sourceBadge(String src) {
   final map = <String, List>{
  'company':       ['OUR PLATFORM',  Color(0xFF2563EB), Color(0xFFEFF6FF)],
  'boqqs':         ['VIA BOQQS',     Color(0xFF059669), Color(0xFFECFDF5)],
  'himalayas':     ['HIMALAYAS',     Color(0xFF7C3AED), Color(0xFFF5F3FF)],
  'arbeitnow':     ['ARBEITNOW',     Color(0xFFEA580C), Color(0xFFFFF7ED)],
  
  'progigfinder':  ['PROGIGFINDER',  Color(0xFF0D9488), Color(0xFFF0FDFA)],
};
    final v = map[src] ?? map['company']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: v[2] as Color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        v[0] as String,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: v[1] as Color,
        ),
      ),
    );
  }
}