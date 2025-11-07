import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a version of an email template
class TemplateVersion {
  final String id;
  final String templateId;
  final String userId;
  final int versionNumber;
  final String name;
  final String subject;
  final String htmlBody;
  final String? plainTextBody;
  final String? description;
  final List<String> variables;
  final List<String> tags;
  final String changeDescription;
  final DateTime createdAt;

  TemplateVersion({
    required this.id,
    required this.templateId,
    required this.userId,
    required this.versionNumber,
    required this.name,
    required this.subject,
    required this.htmlBody,
    this.plainTextBody,
    this.description,
    required this.variables,
    required this.tags,
    required this.changeDescription,
    required this.createdAt,
  });

  factory TemplateVersion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TemplateVersion(
      id: doc.id,
      templateId: data['templateId'] as String,
      userId: data['userId'] as String,
      versionNumber: data['versionNumber'] as int,
      name: data['name'] as String,
      subject: data['subject'] as String,
      htmlBody: data['htmlBody'] as String,
      plainTextBody: data['plainTextBody'] as String?,
      description: data['description'] as String?,
      variables: List<String>.from(data['variables'] as List),
      tags: List<String>.from(data['tags'] as List),
      changeDescription: data['changeDescription'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'templateId': templateId,
      'userId': userId,
      'versionNumber': versionNumber,
      'name': name,
      'subject': subject,
      'htmlBody': htmlBody,
      'plainTextBody': plainTextBody,
      'description': description,
      'variables': variables,
      'tags': tags,
      'changeDescription': changeDescription,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TemplateVersion copyWith({
    String? id,
    String? templateId,
    String? userId,
    int? versionNumber,
    String? name,
    String? subject,
    String? htmlBody,
    String? plainTextBody,
    String? description,
    List<String>? variables,
    List<String>? tags,
    String? changeDescription,
    DateTime? createdAt,
  }) {
    return TemplateVersion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      userId: userId ?? this.userId,
      versionNumber: versionNumber ?? this.versionNumber,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      htmlBody: htmlBody ?? this.htmlBody,
      plainTextBody: plainTextBody ?? this.plainTextBody,
      description: description ?? this.description,
      variables: variables ?? this.variables,
      tags: tags ?? this.tags,
      changeDescription: changeDescription ?? this.changeDescription,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
