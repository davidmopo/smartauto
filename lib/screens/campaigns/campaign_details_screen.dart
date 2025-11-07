import 'package:flutter/material.dart';
import '../../models/campaign.dart';
import '../../models/campaign_recipient.dart';
import '../../services/campaign_service.dart';
import 'package:intl/intl.dart';

/// Screen for viewing campaign details and statistics
class CampaignDetailsScreen extends StatefulWidget {
  final Campaign campaign;

  const CampaignDetailsScreen({super.key, required this.campaign});

  @override
  State<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends State<CampaignDetailsScreen> {
  final CampaignService _campaignService = CampaignService();
  List<CampaignRecipient> _recipients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    setState(() => _isLoading = true);

    try {
      final recipients = await _campaignService.getCampaignRecipients(
        widget.campaign.id,
        limit: 50,
      );

      setState(() => _recipients = recipients);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading recipients: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campaign.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (widget.campaign.canStart)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _startCampaign,
              tooltip: 'Start Campaign',
            ),
          if (widget.campaign.canPause)
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: _pauseCampaign,
              tooltip: 'Pause Campaign',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildMetricsSection(),
            _buildDetailsSection(),
            _buildRecipientsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.blue.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.campaign.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusBadge(widget.campaign.status),
            ],
          ),
          if (widget.campaign.description != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.campaign.description!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(Icons.category, widget.campaign.type.displayName),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.people,
                '${widget.campaign.totalRecipients} recipients',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Sent',
                  widget.campaign.sentCount.toString(),
                  Icons.send,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Delivered',
                  widget.campaign.deliveredCount.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Open Rate',
                  '${widget.campaign.openRate.toStringAsFixed(1)}%',
                  Icons.mark_email_read,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Click Rate',
                  '${widget.campaign.clickRate.toStringAsFixed(1)}%',
                  Icons.touch_app,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Reply Rate',
                  '${widget.campaign.replyRate.toStringAsFixed(1)}%',
                  Icons.reply,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Bounce Rate',
                  '${widget.campaign.bounceRate.toStringAsFixed(1)}%',
                  Icons.error,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campaign Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Created',
            dateFormat.format(widget.campaign.createdAt),
          ),
          if (widget.campaign.scheduledAt != null)
            _buildDetailRow(
              'Scheduled',
              dateFormat.format(widget.campaign.scheduledAt!),
            ),
          if (widget.campaign.startedAt != null)
            _buildDetailRow(
              'Started',
              dateFormat.format(widget.campaign.startedAt!),
            ),
          if (widget.campaign.completedAt != null)
            _buildDetailRow(
              'Completed',
              dateFormat.format(widget.campaign.completedAt!),
            ),
          if (widget.campaign.dailyLimit != null)
            _buildDetailRow(
              'Daily Limit',
              '${widget.campaign.dailyLimit} emails/day',
            ),
          if (widget.campaign.hourlyLimit != null)
            _buildDetailRow(
              'Hourly Limit',
              '${widget.campaign.hourlyLimit} emails/hour',
            ),
          _buildDetailRow(
            'Track Opens',
            widget.campaign.trackOpens ? 'Yes' : 'No',
          ),
          _buildDetailRow(
            'Track Clicks',
            widget.campaign.trackClicks ? 'Yes' : 'No',
          ),
          _buildDetailRow(
            'Track Replies',
            widget.campaign.trackReplies ? 'Yes' : 'No',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildRecipientsSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recipients',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_recipients.isEmpty)
            const Text(
              'No recipients yet',
              style: TextStyle(color: Colors.grey),
            )
          else
            ..._recipients.map((recipient) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(recipient.fullName[0].toUpperCase()),
                  ),
                  title: Text(recipient.fullName),
                  subtitle: Text(recipient.email),
                  trailing: _buildRecipientStatusBadge(recipient.status),
                ),
              );
            }),
          if (_recipients.length >= 50)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Showing first 50 recipients',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(CampaignStatus status) {
    Color color;
    switch (status) {
      case CampaignStatus.draft:
        color = Colors.grey;
        break;
      case CampaignStatus.scheduled:
        color = Colors.orange;
        break;
      case CampaignStatus.sending:
        color = Colors.blue;
        break;
      case CampaignStatus.paused:
        color = Colors.amber;
        break;
      case CampaignStatus.completed:
        color = Colors.green;
        break;
      case CampaignStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRecipientStatusBadge(EmailStatus status) {
    Color color;
    switch (status) {
      case EmailStatus.pending:
      case EmailStatus.queued:
        color = Colors.grey;
        break;
      case EmailStatus.sending:
      case EmailStatus.sent:
        color = Colors.blue;
        break;
      case EmailStatus.delivered:
        color = Colors.green;
        break;
      case EmailStatus.opened:
        color = Colors.orange;
        break;
      case EmailStatus.clicked:
        color = Colors.purple;
        break;
      case EmailStatus.replied:
        color = Colors.teal;
        break;
      case EmailStatus.bounced:
      case EmailStatus.failed:
        color = Colors.red;
        break;
      case EmailStatus.unsubscribed:
        color = Colors.amber;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Future<void> _startCampaign() async {
    try {
      await _campaignService.updateCampaignStatus(
        widget.campaign.id,
        CampaignStatus.sending,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign started successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting campaign: $e')));
      }
    }
  }

  Future<void> _pauseCampaign() async {
    try {
      await _campaignService.updateCampaignStatus(
        widget.campaign.id,
        CampaignStatus.paused,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign paused successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error pausing campaign: $e')));
      }
    }
  }
}
