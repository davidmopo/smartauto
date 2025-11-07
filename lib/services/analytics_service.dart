import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics_metric.dart';
import '../models/email_event.dart';
import '../models/campaign.dart';

/// Custom exception for analytics service errors
class AnalyticsServiceException implements Exception {
  final String message;
  AnalyticsServiceException(this.message);

  @override
  String toString() => message;
}

/// Service for analytics and reporting
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _metricsCollection =>
      _firestore.collection('analytics_metrics');
  CollectionReference get _eventsCollection =>
      _firestore.collection('email_events');
  CollectionReference get _campaignsCollection =>
      _firestore.collection('campaigns');
  CollectionReference get _recipientsCollection =>
      _firestore.collection('campaign_recipients');
  CollectionReference get _contactsCollection =>
      _firestore.collection('contacts');

  /// Get analytics summary for a user
  Future<AnalyticsSummary> getAnalyticsSummary(
    String userId, {
    AnalyticsPeriod period = AnalyticsPeriod.last30Days,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final dateRange = period == AnalyticsPeriod.custom && startDate != null && endDate != null
          ? DateTimeRange(start: startDate, end: endDate)
          : period.getDateRange();

      // Get campaigns count
      final campaignsQuery = await _campaignsCollection
          .where('user_id', isEqualTo: userId)
          .where('created_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
          .where('created_at',
              isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
          .get();

      final totalCampaigns = campaignsQuery.docs.length;
      final activeCampaigns = campaignsQuery.docs
          .where((doc) {
            final campaign = Campaign.fromFirestore(doc);
            return campaign.isActive;
          })
          .length;

      // Get contacts count
      final contactsQuery = await _contactsCollection
          .where('user_id', isEqualTo: userId)
          .get();
      final totalContacts = contactsQuery.docs.length;

      // Get metrics for the period
      final metricsQuery = await _metricsCollection
          .where('user_id', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
          .get();

      int totalEmailsSent = 0;
      int totalEmailsDelivered = 0;
      int totalEmailsOpened = 0;
      int totalEmailsClicked = 0;
      int totalEmailsReplied = 0;
      int totalEmailsBounced = 0;
      int totalEmailsUnsubscribed = 0;
      double totalRevenue = 0.0;

      for (var doc in metricsQuery.docs) {
        final metric = AnalyticsMetric.fromFirestore(doc);
        totalEmailsSent += metric.emailsSent;
        totalEmailsDelivered += metric.emailsDelivered;
        totalEmailsOpened += metric.emailsOpened;
        totalEmailsClicked += metric.emailsClicked;
        totalEmailsReplied += metric.emailsReplied;
        totalEmailsBounced += metric.emailsBounced;
        totalEmailsUnsubscribed += metric.emailsUnsubscribed;
        totalRevenue += metric.revenue;
      }

      return AnalyticsSummary(
        totalCampaigns: totalCampaigns,
        activeCampaigns: activeCampaigns,
        totalContacts: totalContacts,
        totalEmailsSent: totalEmailsSent,
        totalEmailsDelivered: totalEmailsDelivered,
        totalEmailsOpened: totalEmailsOpened,
        totalEmailsClicked: totalEmailsClicked,
        totalEmailsReplied: totalEmailsReplied,
        totalEmailsBounced: totalEmailsBounced,
        totalEmailsUnsubscribed: totalEmailsUnsubscribed,
        totalRevenue: totalRevenue,
      );
    } catch (e) {
      throw AnalyticsServiceException('Failed to get analytics summary: $e');
    }
  }

  /// Get metrics for a specific period
  Future<List<AnalyticsMetric>> getMetrics(
    String userId, {
    String? campaignId,
    AnalyticsPeriod period = AnalyticsPeriod.last30Days,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final dateRange = period == AnalyticsPeriod.custom && startDate != null && endDate != null
          ? DateTimeRange(start: startDate, end: endDate)
          : period.getDateRange();

      Query query = _metricsCollection
          .where('user_id', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
          .orderBy('date', descending: true);

      if (campaignId != null) {
        query = query.where('campaign_id', isEqualTo: campaignId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AnalyticsMetric.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw AnalyticsServiceException('Failed to get metrics: $e');
    }
  }

  /// Create or update daily metric
  Future<void> updateDailyMetric(
    String userId, {
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
  }) async {
    try {
      final metricDate = date ?? DateTime.now();
      final dateOnly = DateTime(metricDate.year, metricDate.month, metricDate.day);

      // Find existing metric for this date and campaign
      Query query = _metricsCollection
          .where('user_id', isEqualTo: userId)
          .where('date', isEqualTo: Timestamp.fromDate(dateOnly));

      if (campaignId != null) {
        query = query.where('campaign_id', isEqualTo: campaignId);
      } else {
        query = query.where('campaign_id', isNull: true);
      }

      final snapshot = await query.limit(1).get();

      final now = DateTime.now();

      if (snapshot.docs.isNotEmpty) {
        // Update existing metric
        final doc = snapshot.docs.first;
        final existingMetric = AnalyticsMetric.fromFirestore(doc);

        final updatedMetric = existingMetric.copyWith(
          emailsSent: emailsSent != null
              ? existingMetric.emailsSent + emailsSent
              : existingMetric.emailsSent,
          emailsDelivered: emailsDelivered != null
              ? existingMetric.emailsDelivered + emailsDelivered
              : existingMetric.emailsDelivered,
          emailsOpened: emailsOpened != null
              ? existingMetric.emailsOpened + emailsOpened
              : existingMetric.emailsOpened,
          emailsClicked: emailsClicked != null
              ? existingMetric.emailsClicked + emailsClicked
              : existingMetric.emailsClicked,
          emailsReplied: emailsReplied != null
              ? existingMetric.emailsReplied + emailsReplied
              : existingMetric.emailsReplied,
          emailsBounced: emailsBounced != null
              ? existingMetric.emailsBounced + emailsBounced
              : existingMetric.emailsBounced,
          emailsFailed: emailsFailed != null
              ? existingMetric.emailsFailed + emailsFailed
              : existingMetric.emailsFailed,
          emailsUnsubscribed: emailsUnsubscribed != null
              ? existingMetric.emailsUnsubscribed + emailsUnsubscribed
              : existingMetric.emailsUnsubscribed,
          revenue: revenue != null
              ? existingMetric.revenue + revenue
              : existingMetric.revenue,
          updatedAt: now,
        );

        await doc.reference.update(updatedMetric.toFirestore());
      } else {
        // Create new metric
        final newMetric = AnalyticsMetric(
          id: '',
          userId: userId,
          campaignId: campaignId,
          date: dateOnly,
          emailsSent: emailsSent ?? 0,
          emailsDelivered: emailsDelivered ?? 0,
          emailsOpened: emailsOpened ?? 0,
          emailsClicked: emailsClicked ?? 0,
          emailsReplied: emailsReplied ?? 0,
          emailsBounced: emailsBounced ?? 0,
          emailsFailed: emailsFailed ?? 0,
          emailsUnsubscribed: emailsUnsubscribed ?? 0,
          revenue: revenue ?? 0.0,
          createdAt: now,
          updatedAt: now,
        );

        await _metricsCollection.add(newMetric.toFirestore());
      }
    } catch (e) {
      throw AnalyticsServiceException('Failed to update daily metric: $e');
    }
  }

  /// Log email event
  Future<void> logEmailEvent(EmailEvent event) async {
    try {
      await _eventsCollection.add(event.toFirestore());

      // Update daily metrics based on event type
      switch (event.eventType) {
        case EmailEventType.sent:
          await updateDailyMetric(
            event.userId,
            campaignId: event.campaignId,
            date: event.timestamp,
            emailsSent: 1,
          );
          break;
        case EmailEventType.delivered:
          await updateDailyMetric(
            event.userId,
            campaignId: event.campaignId,
            date: event.timestamp,
            emailsDelivered: 1,
          );
          break;
        case EmailEventType.opened:
          await updateDailyMetric(
            event.userId,
            campaignId: event.campaignId,
            date: event.timestamp,
            emailsOpened: 1,
          );
          break;
        case EmailEventType.clicked:
          await updateDailyMetric(
            event.userId,
            campaignId: event.campaignId,
            date: event.timestamp,
            emailsClicked: 1,
          );
          break;
        case EmailEventType.replied:
          await updateDailyMetric(
            event.userId,
            campaignId: event.campaignId,
            date: event.timestamp,
            emailsReplied: 1,
          );
          break;
        case EmailEventType.bounced:
          await updateDailyMetric(
            event.userId,
            campaignId: event.campaignId,
            date: event.timestamp,
            emailsBounced: 1,
          );
          break;
        case EmailEventType.failed:
          await updateDailyMetric(
            event.userId,
            campaignId: event.campaignId,
            date: event.timestamp,
            emailsFailed: 1,
          );
          break;
        case EmailEventType.unsubscribed:
          await updateDailyMetric(
            event.userId,
            campaignId: event.campaignId,
            date: event.timestamp,
            emailsUnsubscribed: 1,
          );
          break;
        case EmailEventType.complained:
          // Handle spam complaints
          break;
      }
    } catch (e) {
      throw AnalyticsServiceException('Failed to log email event: $e');
    }
  }

  /// Get email events for a campaign
  Future<List<EmailEvent>> getEmailEvents(
    String campaignId, {
    EmailEventType? eventType,
    int? limit,
  }) async {
    try {
      Query query = _eventsCollection
          .where('campaign_id', isEqualTo: campaignId)
          .orderBy('timestamp', descending: true);

      if (eventType != null) {
        query = query.where('event_type', isEqualTo: eventType.name);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => EmailEvent.fromFirestore(doc)).toList();
    } catch (e) {
      throw AnalyticsServiceException('Failed to get email events: $e');
    }
  }

  /// Get event statistics for a campaign
  Future<EmailEventStats> getEventStats(String campaignId) async {
    try {
      final events = await getEmailEvents(campaignId);

      int sentEvents = 0;
      int deliveredEvents = 0;
      int openedEvents = 0;
      int clickedEvents = 0;
      int repliedEvents = 0;
      int bouncedEvents = 0;
      int failedEvents = 0;
      int unsubscribedEvents = 0;
      int complainedEvents = 0;

      for (var event in events) {
        switch (event.eventType) {
          case EmailEventType.sent:
            sentEvents++;
            break;
          case EmailEventType.delivered:
            deliveredEvents++;
            break;
          case EmailEventType.opened:
            openedEvents++;
            break;
          case EmailEventType.clicked:
            clickedEvents++;
            break;
          case EmailEventType.replied:
            repliedEvents++;
            break;
          case EmailEventType.bounced:
            bouncedEvents++;
            break;
          case EmailEventType.failed:
            failedEvents++;
            break;
          case EmailEventType.unsubscribed:
            unsubscribedEvents++;
            break;
          case EmailEventType.complained:
            complainedEvents++;
            break;
        }
      }

      return EmailEventStats(
        totalEvents: events.length,
        sentEvents: sentEvents,
        deliveredEvents: deliveredEvents,
        openedEvents: openedEvents,
        clickedEvents: clickedEvents,
        repliedEvents: repliedEvents,
        bouncedEvents: bouncedEvents,
        failedEvents: failedEvents,
        unsubscribedEvents: unsubscribedEvents,
        complainedEvents: complainedEvents,
      );
    } catch (e) {
      throw AnalyticsServiceException('Failed to get event stats: $e');
    }
  }
}

