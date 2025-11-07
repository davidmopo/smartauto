import 'package:flutter/material.dart';

class Activity {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime timestamp;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.timestamp,
  });
}

class ActivityFeedWidget extends StatelessWidget {
  const ActivityFeedWidget({super.key});

  // Mock data - will be replaced with real data from provider
  List<Activity> get _mockActivities => [
        Activity(
          id: '1',
          title: 'Campaign Started',
          description: 'Welcome Series campaign has been launched',
          icon: Icons.play_circle,
          color: Colors.green,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Activity(
          id: '2',
          title: 'Contacts Imported',
          description: '250 new contacts added from CSV file',
          icon: Icons.upload_file,
          color: Colors.blue,
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        Activity(
          id: '3',
          title: 'Email Verified',
          description: '180 email addresses verified successfully',
          icon: Icons.verified,
          color: Colors.purple,
          timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        Activity(
          id: '4',
          title: 'Template Created',
          description: 'New email template "Product Launch" saved',
          icon: Icons.email,
          color: Colors.orange,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Activity(
          id: '5',
          title: 'Campaign Completed',
          description: 'Product Launch campaign finished with 38% open rate',
          icon: Icons.check_circle,
          color: Colors.teal,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final activities = _mockActivities;

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
                  'Recent Activity',
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
            if (activities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activity',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
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
                itemCount: activities.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _buildActivityItem(activity);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Activity activity) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: activity.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            activity.icon,
            color: activity.color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(activity.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

