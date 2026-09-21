// ignore_for_file: prefer_const_constructors, unused_import

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../features/jobs/models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onSave;
  final bool saved;
  const JobCard({super.key, required this.job, this.onSave, this.saved = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/jobs/${job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _logo(job),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 17)),
                        const SizedBox(height: 4),
                        Text(job.companyName ?? 'Unknown Company',
                            style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500)),
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
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(Icons.location_on_outlined, job.location ?? 'N/A'),
                  if (job.remoteType != null)
                    _pill(Icons.wifi, job.remoteType!),
                  if (job.employmentType != null)
                    _pill(Icons.schedule, job.employmentType!),
                ],
              ),
              if (job.salaryLabel != null) ...[
                const SizedBox(height: 12),
                Text(job.salaryLabel!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                        fontSize: 15)),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  _sourceBadge(job.source),
                  const Spacer(),
                  Text(
                    job.postedAt != null
                        ? timeago.format(job.postedAt!, allowFromNow: true)
                        : 'Recently',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo(JobModel j) {
    if (j.companyLogo != null && j.companyLogo!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(j.companyLogo!,
            width: 52, height: 52, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder()),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.business, color: Color(0xFF2563EB)),
      );

  Widget _pill(IconData i, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 14, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(t,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _sourceBadge(String src) {
    final map = {
      'company': ['OUR PLATFORM', Color(0xFF2563EB), Color(0xFFEFF6FF)],
      'boqqs': ['BOQQS', Color(0xFF059669), Color(0xFFECFDF5)],
      'himalayas': ['HIMALAYAS', Color(0xFF7C3AED), Color(0xFFF5F3FF)],
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
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: v[1] as Color),
      ),
    );
  }
}