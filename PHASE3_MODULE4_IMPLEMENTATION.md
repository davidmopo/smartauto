# Phase 3: Module 4 - Analytics & Reporting Implementation

## Overview
This document outlines the implementation of the Analytics & Reporting system for tracking campaign performance and generating insights.

## Completed Features

### 1. Analytics Models ✅
**Files:**
- `lib/models/analytics_metric.dart`
- `lib/models/email_event.dart`

**AnalyticsMetric Model Features:**
- Daily metrics tracking per user/campaign
- Email counts (sent, delivered, opened, clicked, replied, bounced, failed, unsubscribed)
- Revenue tracking (for future e-commerce integration)
- Calculated rates (delivery, open, click, reply, bounce, click-to-open, unsubscribe)
- Firestore integration with timestamps

**AnalyticsSummary Model Features:**
- Aggregated metrics across all campaigns
- Total campaigns and active campaigns count
- Total contacts count
- Total email statistics
- Average rates calculation
- Revenue totals

**AnalyticsPeriod Enum:**
- Today
- Yesterday
- Last 7 Days
- Last 30 Days
- Last 90 Days
- This Month
- Last Month
- This Year
- Custom Range

**EmailEvent Model Features:**
- Individual email event tracking
- 9 event types (sent, delivered, opened, clicked, replied, bounced, failed, unsubscribed, complained)
- Detailed tracking data:
  - IP address
  - User agent
  - Location (city, country)
  - Device type (desktop, mobile, tablet)
  - Link URL (for click events)
  - Bounce reason (for bounce events)
  - Error message (for failed events)
  - Custom metadata
- Timestamp tracking

**EmailEventStats Model:**
- Event count aggregation
- Statistics by event type

### 2. Analytics Service ✅
**File:** `lib/services/analytics_service.dart`

**Core Operations:**
- `getAnalyticsSummary()` - Get aggregated analytics for a user
- `getMetrics()` - Get daily metrics for a period
- `updateDailyMetric()` - Create or update daily metric
- `logEmailEvent()` - Log email tracking event
- `getEmailEvents()` - Get events for a campaign
- `getEventStats()` - Get event statistics for a campaign

**Features:**
- Period-based filtering (today, last 7 days, last 30 days, etc.)
- Campaign-specific metrics
- Automatic metric aggregation from events
- Daily metric rollup
- Event logging with automatic metric updates
- Query optimization with Firestore indexes

**Metric Calculations:**
- Delivery Rate = (Delivered / Sent) × 100
- Open Rate = (Opened / Delivered) × 100
- Click Rate = (Clicked / Delivered) × 100
- Reply Rate = (Replied / Delivered) × 100
- Bounce Rate = (Bounced / Sent) × 100
- Click-to-Open Rate = (Clicked / Opened) × 100
- Unsubscribe Rate = (Unsubscribed / Delivered) × 100

### 3. Analytics Dashboard Screen ✅
**File:** `lib/screens/analytics/analytics_screen.dart`

**Features:**
- Period selector (dropdown in app bar)
- Overview summary cards:
  - Total campaigns (with active count)
  - Total contacts
  - Emails sent
  - Delivered (with delivery rate)
  - Open rate (with total opens)
  - Click rate (with total clicks)
- Performance trends chart:
  - Line chart showing open rate and click rate over time
  - Interactive chart with fl_chart package
  - Legend for chart lines
- Detailed metrics breakdown:
  - Reply rate
  - Bounce rate
  - Click-to-open rate
- Empty state for no data
- Loading states
- Error handling

**UI Components:**
- Color-coded metric cards
- Icon-based visual indicators
- Responsive layout
- Material Design styling

### 4. Dashboard Integration ✅
**File:** `lib/screens/dashboard/dashboard_screen.dart`

**Updates:**
- Added navigation to Analytics screen from sidebar
- Added navigation to Analytics screen from drawer
- Integrated analytics into main app flow

## File Structure

```
lib/
├── models/
│   ├── analytics_metric.dart        # Analytics metrics and summary models
│   └── email_event.dart              # Email tracking event models
├── services/
│   └── analytics_service.dart        # Analytics CRUD and aggregation
├── screens/
│   ├── analytics/
│   │   └── analytics_screen.dart     # Analytics dashboard
│   └── dashboard/
│       └── dashboard_screen.dart     # Updated with analytics navigation
└── PHASE3_MODULE4_IMPLEMENTATION.md  # This file
```

## Database Schema

### Firestore Collections

#### `analytics_metrics`
```javascript
{
  user_id: string,
  campaign_id: string | null,  // null for overall metrics
  date: timestamp,              // Date only (no time)
  emails_sent: number,
  emails_delivered: number,
  emails_opened: number,
  emails_clicked: number,
  emails_replied: number,
  emails_bounced: number,
  emails_failed: number,
  emails_unsubscribed: number,
  revenue: number,
  created_at: timestamp,
  updated_at: timestamp
}
```

**Indexes Required:**
- `user_id` + `date` (for user metrics by date)
- `user_id` + `campaign_id` + `date` (for campaign metrics by date)

#### `email_events`
```javascript
{
  user_id: string,
  campaign_id: string,
  recipient_id: string,
  email: string,
  event_type: string,  // sent, delivered, opened, clicked, etc.
  timestamp: timestamp,
  ip_address: string | null,
  user_agent: string | null,
  location: string | null,
  device: string | null,
  link_url: string | null,
  bounce_reason: string | null,
  error_message: string | null,
  metadata: map | null,
  created_at: timestamp
}
```

**Indexes Required:**
- `campaign_id` + `timestamp` (for campaign events)
- `campaign_id` + `event_type` + `timestamp` (for filtered events)
- `recipient_id` + `timestamp` (for recipient events)

## Configuration Required

### Firestore Security Rules
Update your Firestore security rules to allow analytics operations:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Analytics metrics collection
    match /analytics_metrics/{metricId} {
      allow read: if request.auth != null && 
                  request.auth.uid == resource.data.user_id;
      allow write: if request.auth != null && 
                   request.auth.uid == request.resource.data.user_id;
    }
    
    // Email events collection
    match /email_events/{eventId} {
      allow read: if request.auth != null && 
                  request.auth.uid == resource.data.user_id;
      allow write: if request.auth != null && 
                   request.auth.uid == request.resource.data.user_id;
    }
  }
}
```

### Firestore Indexes
Create composite indexes in Firebase Console:

1. **analytics_metrics**
   - Collection: `analytics_metrics`
   - Fields: `user_id` (Ascending), `date` (Descending)

2. **analytics_metrics (campaign)**
   - Collection: `analytics_metrics`
   - Fields: `user_id` (Ascending), `campaign_id` (Ascending), `date` (Descending)

3. **email_events**
   - Collection: `email_events`
   - Fields: `campaign_id` (Ascending), `timestamp` (Descending)

4. **email_events (filtered)**
   - Collection: `email_events`
   - Fields: `campaign_id` (Ascending), `event_type` (Ascending), `timestamp` (Descending)

## Usage Examples

### Logging Email Events

```dart
final analyticsService = AnalyticsService();

// Log email sent event
await analyticsService.logEmailEvent(
  EmailEvent(
    id: '',
    userId: userId,
    campaignId: campaignId,
    recipientId: recipientId,
    email: recipientEmail,
    eventType: EmailEventType.sent,
    timestamp: DateTime.now(),
    createdAt: DateTime.now(),
  ),
);

// Log email opened event with tracking data
await analyticsService.logEmailEvent(
  EmailEvent(
    id: '',
    userId: userId,
    campaignId: campaignId,
    recipientId: recipientId,
    email: recipientEmail,
    eventType: EmailEventType.opened,
    timestamp: DateTime.now(),
    ipAddress: '192.168.1.1',
    userAgent: 'Mozilla/5.0...',
    location: 'New York, USA',
    device: 'Desktop',
    createdAt: DateTime.now(),
  ),
);
```

### Getting Analytics Summary

```dart
final analyticsService = AnalyticsService();

// Get last 30 days summary
final summary = await analyticsService.getAnalyticsSummary(
  userId,
  period: AnalyticsPeriod.last30Days,
);

print('Total campaigns: ${summary.totalCampaigns}');
print('Average open rate: ${summary.averageOpenRate}%');
print('Average click rate: ${summary.averageClickRate}%');
```

### Getting Campaign Metrics

```dart
final analyticsService = AnalyticsService();

// Get metrics for a specific campaign
final metrics = await analyticsService.getMetrics(
  userId,
  campaignId: campaignId,
  period: AnalyticsPeriod.last7Days,
);

for (var metric in metrics) {
  print('Date: ${metric.date}');
  print('Open rate: ${metric.openRate}%');
  print('Click rate: ${metric.clickRate}%');
}
```

## Testing Instructions

### 1. Test Analytics Dashboard
1. Navigate to Analytics screen from dashboard
2. Verify period selector works
3. Check that summary cards display correctly
4. Verify performance chart renders
5. Test detailed metrics section

### 2. Test Event Logging
1. Create a test campaign
2. Log various email events
3. Verify events are stored in Firestore
4. Check that daily metrics are updated
5. Verify analytics dashboard reflects new data

### 3. Test Period Filtering
1. Select different time periods
2. Verify data updates correctly
3. Test edge cases (no data, single day, etc.)

## Known Limitations

1. **Real-time Updates**: Analytics data is not real-time (requires manual refresh)
2. **Export Functionality**: CSV/PDF export not yet implemented
3. **Advanced Charts**: Limited chart types (only line charts currently)
4. **Detailed Reports**: No dedicated reports screen yet
5. **Email Tracking Integration**: Tracking pixels and links not yet implemented in email sending

## Next Steps

### Immediate Improvements
1. Implement real-time analytics with Firestore streams
2. Add more chart types (bar, pie, area charts)
3. Create dedicated reports screen
4. Add CSV/PDF export functionality
5. Implement email tracking pixels and click tracking links
6. Add campaign comparison features
7. Create custom date range picker

### Future Enhancements
1. **Advanced Analytics**
   - Cohort analysis
   - Funnel visualization
   - A/B test results
   - Predictive analytics
   - Engagement scoring

2. **Reporting**
   - Scheduled reports (daily, weekly, monthly)
   - Email report delivery
   - Custom report builder
   - Report templates
   - White-label reports

3. **Visualizations**
   - Heat maps (best send times)
   - Geographic maps (location-based opens)
   - Device breakdown charts
   - Email client analysis
   - Link click maps

4. **Integrations**
   - Google Analytics integration
   - Data export to BI tools
   - Webhook notifications for events
   - API for external analytics tools

5. **Performance**
   - Data aggregation optimization
   - Caching layer for frequently accessed metrics
   - Background metric calculation
   - Incremental metric updates

## Best Practices

### Event Logging
1. **Log All Events**: Track every email interaction
2. **Include Context**: Add IP, user agent, location when available
3. **Batch Logging**: Consider batching events for performance
4. **Error Handling**: Handle logging failures gracefully
5. **Privacy**: Respect user privacy and GDPR requirements

### Metric Calculation
1. **Daily Rollup**: Aggregate metrics daily for performance
2. **Incremental Updates**: Update metrics incrementally, not full recalculation
3. **Cache Results**: Cache frequently accessed metrics
4. **Async Processing**: Calculate metrics asynchronously
5. **Data Retention**: Define data retention policies

### Dashboard Performance
1. **Limit Data**: Don't load all historical data at once
2. **Pagination**: Paginate large result sets
3. **Lazy Loading**: Load charts and data on demand
4. **Debounce**: Debounce period selector changes
5. **Optimize Queries**: Use Firestore indexes effectively

## Conclusion

Phase 3: Module 4 has been successfully implemented with core features:
- ✅ Analytics models (metrics, events, summary)
- ✅ Analytics service with aggregation
- ✅ Analytics dashboard screen
- ✅ Performance charts
- ✅ Email event tracking system (models and service)
- ✅ Dashboard integration
- ⏭️ Real-time analytics (future enhancement)
- ⏭️ Reports screen (future enhancement)
- ⏭️ Export functionality (future enhancement)

The module provides a solid foundation for tracking campaign performance and generating insights. The email tracking system is ready for integration with the email sending service.

**Note**: To see actual analytics data, you need to:
1. Send campaigns (or simulate sending)
2. Log email events using the analytics service
3. Wait for daily metrics to aggregate
4. View analytics in the dashboard

For testing purposes, you can manually create analytics metrics and events in Firestore to populate the dashboard.

