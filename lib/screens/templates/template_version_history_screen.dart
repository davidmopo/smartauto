import 'package:flutter/material.dart';
import '../../models/email_template.dart';
import '../../models/template_version.dart';
import '../../services/template_service.dart';
import '../../widgets/template_comparison_dialog.dart';

class TemplateVersionHistoryScreen extends StatefulWidget {
  final EmailTemplate template;

  const TemplateVersionHistoryScreen({super.key, required this.template});

  @override
  State<TemplateVersionHistoryScreen> createState() =>
      _TemplateVersionHistoryScreenState();
}

class _TemplateVersionHistoryScreenState
    extends State<TemplateVersionHistoryScreen> {
  final TemplateService _templateService = TemplateService();
  bool _isLoading = true;
  List<TemplateVersion> _versions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVersionHistory();
  }

  Future<void> _loadVersionHistory() async {
    try {
      setState(() => _isLoading = true);
      final versions = await _templateService.getTemplateVersions(
        widget.template.id,
      );
      setState(() {
        _versions = versions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading version history: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showVersionComparison(
    TemplateVersion version1,
    TemplateVersion version2,
  ) async {
    // Convert TemplateVersion to EmailTemplate for comparison
    final template1 = EmailTemplate(
      id: version1.id,
      userId: version1.userId,
      name: version1.name,
      subject: version1.subject,
      htmlBody: version1.htmlBody,
      plainTextBody: version1.plainTextBody,
      description: version1.description,
      variables: version1.variables,
      tags: version1.tags,
      category: widget.template.category,
      isActive: widget.template.isActive,
      createdAt: version1.createdAt,
      updatedAt: version1.createdAt,
    );

    final template2 = EmailTemplate(
      id: version2.id,
      userId: version2.userId,
      name: version2.name,
      subject: version2.subject,
      htmlBody: version2.htmlBody,
      plainTextBody: version2.plainTextBody,
      description: version2.description,
      variables: version2.variables,
      tags: version2.tags,
      category: widget.template.category,
      isActive: widget.template.isActive,
      createdAt: version2.createdAt,
      updatedAt: version2.createdAt,
    );

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) =>
          TemplateComparisonDialog(template1: template1, template2: template2),
    );
  }

  Future<void> _restoreVersion(TemplateVersion version) async {
    try {
      final shouldRestore =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Restore Version'),
              content: Text(
                'Are you sure you want to restore version ${version.versionNumber}? '
                'This will create a new version with the restored content.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Restore'),
                ),
              ],
            ),
          ) ??
          false;

      if (!shouldRestore) return;

      await _templateService.restoreVersion(widget.template.id, version.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Version restored successfully')),
      );

      // Refresh the version history
      await _loadVersionHistory();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error restoring version: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 30}mo ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Version History'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadVersionHistory,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _versions.isEmpty
          ? const Center(child: Text('No version history available'))
          : ListView.builder(
              itemCount: _versions.length,
              itemBuilder: (context, index) {
                final version = _versions[index];
                final isLatest = index == 0;
                final nextVersion = index < _versions.length - 1
                    ? _versions[index + 1]
                    : null;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Row(
                      children: [
                        Text(
                          'Version ${version.versionNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isLatest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Latest',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(version.changeDescription),
                        const SizedBox(height: 4),
                        Text(
                          _getTimeAgo(version.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (nextVersion != null)
                          IconButton(
                            icon: const Icon(Icons.compare),
                            tooltip: 'Compare with previous version',
                            onPressed: () =>
                                _showVersionComparison(version, nextVersion),
                          ),
                        if (!isLatest)
                          IconButton(
                            icon: const Icon(Icons.restore),
                            tooltip: 'Restore this version',
                            onPressed: () => _restoreVersion(version),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
