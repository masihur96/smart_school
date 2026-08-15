class AcademicBook {
  final String id;
  final String title;
  final String description;
  final String classId;
  final String className;

  // Legacy fields (admin/academic-books)
  final String subjectId;
  final String subjectName;

  // New /academic-ebooks fields
  final String author;
  final String subject; // subject name string (used in new API)
  final String coverImageUrl;
  final String pdfUrl;
  final int totalPages;
  final int publishedYear;
  final bool isActive;

  final String uploadedBy;
  final String schoolId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AcademicBook({
    required this.id,
    required this.title,
    this.description = '',
    required this.classId,
    this.className = '',
    this.subjectId = '',
    this.subjectName = '',
    this.author = '',
    this.subject = '',
    this.coverImageUrl = '',
    required this.pdfUrl,
    this.totalPages = 0,
    this.publishedYear = 0,
    this.isActive = true,
    this.uploadedBy = '',
    this.schoolId = '',
    required this.createdAt,
    this.updatedAt,
  });

  factory AcademicBook.fromJson(Map<String, dynamic> json) => AcademicBook(
        id: json['uuid'] ?? json['id'] ?? json['_id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        classId: (json['class'] is Map
                ? (json['class']['uuid'] ?? json['class']['id'])
                : null) ??
            json['classId'] ??
            '',
        className: (json['class'] is Map ? json['class']['name'] : null) ??
            json['className'] ??
            '',
        subjectId: (json['subjectObj'] is Map
                ? (json['subjectObj']['uuid'] ?? json['subjectObj']['id'])
                : null) ??
            json['subjectId'] ??
            '',
        subjectName:
            (json['subjectObj'] is Map ? json['subjectObj']['name'] : null) ??
                json['subjectName'] ??
                '',
        author: json['author'] ?? '',
        subject: json['subject'] ?? '',
        coverImageUrl: json['coverImageUrl'] ?? '',
        pdfUrl: json['pdfUrl'] ?? json['fileUrl'] ?? json['url'] ?? '',
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
        publishedYear: (json['publishedYear'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] ?? true,
        uploadedBy: json['uploadedBy'] ?? '',
        schoolId: json['schoolId'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'classId': classId,
        'className': className,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'author': author,
        'subject': subject,
        'coverImageUrl': coverImageUrl,
        'pdfUrl': pdfUrl,
        'totalPages': totalPages,
        'publishedYear': publishedYear,
        'isActive': isActive,
        'uploadedBy': uploadedBy,
        'schoolId': schoolId,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  AcademicBook copyWith({
    String? id,
    String? title,
    String? description,
    String? classId,
    String? className,
    String? subjectId,
    String? subjectName,
    String? author,
    String? subject,
    String? coverImageUrl,
    String? pdfUrl,
    int? totalPages,
    int? publishedYear,
    bool? isActive,
    String? uploadedBy,
    String? schoolId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AcademicBook(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        classId: classId ?? this.classId,
        className: className ?? this.className,
        subjectId: subjectId ?? this.subjectId,
        subjectName: subjectName ?? this.subjectName,
        author: author ?? this.author,
        subject: subject ?? this.subject,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        pdfUrl: pdfUrl ?? this.pdfUrl,
        totalPages: totalPages ?? this.totalPages,
        publishedYear: publishedYear ?? this.publishedYear,
        isActive: isActive ?? this.isActive,
        uploadedBy: uploadedBy ?? this.uploadedBy,
        schoolId: schoolId ?? this.schoolId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
