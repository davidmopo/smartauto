import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../utils/csv_parser.dart';
import '../../services/contact_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// Screen for uploading contacts from CSV files
class UploadContactsScreen extends StatefulWidget {
  const UploadContactsScreen({super.key});

  @override
  State<UploadContactsScreen> createState() => _UploadContactsScreenState();
}

class _UploadContactsScreenState extends State<UploadContactsScreen> {
  final ContactService _contactService = ContactService();

  // Upload state
  bool _isUploading = false;
  bool _isProcessing = false;
  String? _fileName;
  List<Map<String, dynamic>>? _parsedData;
  Map<String, String>? _columnMappings;
  ContactValidationResult? _validationResult;

  // Step tracking
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Contacts'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                if (details.currentStep < 2)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Continue'),
                  ),
                if (details.currentStep == 2)
                  ElevatedButton(
                    onPressed: _isUploading ? null : _importContacts,
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Import Contacts'),
                  ),
                const SizedBox(width: 8),
                if (details.currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Upload File'),
            content: _buildUploadStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Map Columns'),
            content: _buildMappingStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Review & Import'),
            content: _buildReviewStep(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload a CSV file containing your contacts',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        if (_fileName != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_present, color: Colors.blue),
              title: Text(_fileName!),
              subtitle: _parsedData != null
                  ? Text('${_parsedData!.length} rows found')
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _fileName = null;
                    _parsedData = null;
                    _columnMappings = null;
                  });
                },
              ),
            ),
          )
        else
          Center(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickFile,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_isProcessing ? 'Processing...' : 'Choose CSV File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'CSV Format Requirements:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('• First row must contain column headers'),
        const Text('• Email column is required'),
        const Text('• Supported columns: First Name, Last Name, Company, Position, Phone, etc.'),
      ],
    );
  }

  Widget _buildMappingStep() {
    if (_parsedData == null || _columnMappings == null) {
      return const Text('Please upload a file first');
    }

    final headers = _parsedData!.first.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Map CSV columns to contact fields',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        ...headers.map((header) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    header,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _columnMappings![header],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _getFieldOptions(),
                    onChanged: (value) {
                      setState(() {
                        _columnMappings![header] = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewStep() {
    if (_parsedData == null || _validationResult == null) {
      return const Text('Please complete previous steps');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review import summary',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryRow('Total Contacts', _validationResult!.total.toString()),
                _buildSummaryRow(
                  'Valid Contacts',
                  _validationResult!.valid.toString(),
                  color: Colors.green,
                ),
                _buildSummaryRow(
                  'Invalid Contacts',
                  _validationResult!.invalid.toString(),
                  color: Colors.red,
                ),
                _buildSummaryRow(
                  'Success Rate',
                  '${_validationResult!.validPercentage.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
        ),
        if (_validationResult!.hasErrors) ...[
          const SizedBox(height: 16),
          const Text(
            'Errors Found:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _validationResult!.errors.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    '• ${_validationResult!.errors[index]}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _getFieldOptions() {
    return [
      const DropdownMenuItem(value: 'email', child: Text('Email')),
      const DropdownMenuItem(value: 'first_name', child: Text('First Name')),
      const DropdownMenuItem(value: 'last_name', child: Text('Last Name')),
      const DropdownMenuItem(value: 'company', child: Text('Company')),
      const DropdownMenuItem(value: 'position', child: Text('Position')),
      const DropdownMenuItem(value: 'phone', child: Text('Phone')),
      const DropdownMenuItem(value: 'location', child: Text('Location')),
      const DropdownMenuItem(value: 'website', child: Text('Website')),
      const DropdownMenuItem(value: 'linkedin_url', child: Text('LinkedIn URL')),
      const DropdownMenuItem(value: 'twitter_handle', child: Text('Twitter Handle')),
      const DropdownMenuItem(value: 'tags', child: Text('Tags')),
      const DropdownMenuItem(value: 'ignore', child: Text('Ignore')),
    ];
  }

  Future<void> _pickFile() async {
    try {
      setState(() => _isProcessing = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        _fileName = file.name;

        // Parse CSV
        final csvContent = utf8.decode(file.bytes!);
        _parsedData = await CsvParser.parseCsv(csvContent);

        // Auto-detect column mappings
        final headers = _parsedData!.first.keys.toList();
        _columnMappings = CsvParser.detectColumnMappings(headers);

        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing file: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0 && _parsedData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a file first')),
      );
      return;
    }

    if (_currentStep == 1) {
      // Validate mappings and prepare data
      _validateAndPrepareData();
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _validateAndPrepareData() {
    if (_parsedData == null || _columnMappings == null) return;

    // Apply mappings
    final mappedData = CsvParser.applyMappings(_parsedData!, _columnMappings!);

    // Remove duplicates
    final uniqueData = CsvParser.removeDuplicates(mappedData);

    // Validate
    _validationResult = CsvParser.validateContacts(uniqueData);
    _parsedData = uniqueData;
  }

  Future<void> _importContacts() async {
    if (_parsedData == null) return;

    try {
      setState(() => _isUploading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Import contacts
      await _contactService.importContacts(userId, _parsedData!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${_validationResult!.valid} contacts'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing contacts: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }
}

