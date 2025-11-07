import 'package:flutter/material.dart';

class PreviewTemplate extends StatelessWidget {
  final String subject;
  final String content;
  final Map<String, String> previewData;

  const PreviewTemplate({
    super.key,
    required this.subject,
    required this.content,
    this.previewData = const {
      'firstName': 'John',
      'lastName': 'Doe',
      'fullName': 'John Doe',
      'email': 'john.doe@example.com',
      'company': 'ACME Corp',
      'position': 'CEO',
      'website': 'www.example.com',
    },
  });

  String _replaceVariables(String text) {
    String result = text;
    previewData.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final previewSubject = _replaceVariables(subject);
    final previewContent = _replaceVariables(content);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    previewSubject,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(height: 32),
                  Text(
                    previewContent,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Note: This is a preview with sample data. Actual emails will use recipient-specific information.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
