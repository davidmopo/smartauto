import 'package:flutter/material.dart';
import '../../services/hunter_service.dart';

/// Screen for verifying email addresses
class EmailVerifierScreen extends StatefulWidget {
  const EmailVerifierScreen({super.key});

  @override
  State<EmailVerifierScreen> createState() => _EmailVerifierScreenState();
}

class _EmailVerifierScreenState extends State<EmailVerifierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late HunterService _hunterService;

  bool _isVerifying = false;
  EmailVerificationResult? _result;

  @override
  void initState() {
    super.initState();
    // TODO: Replace with actual API key from settings/environment
    _hunterService = HunterService(apiKey: 'YOUR_HUNTER_API_KEY');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verifier'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVerificationForm(),
            const SizedBox(height: 32),
            if (_result != null) _buildResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationForm() {
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
                'Verify Email Address',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check if an email address is valid and deliverable',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'john.doe@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isVerifying ? null : _verifyEmail,
                  icon: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_user),
                  label: Text(_isVerifying ? 'Verifying...' : 'Verify Email'),
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
    final isValid = _result!.status == 'valid';
    final statusColor = _getStatusColor(_result!.status);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.cancel,
                  color: statusColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result!.email,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _result!.statusMessage,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDeliverabilityScore(_result!.score),
            const SizedBox(height: 24),
            const Text(
              'Verification Details:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCheckItem('Syntax Check', _result!.regexp),
            _buildCheckItem('MX Records', _result!.mxRecords),
            _buildCheckItem('SMTP Server', _result!.smtpServer),
            _buildCheckItem('SMTP Check', _result!.smtpCheck),
            const SizedBox(height: 16),
            const Text(
              'Additional Information:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem('Disposable Email', _result!.disposable),
            _buildInfoItem('Webmail', _result!.webmail),
            _buildInfoItem('Accept All', _result!.acceptAll),
            _buildInfoItem('Gibberish', _result!.gibberish),
            _buildInfoItem('Blocked', _result!.block),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _verifyAnother,
                icon: const Icon(Icons.refresh),
                label: const Text('Verify Another'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverabilityScore(int score) {
    Color scoreColor;
    String scoreLabel;

    if (score >= 90) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
    } else if (score >= 70) {
      scoreColor = Colors.lightGreen;
      scoreLabel = 'Good';
    } else if (score >= 50) {
      scoreColor = Colors.orange;
      scoreLabel = 'Fair';
    } else if (score >= 30) {
      scoreColor = Colors.deepOrange;
      scoreLabel = 'Poor';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Very Poor';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Deliverability Score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$score/100',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
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
          const SizedBox(height: 8),
          Text(
            scoreLabel,
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool passed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            color: passed ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: value ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value ? Colors.orange : Colors.green,
              ),
            ),
            child: Text(
              value ? 'Yes' : 'No',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: value ? Colors.orange : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'valid':
        return Colors.green;
      case 'invalid':
        return Colors.red;
      case 'accept_all':
        return Colors.orange;
      case 'webmail':
        return Colors.blue;
      case 'disposable':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
      _result = null;
    });

    try {
      final result = await _hunterService.verifyEmail(
        _emailController.text.trim(),
      );

      setState(() => _result = result);
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
      setState(() => _isVerifying = false);
    }
  }

  void _verifyAnother() {
    setState(() {
      _result = null;
      _emailController.clear();
    });
  }
}

