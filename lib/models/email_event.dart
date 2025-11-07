import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Email tracking event types
enum EmailEventType {
  sent,
  delivered,
  opened,
  clicked,
  replied,
  bounced,
  failed,
  unsubscribed,
  complained; // Spam complaint

  String get displayName {
    switch (this) {
      case EmailEventType.sent:
        return 'Sent';
      case EmailEventType.delivered:
        return 'Delivered';
      case EmailEventType.opened:
        return 'Opened';
      case EmailEventType.clicked:
        return 'Clicked';
      case EmailEventType.replied:
        return 'Replied';
      case EmailEventType.bounced:
        return 'Bounced';
      case EmailEventType.failed:
        return 'Failed';
      case EmailEventType.unsubscribed:
        return 'Unsubscribed';
      case EmailEventType.complained:
        return 'Spam Complaint';
    }
  }
}

/// Email tracking event
class EmailEvent extends Equatable {
  final String id;
  final String userId;
  final String campaignId;
  final String recipientId;
  final String email;
  final EmailEventType eventType;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final String? location; // City, Country
  final String? device; // Desktop, Mobile, Tablet
  final String? linkUrl; // For click events
  final String? bounceReason; // For bounce events
  final String? errorMessage; // For failed events
  final Map<String, dynamic>? metadata; // Additional event data
  final DateTime createdAt;

  const EmailEvent({
    required this.id,
    required this.userId,
    required this.campaignId,
    required this.recipientId,
    required this.email,
    required this.eventType,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.location,
    this.device,
    this.linkUrl,
    this.bounceReason,
    this.errorMessage,
    this.metadata,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        campaignId,
        recipientId,
        email,
        eventType,
        timestamp,
        ipAddress,
        userAgent,
        location,
        device,
        linkUrl,
        bounceReason,
        errorMessage,
        metadata,
        createdAt,
      ];

  EmailEvent copyWith({
    String? id,
    String? userId,
    String? campaignId,
    String? recipientId,
    String? email,
    EmailEventType? eventType,
    DateTime? timestamp,
    String? ipAddress,
    String? userAgent,
    String? location,
    String? device,
    String? linkUrl,
    String? bounceReason,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return EmailEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      campaignId: campaignId ?? this.campaignId,
      recipientId: recipientId ?? this.recipientId,
      email: email ?? this.email,
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      location: location ?? this.location,
      device: device ?? this.device,
      linkUrl: linkUrl ?? this.linkUrl,
      bounceReason: bounceReason ?? this.bounceReason,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'campaign_id': campaignId,
      'recipient_id': recipientId,
      'email': email,
      'event_type': eventType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'location': location,
      'device': device,
      'link_url': linkUrl,
      'bounce_reason': bounceReason,
      'error_message': errorMessage,
      'metadata': metadata,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory EmailEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmailEvent(
      id: doc.id,
      userId: data['user_id'] ?? '',
      campaignId: data['campaign_id'] ?? '',
      recipientId: data['recipient_id'] ?? '',
      email: data['email'] ?? '',
      eventType: EmailEventType.values.firstWhere(
        (e) => e.name == data['event_type'],
        orElse: () => EmailEventType.sent,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      ipAddress: data['ip_address'],
      userAgent: data['user_agent'],
      location: data['location'],
      device: data['device'],
      linkUrl: data['link_url'],
      bounceReason: data['bounce_reason'],
      errorMessage: data['error_message'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
}

/// Email event statistics
class EmailEventStats extends Equatable {
  final int totalEvents;
  final int sentEvents;
  final int deliveredEvents;
  final int openedEvents;
  final int clickedEvents;
  final int repliedEvents;
  final int bouncedEvents;
  final int failedEvents;
  final int unsubscribedEvents;
  final int complainedEvents;

  const EmailEventStats({
    this.totalEvents = 0,
    this.sentEvents = 0,
    this.deliveredEvents = 0,
    this.openedEvents = 0,
    this.clickedEvents = 0,
    this.repliedEvents = 0,
    this.bouncedEvents = 0,
    this.failedEvents = 0,
    this.unsubscribedEvents = 0,
    this.complainedEvents = 0,
  });

  @override
  List<Object?> get props => [
        totalEvents,
        sentEvents,
        deliveredEvents,
        openedEvents,
        clickedEvents,
        repliedEvents,
        bouncedEvents,
        failedEvents,
        unsubscribedEvents,
        complainedEvents,
      ];

  EmailEventStats copyWith({
    int? totalEvents,
    int? sentEvents,
    int? deliveredEvents,
    int? openedEvents,
    int? clickedEvents,
    int? repliedEvents,
    int? bouncedEvents,
    int? failedEvents,
    int? unsubscribedEvents,
    int? complainedEvents,
  }) {
    return EmailEventStats(
      totalEvents: totalEvents ?? this.totalEvents,
      sentEvents: sentEvents ?? this.sentEvents,
      deliveredEvents: deliveredEvents ?? this.deliveredEvents,
      openedEvents: openedEvents ?? this.openedEvents,
      clickedEvents: clickedEvents ?? this.clickedEvents,
      repliedEvents: repliedEvents ?? this.repliedEvents,
      bouncedEvents: bouncedEvents ?? this.bouncedEvents,
      failedEvents: failedEvents ?? this.failedEvents,
      unsubscribedEvents: unsubscribedEvents ?? this.unsubscribedEvents,
      complainedEvents: complainedEvents ?? this.complainedEvents,
    );
  }
}

