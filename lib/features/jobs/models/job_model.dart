class JobModel {
  final String id;
  final String source;
  final String? externalId;
  final String? companyId;
  final String? companyName;
  final String? companyLogo;
  final String title;
  final String? description;
  final String? requirements;
  final String? location;
  final String? country;
  final String? remoteType;
  final String? employmentType;
  final String? category;
  final num? salaryMin;
  final num? salaryMax;
  final String? salaryCurrency;
  final List<String> skills;
  final String? jobUrl;
  final String? applyUrl;
  final DateTime? postedAt;
  final DateTime? expiresAt;
  final String status;
  final int views;

  JobModel({
    required this.id,
    required this.source,
    this.externalId,
    this.companyId,
    this.companyName,
    this.companyLogo,
    required this.title,
    this.description,
    this.requirements,
    this.location,
    this.country,
    this.remoteType,
    this.employmentType,
    this.category,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency,
    this.skills = const [],
    this.jobUrl,
    this.applyUrl,
    this.postedAt,
    this.expiresAt,
    this.status = 'active',
    this.views = 0,
  });

  String? get salaryLabel {
    if (salaryMin == null && salaryMax == null) return null;
    final cur = salaryCurrency ?? '';
    String fmt(num? v) {
      if (v == null) return '';
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
      return v.toString();
    }
    if (salaryMin != null && salaryMax != null) {
      return '$cur ${fmt(salaryMin)} - ${fmt(salaryMax)}';
    }
    return '$cur ${fmt(salaryMin ?? salaryMax)}';
  }

  bool get isExternal => source != 'company';

  factory JobModel.fromMap(Map<String, dynamic> m) => JobModel(
        id: m['id'].toString(),
        source: m['source'] ?? 'company',
        externalId: m['external_id'],
        companyId: m['company_id'],
        companyName: m['company_name'],
        companyLogo: m['company_logo'],
        title: m['title'] ?? '',
        description: m['description'],
        requirements: m['requirements'],
        location: m['location'],
        country: m['country'],
        remoteType: m['remote_type'],
        employmentType: m['employment_type'],
        category: m['category'],
        salaryMin: m['salary_min'],
        salaryMax: m['salary_max'],
        salaryCurrency: m['salary_currency'],
        skills: (m['skills'] as List?)?.cast<String>() ?? const [],
        jobUrl: m['job_url'],
        applyUrl: m['apply_url'],
        postedAt: m['posted_at'] != null
            ? DateTime.tryParse(m['posted_at'].toString())
            : null,
        expiresAt: m['expires_at'] != null
            ? DateTime.tryParse(m['expires_at'].toString())
            : null,
        status: m['status'] ?? 'active',
        views: m['views'] ?? 0,
      );
}