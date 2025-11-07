import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/hunter_service.dart';
import '../../services/contact_service.dart';
import '../../models/contact.dart';

/// Screen for finding email addresses using Hunter.io
class EmailFinderScreen extends StatefulWidget {
  const EmailFinderScreen({super.key});

  @override
  State<EmailFinderScreen> createState() => _EmailFinderScreenState();
}

class _EmailFinderScreenState extends State<EmailFinderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _domainController = TextEditingController();

  late HunterService _hunterService;
  final ContactService _contactService = ContactService();

  bool _isSearching = false;
  EmailFinderResult? _result;
  AccountInfo? _accountInfo;

  @override
  void initState() {
    super.initState();
    // TODO: Replace with actual API key from settings/environment
    _hunterService = HunterService(apiKey: 'YOUR_HUNTER_API_KEY');
    _loadAccountInfo();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountInfo() async {
    try {
      final info = await _hunterService.getAccountInfo();
      setState(() => _accountInfo = info);
    } catch (e) {
      // Silently fail - account info is not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Finder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_accountInfo != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '${_accountInfo!.requestsAvailable} searches left',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchForm(),
            const SizedBox(height: 32),
            if (_result != null) _buildResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find Email Address',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the person\'s name and company domain to find their email address',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  hintText: 'John',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'Doe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _domainController,
                decoration: const InputDecoration(
                  labelText: 'Company Domain',
                  hintText: 'example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter company domain';
                  }
                  if (!value.contains('.')) {
                    return 'Please enter a valid domain';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSearching ? null : _findEmail,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isSearching ? 'Searching...' : 'Find Email'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Email Found!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            if (_result!.email != null) ...[
              _buildResultRow('Email', _result!.email!, Icons.email),
              const SizedBox(height: 16),
            ],
            if (_result!.firstName != null || _result!.lastName != null) ...[
              _buildResultRow(
                'Name',
                '${_result!.firstName ?? ''} ${_result!.lastName ?? ''}'.trim(),
                Icons.person,
              ),
              const SizedBox(height: 16),
            ],
            if (_result!.position != null) ...[
              _buildResultRow('Position', _result!.position!, Icons.work),
              const SizedBox(height: 16),
            ],
            if (_result!.department != null) ...[
              _buildResultRow('Department', _result!.department!, Icons.business_center),
              const SizedBox(height: 16),
            ],
            if (_result!.score != null) ...[
              _buildConfidenceScore(_result!.score!),
              const SizedBox(height: 16),
            ],
            if (_result!.sources.isNotEmpty) ...[
              const Text(
                'Sources:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(_result!.sources.take(3).map((source) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    '• ${source.domain ?? source.uri ?? 'Unknown'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              })),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saveContact,
                    icon: const Icon(Icons.save),
                    label: const Text('Save to Contacts'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _findAnother,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Find Another'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceScore(int score) {
    Color scoreColor;
    String scoreLabel;

    if (score >= 90) {
      scoreColor = Colors.green;
      scoreLabel = 'Very High';
    } else if (score >= 70) {
      scoreColor = Colors.lightGreen;
      scoreLabel = 'High';
    } else if (score >= 50) {
      scoreColor = Colors.orange;
      scoreLabel = 'Medium';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Low';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Confidence Score: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '$score% ($scoreLabel)',
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          minHeight: 8,
        ),
      ],
    );
  }

  Future<void> _findEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSearching = true;
      _result = null;
    });

    try {
      final result = await _hunterService.findEmail(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        domain: _domainController.text.trim(),
      );

      setState(() => _result = result);

      // Reload account info to update remaining searches
      _loadAccountInfo();
    } on HunterException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _saveContact() async {
    if (_result?.email == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if email already exists
      final exists = await _contactService.emailExists(userId, _result!.email!);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact already exists')),
          );
        }
        return;
      }

      // Create contact
      final contact = Contact(
        id: '',
        userId: userId,
        firstName: _result!.firstName,
        lastName: _result!.lastName,
        email: _result!.email!,
        position: _result!.position,
        company: _domainController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _contactService.createContact(contact);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving contact: $e')),
        );
      }
    }
  }

  void _findAnother() {
    setState(() {
      _result = null;
      _firstNameController.clear();
      _lastNameController.clear();
      _domainController.clear();
    });
  }
}

