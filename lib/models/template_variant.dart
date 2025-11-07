import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Template variant for A/B testing
class TemplateVariant extends Equatable {
  final String id;
  final String templateId;
  final String userId;
  final String name;
  final String subject;
  final String htmlBody;
  final String? plainTextBody;
  final int weight; // Percentage of recipients to receive this variant (0-100)
  final bool isControl; // Whether this is the control variant
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Performance metrics
  final int sentCount;
  final int openCount;
  final int clickCount;
  final int replyCount;
  final double? openRate;
  final double? clickRate;
  final double? replyRate;

  const TemplateVariant({
    required this.id,
    required this.templateId,
    required this.userId,
    required this.name,
    required this.subject,
    required this.htmlBody,
    this.plainTextBody,
    this.weight = 50,
    this.isControl = false,
    required this.createdAt,
    required this.updatedAt,
    this.sentCount = 0,
    this.openCount = 0,
    this.clickCount = 0,
    this.replyCount = 0,
    this.openRate,
    this.clickRate,
    this.replyRate,
  });

  @override
  List<Object?> get props => [
        id,
        templateId,
        userId,
        name,
        subject,
        htmlBody,
        plainTextBody,
        weight,
        isControl,
        createdAt,
        updatedAt,
        sentCount,
        openCount,
        clickCount,
        replyCount,
        openRate,
        clickRate,
        replyRate,
      ];

  /// Create a copy with updated fields
  TemplateVariant copyWith({
    String? id,
    String? templateId,
    String? userId,
    String? name,
    String? subject,
    String? htmlBody,
    String? plainTextBody,
    int? weight,
    bool? isControl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sentCount,
    int? openCount,
    int? clickCount,
    int? replyCount,
    double? openRate,
    double? clickRate,
    double? replyRate,
  }) {
    return TemplateVariant(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      htmlBody: htmlBody ?? this.htmlBody,
      plainTextBody: plainTextBody ?? this.plainTextBody,
      weight: weight ?? this.weight,
      isControl: isControl ?? this.isControl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sentCount: sentCount ?? this.sentCount,
      openCount: openCount ?? this.openCount,
      clickCount: clickCount ?? this.clickCount,
      replyCount: replyCount ?? this.replyCount,
      openRate: openRate ?? this.openRate,
      clickRate: clickRate ?? this.clickRate,
      replyRate: replyRate ?? this.replyRate,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'template_id': templateId,
      'user_id': userId,
      'name': name,
      'subject': subject,
      'html_body': htmlBody,
      'plain_text_body': plainTextBody,
      'weight': weight,
      'is_control': isControl,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'sent_count': sentCount,
      'open_count': openCount,
      'click_count': clickCount,
      'reply_count': replyCount,
      'open_rate': openRate,
      'click_rate': clickRate,
      'reply_rate': replyRate,
    };
  }

  /// Create from Firestore document
  factory TemplateVariant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TemplateVariant(
      id: doc.id,
      templateId: data['template_id'] ?? '',
      userId: data['user_id'] ?? '',
      name: data['name'] ?? '',
      subject: data['subject'] ?? '',
      htmlBody: data['html_body'] ?? '',
      plainTextBody: data['plain_text_body'],
      weight: data['weight'] ?? 50,
      isControl: data['is_control'] ?? false,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      sentCount: data['sent_count'] ?? 0,
      openCount: data['open_count'] ?? 0,
      clickCount: data['click_count'] ?? 0,
      replyCount: data['reply_count'] ?? 0,
      openRate: data['open_rate']?.toDouble(),
      clickRate: data['click_rate']?.toDouble(),
      replyRate: data['reply_rate']?.toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'user_id': userId,
      'name': name,
      'subject': subject,
      'html_body': htmlBody,
      'plain_text_body': plainTextBody,
      'weight': weight,
      'is_control': isControl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sent_count': sentCount,
      'open_count': openCount,
      'click_count': clickCount,
      'reply_count': replyCount,
      'open_rate': openRate,
      'click_rate': clickRate,
      'reply_rate': replyRate,
    };
  }

  /// Create from JSON
  factory TemplateVariant.fromJson(Map<String, dynamic> json) {
    return TemplateVariant(
      id: json['id'] ?? '',
      templateId: json['template_id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      subject: json['subject'] ?? '',
      htmlBody: json['html_body'] ?? '',
      plainTextBody: json['plain_text_body'],
      weight: json['weight'] ?? 50,
      isControl: json['is_control'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      sentCount: json['sent_count'] ?? 0,
      openCount: json['open_count'] ?? 0,
      clickCount: json['click_count'] ?? 0,
      replyCount: json['reply_count'] ?? 0,
      openRate: json['open_rate']?.toDouble(),
      clickRate: json['click_rate']?.toDouble(),
      replyRate: json['reply_rate']?.toDouble(),
    );
  }

  /// Calculate performance score (0-100)
  double get performanceScore {
    final openScore = (openRate ?? 0) * 0.4;
    final clickScore = (clickRate ?? 0) * 0.3;
    final replyScore = (replyRate ?? 0) * 0.3;
    return (openScore + clickScore + replyScore) * 100;
  }

  /// Check if variant has enough data for statistical significance
  bool get hasSignificantData => sentCount >= 30;

  /// Get winner indicator compared to control
  /// Returns: 1 if winning, -1 if losing, 0 if neutral/not enough data
  int compareToControl(TemplateVariant control) {
    if (!hasSignificantData || !control.hasSignificantData) return 0;
    
    final scoreDiff = performanceScore - control.performanceScore;
    if (scoreDiff > 5) return 1; // Winning by >5%
    if (scoreDiff < -5) return -1; // Losing by >5%
    return 0; // Neutral
  }
}

