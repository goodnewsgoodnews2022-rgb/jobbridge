// Resume Builder data model.
// Stores all info a user fills in the resume builder form.

class ResumeModel {
  String? id;
  String title;
  String template;

  // Personal
  String fullName;
  String email;
  String phone;
  String location;
  String linkedin;
  String github;
  String website;
  String jobTitle;

  // Content
  String summary;
  List<ExperienceItem> experience;
  List<EducationItem> education;
  List<String> skills;
  List<ProjectItem> projects;
  List<CertificationItem> certifications;
  List<String> languages;

  // Payment
  bool isPro;
  String package;
  String paymentStatus;
  String? pdfUrl;

  ResumeModel({
    this.id,
    this.title = 'My Resume',
    this.template = 'modern',
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedin = '',
    this.github = '',
    this.website = '',
    this.jobTitle = '',
    this.summary = '',
    this.experience = const [],
    this.education = const [],
    this.skills = const [],
    this.projects = const [],
    this.certifications = const [],
    this.languages = const [],
    this.isPro = false,
    this.package = 'free',
    this.paymentStatus = 'free',
    this.pdfUrl,
  });

  factory ResumeModel.fromMap(Map<String, dynamic> m) => ResumeModel(
        id: m['id'],
        title: m['title'] ?? 'My Resume',
        template: m['template'] ?? 'modern',
        fullName: m['full_name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        location: m['location'] ?? '',
        linkedin: m['linkedin'] ?? '',
        github: m['github'] ?? '',
        website: m['website'] ?? '',
        jobTitle: m['job_title'] ?? '',
        summary: m['summary'] ?? '',
        experience: (m['experience'] as List? ?? [])
            .map((e) => ExperienceItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        education: (m['education'] as List? ?? [])
            .map((e) => EducationItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        skills: (m['skills'] as List? ?? []).cast<String>(),
        projects: (m['projects'] as List? ?? [])
            .map((e) => ProjectItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        certifications: (m['certifications'] as List? ?? [])
            .map((e) =>
                CertificationItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        languages: (m['languages'] as List? ?? []).cast<String>(),
        isPro: m['is_pro'] ?? false,
        package: m['package'] ?? 'free',
        paymentStatus: m['payment_status'] ?? 'free',
        pdfUrl: m['pdf_url'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'template': template,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'location': location,
        'linkedin': linkedin,
        'github': github,
        'website': website,
        'job_title': jobTitle,
        'summary': summary,
        'experience': experience.map((e) => e.toMap()).toList(),
        'education': education.map((e) => e.toMap()).toList(),
        'skills': skills,
        'projects': projects.map((e) => e.toMap()).toList(),
        'certifications': certifications.map((e) => e.toMap()).toList(),
        'languages': languages,
        'is_pro': isPro,
        'package': package,
        'payment_status': paymentStatus,
        'pdf_url': pdfUrl,
      };
}

class ExperienceItem {
  String role;
  String company;
  String start;
  String end;
  String description;

  ExperienceItem({
    this.role = '',
    this.company = '',
    this.start = '',
    this.end = '',
    this.description = '',
  });

  factory ExperienceItem.fromMap(Map<String, dynamic> m) => ExperienceItem(
        role: m['role'] ?? '',
        company: m['company'] ?? '',
        start: m['start'] ?? '',
        end: m['end'] ?? '',
        description: m['description'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'role': role,
        'company': company,
        'start': start,
        'end': end,
        'description': description,
      };
}

class EducationItem {
  String degree;
  String school;
  String year;
  String description;

  EducationItem({
    this.degree = '',
    this.school = '',
    this.year = '',
    this.description = '',
  });

  factory EducationItem.fromMap(Map<String, dynamic> m) => EducationItem(
        degree: m['degree'] ?? '',
        school: m['school'] ?? '',
        year: m['year'] ?? '',
        description: m['description'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'degree': degree,
        'school': school,
        'year': year,
        'description': description,
      };
}

class ProjectItem {
  String name;
  String description;
  String link;

  ProjectItem({this.name = '', this.description = '', this.link = ''});

  factory ProjectItem.fromMap(Map<String, dynamic> m) => ProjectItem(
        name: m['name'] ?? '',
        description: m['description'] ?? '',
        link: m['link'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'link': link,
      };
}

class CertificationItem {
  String name;
  String issuer;
  String year;

  CertificationItem({this.name = '', this.issuer = '', this.year = ''});

  factory CertificationItem.fromMap(Map<String, dynamic> m) => CertificationItem(
        name: m['name'] ?? '',
        issuer: m['issuer'] ?? '',
        year: m['year'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'issuer': issuer,
        'year': year,
      };
}