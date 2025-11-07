import 'package:flutter/material.dart';

class Campaign {
  final String id;
  final String name;
  final String status;
  final int emailsSent;
  final int totalEmails;
  final double openRate;
  final DateTime createdAt;

  Campaign({
    required this.id,
    required this.name,
    required this.status,
    required this.emailsSent,
    required this.totalEmails,
    required this.openRate,
    required this.createdAt,
  });
}

class RecentCampaignsWidget extends StatelessWidget {
  const RecentCampaignsWidget({super.key});

  // Mock data - will be replaced with real data from provider
  List<Campaign> get _mockCampaigns => [
        Campaign(
          id: '1',
          name: 'Welcome Series',
          status: 'Active',
          emailsSent: 450,
          totalEmails: 500,
          openRate: 45.5,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Campaign(
          id: '2',
          name: 'Product Launch',
          status: 'Completed',
          emailsSent: 1200,
          totalEmails: 1200,
          openRate: 38.2,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Campaign(
          id: '3',
          name: 'Newsletter Q1',
          status: 'Draft',
          emailsSent: 0,
          totalEmails: 800,
          openRate: 0,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final campaigns = _mockCampaigns;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Campaigns',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('View All - Coming soon!')),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (campaigns.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No campaigns yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first campaign to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: campaigns.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final campaign = campaigns[index];
                  return _buildCampaignItem(context, campaign);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignItem(BuildContext context, Campaign campaign) {
    final statusColor = _getStatusColor(campaign.status);
    final progress = campaign.totalEmails > 0
        ? campaign.emailsSent / campaign.totalEmails
        : 0.0;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('View campaign: ${campaign.name}')),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(campaign.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    campaign.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'Sent',
                    '${campaign.emailsSent}/${campaign.totalEmails}',
                    Icons.send,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Open Rate',
                    '${campaign.openRate.toStringAsFixed(1)}%',
                    Icons.mark_email_read,
                  ),
                ),
              ],
            ),
            if (campaign.status == 'Active') ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'draft':
        return Colors.orange;
      case 'paused':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

