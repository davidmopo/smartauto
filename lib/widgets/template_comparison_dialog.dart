import 'package:flutter/material.dart';
// Lightweight comparison — avoid depending on external diff package for now.
import '../../models/email_template.dart';

class TemplateComparisonDialog extends StatelessWidget {
  final EmailTemplate template1;
  final EmailTemplate template2;

  const TemplateComparisonDialog({
    super.key,
    required this.template1,
    required this.template2,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Template Comparison',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildTemplateView(template1, 'Version 1')),
                  const VerticalDivider(),
                  Expanded(child: _buildTemplateView(template2, 'Version 2')),
                ],
              ),
            ),
            _buildDiffStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateView(EmailTemplate template, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildDiffSection('Name', template.name),
        _buildDiffSection('Subject', template.subject),
        _buildDiffSection('Description', template.description ?? ''),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: _buildDiffSection('Content', template.htmlBody),
          ),
        ),
        const Divider(),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: template.tags.map((tag) => Chip(label: Text(tag))).toList(),
        ),
      ],
    );
  }

  Widget _buildDiffSection(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  Widget _buildDiffStats() {
    final changes = _calculateChanges();

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.add_circle_outline,
            Colors.green,
            'Additions',
            changes.additions,
          ),
          _buildStatItem(
            Icons.remove_circle_outline,
            Colors.red,
            'Deletions',
            changes.deletions,
          ),
          _buildStatItem(
            Icons.edit_outlined,
            Colors.blue,
            'Changes',
            changes.modifications,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String label, int count) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text('$label: $count'),
      ],
    );
  }

  _DiffStats _calculateChanges() {
    final List<String> oldLines = template1.htmlBody.split('\n');
    final List<String> newLines = template2.htmlBody.split('\n');

    // Additions: lines present in new but not in old
    final oldSet = oldLines.toSet();
    final newSet = newLines.toSet();
    final additions = newSet.difference(oldSet).length;
    final deletions = oldSet.difference(newSet).length;

    // Modifications: differing lines at the same index
    int modifications = 0;
    final minLen = oldLines.length < newLines.length
        ? oldLines.length
        : newLines.length;
    for (int i = 0; i < minLen; i++) {
      if (oldLines[i] != newLines[i]) modifications++;
    }

    return _DiffStats(additions, deletions, modifications);
  }
}

class _DiffStats {
  final int additions;
  final int deletions;
  final int modifications;

  _DiffStats(this.additions, this.deletions, this.modifications);
}
