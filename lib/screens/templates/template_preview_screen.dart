import 'package:flutter/material.dart';
import '../../models/email_template.dart';

/// Screen for previewing email templates with sample data
class TemplatePreviewScreen extends StatefulWidget {
  final EmailTemplate template;

  const TemplatePreviewScreen({super.key, required this.template});

  @override
  State<TemplatePreviewScreen> createState() => _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends State<TemplatePreviewScreen> {
  // Sample data for preview
  final Map<String, String> _sampleData = {
    'firstName': 'John',
    'lastName': 'Doe',
    'fullName': 'John Doe',
    'email': 'john.doe@example.com',
    'company': 'Acme Corporation',
    'position': 'CEO',
    'website': 'www.acme.com',
  };

  @override
  Widget build(BuildContext context) {
    final previewSubject = EmailTemplate.replaceVariables(
      widget.template.subject,
      _sampleData,
    );
    final previewBody = EmailTemplate.replaceVariables(
      widget.template.htmlBody,
      _sampleData,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Preview'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Preview area
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template info
                  Text(
                    widget.template.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.template.description != null) ...[
                    Text(
                      widget.template.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Divider(),
                  const SizedBox(height: 16),

                  // Email preview
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Subject: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Text(
                                      previewSubject,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'To: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(_sampleData['email']!),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Email body
                        Container(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            previewBody,
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sidebar with template details
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Template Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailItem('Category', widget.template.category.displayName),
                  _buildDetailItem('Status', widget.template.isActive ? 'Active' : 'Inactive'),
                  _buildDetailItem('Usage Count', widget.template.usageCount.toString()),
                  
                  if (widget.template.averageOpenRate != null)
                    _buildDetailItem(
                      'Avg. Open Rate',
                      '${widget.template.averageOpenRate!.toStringAsFixed(1)}%',
                    ),
                  
                  if (widget.template.averageClickRate != null)
                    _buildDetailItem(
                      'Avg. Click Rate',
                      '${widget.template.averageClickRate!.toStringAsFixed(1)}%',
                    ),

                  const Divider(height: 32),

                  const Text(
                    'Variables Used',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (widget.template.variables.isEmpty)
                    const Text(
                      'No variables used',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...widget.template.variables.map((variable) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.code, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                '{{$variable}}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _sampleData[variable] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const Divider(height: 32),

                  const Text(
                    'Sample Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Edit sample data to see how the template will look with different values:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  ..._sampleData.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextFormField(
                        initialValue: entry.value,
                        decoration: InputDecoration(
                          labelText: entry.key,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _sampleData[entry.key] = value;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

