class AcademicBook {
  final String id;
  final String title;
  final String description;
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String pdfUrl;
  final String uploadedBy;
  final String schoolId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AcademicBook({
    required this.id,
    required this.title,
    this.description = '',
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.pdfUrl,
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
        subjectId: (json['subject'] is Map
                ? (json['subject']['uuid'] ?? json['subject']['id'])
                : null) ??
            json['subjectId'] ??
            '',
        subjectName:
            (json['subject'] is Map ? json['subject']['name'] : null) ??
                json['subjectName'] ??
                '',
        pdfUrl: json['pdfUrl'] ?? json['fileUrl'] ?? json['url'] ?? '',
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
        'pdfUrl': pdfUrl,
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
    String? pdfUrl,
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
        pdfUrl: pdfUrl ?? this.pdfUrl,
        uploadedBy: uploadedBy ?? this.uploadedBy,
        schoolId: schoolId ?? this.schoolId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
