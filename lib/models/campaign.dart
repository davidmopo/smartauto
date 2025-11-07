import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Campaign status enum
enum CampaignStatus {
  draft,
  scheduled,
  sending,
  paused,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case CampaignStatus.draft:
        return 'Draft';
      case CampaignStatus.scheduled:
        return 'Scheduled';
      case CampaignStatus.sending:
        return 'Sending';
      case CampaignStatus.paused:
        return 'Paused';
      case CampaignStatus.completed:
        return 'Completed';
      case CampaignStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Campaign type enum
enum CampaignType {
  oneTime,
  drip,
  followUp;

  String get displayName {
    switch (this) {
      case CampaignType.oneTime:
        return 'One-Time';
      case CampaignType.drip:
        return 'Drip Sequence';
      case CampaignType.followUp:
        return 'Follow-Up';
    }
  }
}

/// Email campaign model
class Campaign extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final CampaignType type;
  final CampaignStatus status;

  // Template and content
  final String templateId;
  final String? customSubject; // Override template subject
  final String? customBody; // Override template body

  // Recipients
  final List<String> contactIds;
  final List<String> contactListIds;
  final int totalRecipients;

  // Scheduling
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Drip sequence settings
  final List<DripStep>? dripSteps;
  final int? dripDelayDays; // Days between emails

  // Sending settings
  final int? dailyLimit; // Max emails per day
  final int? hourlyLimit; // Max emails per hour
  final bool trackOpens;
  final bool trackClicks;
  final bool trackReplies;

  // Performance metrics
  final int sentCount;
  final int deliveredCount;
  final int openedCount;
  final int clickedCount;
  final int repliedCount;
  final int bouncedCount;
  final int unsubscribedCount;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const Campaign({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.type,
    required this.status,
    required this.templateId,
    this.customSubject,
    this.customBody,
    required this.contactIds,
    required this.contactListIds,
    required this.totalRecipients,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.dripSteps,
    this.dripDelayDays,
    this.dailyLimit,
    this.hourlyLimit,
    this.trackOpens = true,
    this.trackClicks = true,
    this.trackReplies = true,
    this.sentCount = 0,
    this.deliveredCount = 0,
    this.openedCount = 0,
    this.clickedCount = 0,
    this.repliedCount = 0,
    this.bouncedCount = 0,
    this.unsubscribedCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        type,
        status,
        templateId,
        customSubject,
        customBody,
        contactIds,
        contactListIds,
        totalRecipients,
        scheduledAt,
        startedAt,
        completedAt,
        dripSteps,
        dripDelayDays,
        dailyLimit,
        hourlyLimit,
        trackOpens,
        trackClicks,
        trackReplies,
        sentCount,
        deliveredCount,
        openedCount,
        clickedCount,
        repliedCount,
        bouncedCount,
        unsubscribedCount,
        createdAt,
        updatedAt,
      ];

  /// Calculate open rate percentage
  double get openRate {
    if (deliveredCount == 0) return 0.0;
    return (openedCount / deliveredCount) * 100;
  }

  /// Calculate click rate percentage
  double get clickRate {
    if (deliveredCount == 0) return 0.0;
    return (clickedCount / deliveredCount) * 100;
  }

  /// Calculate reply rate percentage
  double get replyRate {
    if (deliveredCount == 0) return 0.0;
    return (repliedCount / deliveredCount) * 100;
  }

  /// Calculate bounce rate percentage
  double get bounceRate {
    if (sentCount == 0) return 0.0;
    return (bouncedCount / sentCount) * 100;
  }

  /// Calculate delivery rate percentage
  double get deliveryRate {
    if (sentCount == 0) return 0.0;
    return (deliveredCount / sentCount) * 100;
  }

  /// Check if campaign is active
  bool get isActive {
    return status == CampaignStatus.sending || status == CampaignStatus.scheduled;
  }

  /// Check if campaign can be edited
  bool get canEdit {
    return status == CampaignStatus.draft || status == CampaignStatus.scheduled;
  }

  /// Check if campaign can be started
  bool get canStart {
    return status == CampaignStatus.draft || status == CampaignStatus.paused;
  }

  /// Check if campaign can be paused
  bool get canPause {
    return status == CampaignStatus.sending;
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'description': description,
      'type': type.name,
      'status': status.name,
      'template_id': templateId,
      'custom_subject': customSubject,
      'custom_body': customBody,
      'contact_ids': contactIds,
      'contact_list_ids': contactListIds,
      'total_recipients': totalRecipients,
      'scheduled_at': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'started_at': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completed_at': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'drip_steps': dripSteps?.map((s) => s.toMap()).toList(),
      'drip_delay_days': dripDelayDays,
      'daily_limit': dailyLimit,
      'hourly_limit': hourlyLimit,
      'track_opens': trackOpens,
      'track_clicks': trackClicks,
      'track_replies': trackReplies,
      'sent_count': sentCount,
      'delivered_count': deliveredCount,
      'opened_count': openedCount,
      'clicked_count': clickedCount,
      'replied_count': repliedCount,
      'bounced_count': bouncedCount,
      'unsubscribed_count': unsubscribedCount,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore document
  factory Campaign.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Campaign(
      id: doc.id,
      userId: data['user_id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      type: CampaignType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => CampaignType.oneTime,
      ),
      status: CampaignStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CampaignStatus.draft,
      ),
      templateId: data['template_id'] ?? '',
      customSubject: data['custom_subject'],
      customBody: data['custom_body'],
      contactIds: List<String>.from(data['contact_ids'] ?? []),
      contactListIds: List<String>.from(data['contact_list_ids'] ?? []),
      totalRecipients: data['total_recipients'] ?? 0,
      scheduledAt: data['scheduled_at'] != null
          ? (data['scheduled_at'] as Timestamp).toDate()
          : null,
      startedAt: data['started_at'] != null
          ? (data['started_at'] as Timestamp).toDate()
          : null,
      completedAt: data['completed_at'] != null
          ? (data['completed_at'] as Timestamp).toDate()
          : null,
      dripSteps: data['drip_steps'] != null
          ? (data['drip_steps'] as List).map((s) => DripStep.fromMap(s)).toList()
          : null,
      dripDelayDays: data['drip_delay_days'],
      dailyLimit: data['daily_limit'],
      hourlyLimit: data['hourly_limit'],
      trackOpens: data['track_opens'] ?? true,
      trackClicks: data['track_clicks'] ?? true,
      trackReplies: data['track_replies'] ?? true,
      sentCount: data['sent_count'] ?? 0,
      deliveredCount: data['delivered_count'] ?? 0,
      openedCount: data['opened_count'] ?? 0,
      clickedCount: data['clicked_count'] ?? 0,
      repliedCount: data['replied_count'] ?? 0,
      bouncedCount: data['bounced_count'] ?? 0,
      unsubscribedCount: data['unsubscribed_count'] ?? 0,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Create a copy with updated fields
  Campaign copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    CampaignType? type,
    CampaignStatus? status,
    String? templateId,
    String? customSubject,
    String? customBody,
    List<String>? contactIds,
    List<String>? contactListIds,
    int? totalRecipients,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<DripStep>? dripSteps,
    int? dripDelayDays,
    int? dailyLimit,
    int? hourlyLimit,
    bool? trackOpens,
    bool? trackClicks,
    bool? trackReplies,
    int? sentCount,
    int? deliveredCount,
    int? openedCount,
    int? clickedCount,
    int? repliedCount,
    int? bouncedCount,
    int? unsubscribedCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Campaign(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      templateId: templateId ?? this.templateId,
      customSubject: customSubject ?? this.customSubject,
      customBody: customBody ?? this.customBody,
      contactIds: contactIds ?? this.contactIds,
      contactListIds: contactListIds ?? this.contactListIds,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      dripSteps: dripSteps ?? this.dripSteps,
      dripDelayDays: dripDelayDays ?? this.dripDelayDays,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      hourlyLimit: hourlyLimit ?? this.hourlyLimit,
      trackOpens: trackOpens ?? this.trackOpens,
      trackClicks: trackClicks ?? this.trackClicks,
      trackReplies: trackReplies ?? this.trackReplies,
      sentCount: sentCount ?? this.sentCount,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      openedCount: openedCount ?? this.openedCount,
      clickedCount: clickedCount ?? this.clickedCount,
      repliedCount: repliedCount ?? this.repliedCount,
      bouncedCount: bouncedCount ?? this.bouncedCount,
      unsubscribedCount: unsubscribedCount ?? this.unsubscribedCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Drip sequence step model
class DripStep extends Equatable {
  final int stepNumber;
  final String templateId;
  final int delayDays; // Days after previous step
  final String? customSubject;
  final String? customBody;

  const DripStep({
    required this.stepNumber,
    required this.templateId,
    required this.delayDays,
    this.customSubject,
    this.customBody,
  });

  @override
  List<Object?> get props => [
        stepNumber,
        templateId,
        delayDays,
        customSubject,
        customBody,
      ];

  Map<String, dynamic> toMap() {
    return {
      'step_number': stepNumber,
      'template_id': templateId,
      'delay_days': delayDays,
      'custom_subject': customSubject,
      'custom_body': customBody,
    };
  }

  factory DripStep.fromMap(Map<String, dynamic> map) {
    return DripStep(
      stepNumber: map['step_number'] ?? 0,
      templateId: map['template_id'] ?? '',
      delayDays: map['delay_days'] ?? 0,
      customSubject: map['custom_subject'],
      customBody: map['custom_body'],
    );
  }
}

