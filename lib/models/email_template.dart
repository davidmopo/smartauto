import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Email template model for storing reusable email templates
class EmailTemplate extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String subject;
  final String htmlBody;
  final String? plainTextBody;
  final String? description;
  final List<String>
  variables; // List of variables used in template (e.g., ['firstName', 'company'])
  final TemplateCategory category;
  final List<String> tags;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int usageCount; // Number of times template has been used
  final double? averageOpenRate;
  final double? averageClickRate;
  final List<String>? variantIds; // IDs of A/B test variants

  const EmailTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.subject,
    required this.htmlBody,
    this.plainTextBody,
    this.description,
    this.variables = const [],
    this.category = TemplateCategory.general,
    this.tags = const [],
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.usageCount = 0,
    this.averageOpenRate,
    this.averageClickRate,
    this.variantIds,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    subject,
    htmlBody,
    plainTextBody,
    description,
    variables,
    category,
    tags,
    isDefault,
    isActive,
    createdAt,
    updatedAt,
    usageCount,
    averageOpenRate,
    averageClickRate,
    variantIds,
  ];

  /// Create a copy with updated fields
  EmailTemplate copyWith({
    String? id,
    String? userId,
    String? name,
    String? subject,
    String? htmlBody,
    String? plainTextBody,
    String? description,
    List<String>? variables,
    TemplateCategory? category,
    List<String>? tags,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? usageCount,
    double? averageOpenRate,
    double? averageClickRate,
    List<String>? variantIds,
  }) {
    return EmailTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      htmlBody: htmlBody ?? this.htmlBody,
      plainTextBody: plainTextBody ?? this.plainTextBody,
      description: description ?? this.description,
      variables: variables ?? this.variables,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      usageCount: usageCount ?? this.usageCount,
      averageOpenRate: averageOpenRate ?? this.averageOpenRate,
      averageClickRate: averageClickRate ?? this.averageClickRate,
      variantIds: variantIds ?? this.variantIds,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'subject': subject,
      'html_body': htmlBody,
      'plain_text_body': plainTextBody,
      'description': description,
      'variables': variables,
      'category': category.name,
      'tags': tags,
      'is_default': isDefault,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'usage_count': usageCount,
      'average_open_rate': averageOpenRate,
      'average_click_rate': averageClickRate,
      'variant_ids': variantIds,
    };
  }

  /// Create from Firestore document
  factory EmailTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmailTemplate(
      id: doc.id,
      userId: data['user_id'] ?? '',
      name: data['name'] ?? '',
      subject: data['subject'] ?? '',
      htmlBody: data['html_body'] ?? '',
      plainTextBody: data['plain_text_body'],
      description: data['description'],
      variables: List<String>.from(data['variables'] ?? []),
      category: TemplateCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => TemplateCategory.general,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      isDefault: data['is_default'] ?? false,
      isActive: data['is_active'] ?? true,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      usageCount: data['usage_count'] ?? 0,
      averageOpenRate: data['average_open_rate']?.toDouble(),
      averageClickRate: data['average_click_rate']?.toDouble(),
      variantIds: data['variant_ids'] != null
          ? List<String>.from(data['variant_ids'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'subject': subject,
      'html_body': htmlBody,
      'plain_text_body': plainTextBody,
      'description': description,
      'variables': variables,
      'category': category.name,
      'tags': tags,
      'is_default': isDefault,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'usage_count': usageCount,
      'average_open_rate': averageOpenRate,
      'average_click_rate': averageClickRate,
      'variant_ids': variantIds,
    };
  }

  /// Create from JSON
  factory EmailTemplate.fromJson(Map<String, dynamic> json) {
    return EmailTemplate(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      subject: json['subject'] ?? '',
      htmlBody: json['html_body'] ?? '',
      plainTextBody: json['plain_text_body'],
      description: json['description'],
      variables: List<String>.from(json['variables'] ?? []),
      category: TemplateCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TemplateCategory.general,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      isDefault: json['is_default'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      usageCount: json['usage_count'] ?? 0,
      averageOpenRate: json['average_open_rate']?.toDouble(),
      averageClickRate: json['average_click_rate']?.toDouble(),
      variantIds: json['variant_ids'] != null
          ? List<String>.from(json['variant_ids'])
          : null,
    );
  }

  /// Extract variables from template content
  static List<String> extractVariables(String content) {
    final regex = RegExp(r'\{\{(\w+)\}\}');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toSet().toList();
  }

  /// Replace variables in content with actual values
  static String replaceVariables(String content, Map<String, String> values) {
    String result = content;
    values.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }

  /// Get performance score (0-100)
  double get performanceScore {
    if (averageOpenRate == null && averageClickRate == null) return null;
    final openScore = (averageOpenRate ?? 0) * 0.6;
    final clickScore = (averageClickRate ?? 0) * 0.4;
    return (openScore + clickScore) * 100;
  }

  /// Check if template has variants
  bool get hasVariants => variantIds != null && variantIds!.isNotEmpty;
}

/// Template category enum
enum TemplateCategory {
  general,
  coldOutreach,
  followUp,
  introduction,
  meeting,
  proposal,
  newsletter,
  announcement,
  thankyou,
  custom,
}

/// Extension for template category display
extension TemplateCategoryExtension on TemplateCategory {
  String get displayName {
    switch (this) {
      case TemplateCategory.general:
        return 'General';
      case TemplateCategory.coldOutreach:
        return 'Cold Outreach';
      case TemplateCategory.followUp:
        return 'Follow Up';
      case TemplateCategory.introduction:
        return 'Introduction';
      case TemplateCategory.meeting:
        return 'Meeting';
      case TemplateCategory.proposal:
        return 'Proposal';
      case TemplateCategory.newsletter:
        return 'Newsletter';
      case TemplateCategory.announcement:
        return 'Announcement';
      case TemplateCategory.thankyou:
        return 'Thank You';
      case TemplateCategory.custom:
        return 'Custom';
    }
  }
}
