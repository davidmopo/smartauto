import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Analytics metric for tracking campaign performance over time
class AnalyticsMetric extends Equatable {
  final String id;
  final String userId;
  final String? campaignId; // null for overall metrics
  final DateTime date;
  final int emailsSent;
  final int emailsDelivered;
  final int emailsOpened;
  final int emailsClicked;
  final int emailsReplied;
  final int emailsBounced;
  final int emailsFailed;
  final int emailsUnsubscribed;
  final double revenue; // For future e-commerce integration
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnalyticsMetric({
    required this.id,
    required this.userId,
    this.campaignId,
    required this.date,
    this.emailsSent = 0,
    this.emailsDelivered = 0,
    this.emailsOpened = 0,
    this.emailsClicked = 0,
    this.emailsReplied = 0,
    this.emailsBounced = 0,
    this.emailsFailed = 0,
    this.emailsUnsubscribed = 0,
    this.revenue = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculated metrics
  double get deliveryRate =>
      emailsSent > 0 ? (emailsDelivered / emailsSent) * 100 : 0.0;

  double get openRate =>
      emailsDelivered > 0 ? (emailsOpened / emailsDelivered) * 100 : 0.0;

  double get clickRate =>
      emailsDelivered > 0 ? (emailsClicked / emailsDelivered) * 100 : 0.0;

  double get replyRate =>
      emailsDelivered > 0 ? (emailsReplied / emailsDelivered) * 100 : 0.0;

  double get bounceRate =>
      emailsSent > 0 ? (emailsBounced / emailsSent) * 100 : 0.0;

  double get clickToOpenRate =>
      emailsOpened > 0 ? (emailsClicked / emailsOpened) * 100 : 0.0;

  double get unsubscribeRate =>
      emailsDelivered > 0 ? (emailsUnsubscribed / emailsDelivered) * 100 : 0.0;

  @override
  List<Object?> get props => [
        id,
        userId,
        campaignId,
        date,
        emailsSent,
        emailsDelivered,
        emailsOpened,
        emailsClicked,
        emailsReplied,
        emailsBounced,
        emailsFailed,
        emailsUnsubscribed,
        revenue,
        createdAt,
        updatedAt,
      ];

  AnalyticsMetric copyWith({
    String? id,
    String? userId,
    String? campaignId,
    DateTime? date,
    int? emailsSent,
    int? emailsDelivered,
    int? emailsOpened,
    int? emailsClicked,
    int? emailsReplied,
    int? emailsBounced,
    int? emailsFailed,
    int? emailsUnsubscribed,
    double? revenue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnalyticsMetric(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      campaignId: campaignId ?? this.campaignId,
      date: date ?? this.date,
      emailsSent: emailsSent ?? this.emailsSent,
      emailsDelivered: emailsDelivered ?? this.emailsDelivered,
      emailsOpened: emailsOpened ?? this.emailsOpened,
      emailsClicked: emailsClicked ?? this.emailsClicked,
      emailsReplied: emailsReplied ?? this.emailsReplied,
      emailsBounced: emailsBounced ?? this.emailsBounced,
      emailsFailed: emailsFailed ?? this.emailsFailed,
      emailsUnsubscribed: emailsUnsubscribed ?? this.emailsUnsubscribed,
      revenue: revenue ?? this.revenue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'campaign_id': campaignId,
      'date': Timestamp.fromDate(date),
      'emails_sent': emailsSent,
      'emails_delivered': emailsDelivered,
      'emails_opened': emailsOpened,
      'emails_clicked': emailsClicked,
      'emails_replied': emailsReplied,
      'emails_bounced': emailsBounced,
      'emails_failed': emailsFailed,
      'emails_unsubscribed': emailsUnsubscribed,
      'revenue': revenue,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory AnalyticsMetric.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnalyticsMetric(
      id: doc.id,
      userId: data['user_id'] ?? '',
      campaignId: data['campaign_id'],
      date: (data['date'] as Timestamp).toDate(),
      emailsSent: data['emails_sent'] ?? 0,
      emailsDelivered: data['emails_delivered'] ?? 0,
      emailsOpened: data['emails_opened'] ?? 0,
      emailsClicked: data['emails_clicked'] ?? 0,
      emailsReplied: data['emails_replied'] ?? 0,
      emailsBounced: data['emails_bounced'] ?? 0,
      emailsFailed: data['emails_failed'] ?? 0,
      emailsUnsubscribed: data['emails_unsubscribed'] ?? 0,
      revenue: (data['revenue'] ?? 0.0).toDouble(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }
}

/// Aggregated analytics summary
class AnalyticsSummary extends Equatable {
  final int totalCampaigns;
  final int activeCampaigns;
  final int totalContacts;
  final int totalEmailsSent;
  final int totalEmailsDelivered;
  final int totalEmailsOpened;
  final int totalEmailsClicked;
  final int totalEmailsReplied;
  final int totalEmailsBounced;
  final int totalEmailsUnsubscribed;
  final double totalRevenue;

  const AnalyticsSummary({
    this.totalCampaigns = 0,
    this.activeCampaigns = 0,
    this.totalContacts = 0,
    this.totalEmailsSent = 0,
    this.totalEmailsDelivered = 0,
    this.totalEmailsOpened = 0,
    this.totalEmailsClicked = 0,
    this.totalEmailsReplied = 0,
    this.totalEmailsBounced = 0,
    this.totalEmailsUnsubscribed = 0,
    this.totalRevenue = 0.0,
  });

  // Calculated metrics
  double get averageDeliveryRate => totalEmailsSent > 0
      ? (totalEmailsDelivered / totalEmailsSent) * 100
      : 0.0;

  double get averageOpenRate => totalEmailsDelivered > 0
      ? (totalEmailsOpened / totalEmailsDelivered) * 100
      : 0.0;

  double get averageClickRate => totalEmailsDelivered > 0
      ? (totalEmailsClicked / totalEmailsDelivered) * 100
      : 0.0;

  double get averageReplyRate => totalEmailsDelivered > 0
      ? (totalEmailsReplied / totalEmailsDelivered) * 100
      : 0.0;

  double get averageBounceRate => totalEmailsSent > 0
      ? (totalEmailsBounced / totalEmailsSent) * 100
      : 0.0;

  double get clickToOpenRate => totalEmailsOpened > 0
      ? (totalEmailsClicked / totalEmailsOpened) * 100
      : 0.0;

  @override
  List<Object?> get props => [
        totalCampaigns,
        activeCampaigns,
        totalContacts,
        totalEmailsSent,
        totalEmailsDelivered,
        totalEmailsOpened,
        totalEmailsClicked,
        totalEmailsReplied,
        totalEmailsBounced,
        totalEmailsUnsubscribed,
        totalRevenue,
      ];

  AnalyticsSummary copyWith({
    int? totalCampaigns,
    int? activeCampaigns,
    int? totalContacts,
    int? totalEmailsSent,
    int? totalEmailsDelivered,
    int? totalEmailsOpened,
    int? totalEmailsClicked,
    int? totalEmailsReplied,
    int? totalEmailsBounced,
    int? totalEmailsUnsubscribed,
    double? totalRevenue,
  }) {
    return AnalyticsSummary(
      totalCampaigns: totalCampaigns ?? this.totalCampaigns,
      activeCampaigns: activeCampaigns ?? this.activeCampaigns,
      totalContacts: totalContacts ?? this.totalContacts,
      totalEmailsSent: totalEmailsSent ?? this.totalEmailsSent,
      totalEmailsDelivered: totalEmailsDelivered ?? this.totalEmailsDelivered,
      totalEmailsOpened: totalEmailsOpened ?? this.totalEmailsOpened,
      totalEmailsClicked: totalEmailsClicked ?? this.totalEmailsClicked,
      totalEmailsReplied: totalEmailsReplied ?? this.totalEmailsReplied,
      totalEmailsBounced: totalEmailsBounced ?? this.totalEmailsBounced,
      totalEmailsUnsubscribed:
          totalEmailsUnsubscribed ?? this.totalEmailsUnsubscribed,
      totalRevenue: totalRevenue ?? this.totalRevenue,
    );
  }
}

/// Time period for analytics
enum AnalyticsPeriod {
  today,
  yesterday,
  last7Days,
  last30Days,
  last90Days,
  thisMonth,
  lastMonth,
  thisYear,
  custom;

  String get displayName {
    switch (this) {
      case AnalyticsPeriod.today:
        return 'Today';
      case AnalyticsPeriod.yesterday:
        return 'Yesterday';
      case AnalyticsPeriod.last7Days:
        return 'Last 7 Days';
      case AnalyticsPeriod.last30Days:
        return 'Last 30 Days';
      case AnalyticsPeriod.last90Days:
        return 'Last 90 Days';
      case AnalyticsPeriod.thisMonth:
        return 'This Month';
      case AnalyticsPeriod.lastMonth:
        return 'Last Month';
      case AnalyticsPeriod.thisYear:
        return 'This Year';
      case AnalyticsPeriod.custom:
        return 'Custom Range';
    }
  }

  DateTimeRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case AnalyticsPeriod.today:
        return DateTimeRange(start: today, end: now);
      case AnalyticsPeriod.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: today);
      case AnalyticsPeriod.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: now,
        );
      case AnalyticsPeriod.last30Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: now,
        );
      case AnalyticsPeriod.last90Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 90)),
          end: now,
        );
      case AnalyticsPeriod.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case AnalyticsPeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0);
        return DateTimeRange(start: lastMonth, end: lastMonthEnd);
      case AnalyticsPeriod.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      case AnalyticsPeriod.custom:
        return DateTimeRange(start: today, end: now);
    }
  }
}

/// Date range helper
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}

