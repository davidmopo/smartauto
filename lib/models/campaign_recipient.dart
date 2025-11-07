import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Email send status enum
enum EmailStatus {
  pending,
  queued,
  sending,
  sent,
  delivered,
  opened,
  clicked,
  replied,
  bounced,
  failed,
  unsubscribed;

  String get displayName {
    switch (this) {
      case EmailStatus.pending:
        return 'Pending';
      case EmailStatus.queued:
        return 'Queued';
      case EmailStatus.sending:
        return 'Sending';
      case EmailStatus.sent:
        return 'Sent';
      case EmailStatus.delivered:
        return 'Delivered';
      case EmailStatus.opened:
        return 'Opened';
      case EmailStatus.clicked:
        return 'Clicked';
      case EmailStatus.replied:
        return 'Replied';
      case EmailStatus.bounced:
        return 'Bounced';
      case EmailStatus.failed:
        return 'Failed';
      case EmailStatus.unsubscribed:
        return 'Unsubscribed';
    }
  }
}

/// Campaign recipient model - tracks individual email sends
class CampaignRecipient extends Equatable {
  final String id;
  final String campaignId;
  final String userId;
  final String contactId;

  // Contact info (denormalized for performance)
  final String email;
  final String? firstName;
  final String? lastName;
  final String? company;

  // Email details
  final String subject;
  final String body;
  final int stepNumber; // For drip campaigns (0 for one-time)

  // Status and tracking
  final EmailStatus status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? openedAt;
  final DateTime? clickedAt;
  final DateTime? repliedAt;
  final DateTime? bouncedAt;
  final DateTime? unsubscribedAt;

  // Tracking details
  final int openCount;
  final int clickCount;
  final String? bounceReason;
  final String? errorMessage;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const CampaignRecipient({
    required this.id,
    required this.campaignId,
    required this.userId,
    required this.contactId,
    required this.email,
    this.firstName,
    this.lastName,
    this.company,
    required this.subject,
    required this.body,
    this.stepNumber = 0,
    required this.status,
    this.scheduledAt,
    this.sentAt,
    this.deliveredAt,
    this.openedAt,
    this.clickedAt,
    this.repliedAt,
    this.bouncedAt,
    this.unsubscribedAt,
    this.openCount = 0,
    this.clickCount = 0,
    this.bounceReason,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        campaignId,
        userId,
        contactId,
        email,
        firstName,
        lastName,
        company,
        subject,
        body,
        stepNumber,
        status,
        scheduledAt,
        sentAt,
        deliveredAt,
        openedAt,
        clickedAt,
        repliedAt,
        bouncedAt,
        unsubscribedAt,
        openCount,
        clickCount,
        bounceReason,
        errorMessage,
        createdAt,
        updatedAt,
      ];

  /// Get contact full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return email;
  }

  /// Check if email was opened
  bool get wasOpened => openedAt != null;

  /// Check if email was clicked
  bool get wasClicked => clickedAt != null;

  /// Check if email was replied to
  bool get wasReplied => repliedAt != null;

  /// Check if email bounced
  bool get wasBounced => bouncedAt != null;

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'campaign_id': campaignId,
      'user_id': userId,
      'contact_id': contactId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'company': company,
      'subject': subject,
      'body': body,
      'step_number': stepNumber,
      'status': status.name,
      'scheduled_at': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'sent_at': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'delivered_at': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'opened_at': openedAt != null ? Timestamp.fromDate(openedAt!) : null,
      'clicked_at': clickedAt != null ? Timestamp.fromDate(clickedAt!) : null,
      'replied_at': repliedAt != null ? Timestamp.fromDate(repliedAt!) : null,
      'bounced_at': bouncedAt != null ? Timestamp.fromDate(bouncedAt!) : null,
      'unsubscribed_at': unsubscribedAt != null ? Timestamp.fromDate(unsubscribedAt!) : null,
      'open_count': openCount,
      'click_count': clickCount,
      'bounce_reason': bounceReason,
      'error_message': errorMessage,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore document
  factory CampaignRecipient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CampaignRecipient(
      id: doc.id,
      campaignId: data['campaign_id'] ?? '',
      userId: data['user_id'] ?? '',
      contactId: data['contact_id'] ?? '',
      email: data['email'] ?? '',
      firstName: data['first_name'],
      lastName: data['last_name'],
      company: data['company'],
      subject: data['subject'] ?? '',
      body: data['body'] ?? '',
      stepNumber: data['step_number'] ?? 0,
      status: EmailStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => EmailStatus.pending,
      ),
      scheduledAt: data['scheduled_at'] != null
          ? (data['scheduled_at'] as Timestamp).toDate()
          : null,
      sentAt: data['sent_at'] != null ? (data['sent_at'] as Timestamp).toDate() : null,
      deliveredAt: data['delivered_at'] != null
          ? (data['delivered_at'] as Timestamp).toDate()
          : null,
      openedAt: data['opened_at'] != null
          ? (data['opened_at'] as Timestamp).toDate()
          : null,
      clickedAt: data['clicked_at'] != null
          ? (data['clicked_at'] as Timestamp).toDate()
          : null,
      repliedAt: data['replied_at'] != null
          ? (data['replied_at'] as Timestamp).toDate()
          : null,
      bouncedAt: data['bounced_at'] != null
          ? (data['bounced_at'] as Timestamp).toDate()
          : null,
      unsubscribedAt: data['unsubscribed_at'] != null
          ? (data['unsubscribed_at'] as Timestamp).toDate()
          : null,
      openCount: data['open_count'] ?? 0,
      clickCount: data['click_count'] ?? 0,
      bounceReason: data['bounce_reason'],
      errorMessage: data['error_message'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Create a copy with updated fields
  CampaignRecipient copyWith({
    String? id,
    String? campaignId,
    String? userId,
    String? contactId,
    String? email,
    String? firstName,
    String? lastName,
    String? company,
    String? subject,
    String? body,
    int? stepNumber,
    EmailStatus? status,
    DateTime? scheduledAt,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? openedAt,
    DateTime? clickedAt,
    DateTime? repliedAt,
    DateTime? bouncedAt,
    DateTime? unsubscribedAt,
    int? openCount,
    int? clickCount,
    String? bounceReason,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampaignRecipient(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      userId: userId ?? this.userId,
      contactId: contactId ?? this.contactId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      company: company ?? this.company,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      stepNumber: stepNumber ?? this.stepNumber,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      openedAt: openedAt ?? this.openedAt,
      clickedAt: clickedAt ?? this.clickedAt,
      repliedAt: repliedAt ?? this.repliedAt,
      bouncedAt: bouncedAt ?? this.bouncedAt,
      unsubscribedAt: unsubscribedAt ?? this.unsubscribedAt,
      openCount: openCount ?? this.openCount,
      clickCount: clickCount ?? this.clickCount,
      bounceReason: bounceReason ?? this.bounceReason,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

