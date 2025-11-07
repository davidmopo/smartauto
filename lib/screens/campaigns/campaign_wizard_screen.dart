import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign.dart';
import '../../models/email_template.dart';
import '../../models/contact.dart';
import '../../models/contact_list.dart';
import '../../services/campaign_service.dart';
import '../../services/template_service.dart';
import '../../services/contact_service.dart';
import '../../providers/auth_provider.dart';

/// Multi-step wizard for creating campaigns
class CampaignWizardScreen extends StatefulWidget {
  final Campaign? campaign; // For editing existing campaign

  const CampaignWizardScreen({super.key, this.campaign});

  @override
  State<CampaignWizardScreen> createState() => _CampaignWizardScreenState();
}

class _CampaignWizardScreenState extends State<CampaignWizardScreen> {
  final PageController _pageController = PageController();
  final CampaignService _campaignService = CampaignService();
  final TemplateService _templateService = TemplateService();
  final ContactService _contactService = ContactService();

  int _currentStep = 0;
  final int _totalSteps = 4;

  // Step 1: Campaign Details
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  CampaignType _campaignType = CampaignType.oneTime;

  // Step 2: Recipients
  List<Contact> _selectedContacts = [];
  List<ContactList> _selectedContactLists = [];
  List<Contact> _availableContacts = [];
  List<ContactList> _availableContactLists = [];

  // Step 3: Template
  EmailTemplate? _selectedTemplate;
  List<EmailTemplate> _availableTemplates = [];
  final _customSubjectController = TextEditingController();
  final _customBodyController = TextEditingController();

  // Step 4: Schedule
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  final _dailyLimitController = TextEditingController(text: '100');
  final _hourlyLimitController = TextEditingController(text: '10');
  bool _trackOpens = true;
  bool _trackClicks = true;
  bool _trackReplies = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.campaign != null) {
      _loadCampaignData();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _customSubjectController.dispose();
    _customBodyController.dispose();
    _dailyLimitController.dispose();
    _hourlyLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) return;

      final templates = await _templateService.getTemplates(
        userId,
        isActive: true,
      );
      final contacts = await _contactService.getContacts(userId);
      final contactLists = await _contactService.getContactLists(userId);

      setState(() {
        _availableTemplates = templates;
        _availableContacts = contacts;
        _availableContactLists = contactLists;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadCampaignData() {
    final campaign = widget.campaign!;
    _nameController.text = campaign.name;
    _descriptionController.text = campaign.description ?? '';
    _campaignType = campaign.type;
    _customSubjectController.text = campaign.customSubject ?? '';
    _customBodyController.text = campaign.customBody ?? '';
    _scheduledDate = campaign.scheduledAt;
    if (campaign.scheduledAt != null) {
      _scheduledTime = TimeOfDay.fromDateTime(campaign.scheduledAt!);
    }
    _dailyLimitController.text = campaign.dailyLimit?.toString() ?? '100';
    _hourlyLimitController.text = campaign.hourlyLimit?.toString() ?? '10';
    _trackOpens = campaign.trackOpens;
    _trackClicks = campaign.trackClicks;
    _trackReplies = campaign.trackReplies;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.campaign == null ? 'Create Campaign' : 'Edit Campaign',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1Details(),
                      _buildStep2Recipients(),
                      _buildStep3Template(),
                      _buildStep4Schedule(),
                    ],
                  ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? Colors.green
                              : isActive
                              ? Colors.blue
                              : Colors.grey[300],
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStepTitle(index),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isActive ? Colors.blue : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < _totalSteps - 1)
                  Container(
                    height: 2,
                    width: 20,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'Details';
      case 1:
        return 'Recipients';
      case 2:
        return 'Template';
      case 3:
        return 'Schedule';
      default:
        return '';
    }
  }

  Widget _buildStep1Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Campaign Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Campaign Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a campaign name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Campaign Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...CampaignType.values.map((type) {
              return RadioListTile<CampaignType>(
                title: Text(type.displayName),
                subtitle: Text(_getCampaignTypeDescription(type)),
                value: type,
                groupValue: _campaignType,
                onChanged: (value) {
                  setState(() => _campaignType = value!);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getCampaignTypeDescription(CampaignType type) {
    switch (type) {
      case CampaignType.oneTime:
        return 'Send a single email to all recipients';
      case CampaignType.drip:
        return 'Send a sequence of emails over time';
      case CampaignType.followUp:
        return 'Automatically follow up with recipients';
    }
  }

  Widget _buildStep2Recipients() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Recipients',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            'Selected: ${_getTotalRecipients()} contacts',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Contact Lists',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_availableContactLists.isEmpty)
            const Text(
              'No contact lists available',
              style: TextStyle(color: Colors.grey),
            )
          else
            ..._availableContactLists.map((list) {
              final isSelected = _selectedContactLists.contains(list);
              return CheckboxListTile(
                title: Text(list.name),
                subtitle: Text('${list.contactCount} contacts'),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedContactLists.add(list);
                    } else {
                      _selectedContactLists.remove(list);
                    }
                  });
                },
              );
            }),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Individual Contacts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedContacts.length == _availableContacts.length) {
                      _selectedContacts.clear();
                    } else {
                      _selectedContacts = List.from(_availableContacts);
                    }
                  });
                },
                child: Text(
                  _selectedContacts.length == _availableContacts.length
                      ? 'Deselect All'
                      : 'Select All',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_availableContacts.isEmpty)
            const Text(
              'No contacts available',
              style: TextStyle(color: Colors.grey),
            )
          else
            ..._availableContacts.take(20).map((contact) {
              final isSelected = _selectedContacts.contains(contact);
              return CheckboxListTile(
                title: Text(contact.fullName),
                subtitle: Text(contact.email),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedContacts.add(contact);
                    } else {
                      _selectedContacts.remove(contact);
                    }
                  });
                },
              );
            }),
          if (_availableContacts.length > 20)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Showing 20 of ${_availableContacts.length} contacts',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  int _getTotalRecipients() {
    // Count unique contacts from selected contacts and lists
    int total = _selectedContacts.length;
    for (var list in _selectedContactLists) {
      total += list.contactCount;
    }
    return total;
  }

  Widget _buildStep3Template() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Template',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (_availableTemplates.isEmpty)
            const Text(
              'No templates available',
              style: TextStyle(color: Colors.grey),
            )
          else
            ..._availableTemplates.map((template) {
              final isSelected = _selectedTemplate == template;
              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected ? Colors.blue.shade50 : null,
                child: RadioListTile<EmailTemplate>(
                  title: Text(template.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.subject),
                      const SizedBox(height: 4),
                      Text(
                        template.category.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  value: template,
                  groupValue: _selectedTemplate,
                  onChanged: (value) {
                    setState(() {
                      _selectedTemplate = value;
                      _customSubjectController.text = value?.subject ?? '';
                    });
                  },
                ),
              );
            }),
          if (_selectedTemplate != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Customize (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customSubjectController,
              decoration: const InputDecoration(
                labelText: 'Custom Subject',
                border: OutlineInputBorder(),
                helperText: 'Override template subject',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customBodyController,
              decoration: const InputDecoration(
                labelText: 'Custom Body',
                border: OutlineInputBorder(),
                helperText: 'Override template body',
              ),
              maxLines: 5,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep4Schedule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule Campaign',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'When to Send',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Send Now'),
                    leading: Radio<bool>(
                      value: false,
                      groupValue: _scheduledDate != null,
                      onChanged: (value) {
                        setState(() {
                          _scheduledDate = null;
                          _scheduledTime = null;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Schedule for Later'),
                    leading: Radio<bool>(
                      value: true,
                      groupValue: _scheduledDate != null,
                      onChanged: (value) {
                        if (value == true) {
                          _selectDate();
                        }
                      },
                    ),
                  ),
                  if (_scheduledDate != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              _scheduledTime != null
                                  ? _scheduledTime!.format(context)
                                  : 'Select Time',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sending Limits',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dailyLimitController,
                          decoration: const InputDecoration(
                            labelText: 'Daily Limit',
                            border: OutlineInputBorder(),
                            suffixText: 'emails/day',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _hourlyLimitController,
                          decoration: const InputDecoration(
                            labelText: 'Hourly Limit',
                            border: OutlineInputBorder(),
                            suffixText: 'emails/hour',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tracking Options',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Track Opens'),
                    subtitle: const Text('Track when recipients open emails'),
                    value: _trackOpens,
                    onChanged: (value) {
                      setState(() => _trackOpens = value ?? true);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Track Clicks'),
                    subtitle: const Text('Track when recipients click links'),
                    value: _trackClicks,
                    onChanged: (value) {
                      setState(() => _trackClicks = value ?? true);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Track Replies'),
                    subtitle: const Text('Track when recipients reply'),
                    value: _trackReplies,
                    onChanged: (value) {
                      setState(() => _trackReplies = value ?? true);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _scheduledDate = date);
      if (_scheduledTime == null) {
        _selectTime();
      }
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => _scheduledTime = time);
    }
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(onPressed: _previousStep, child: const Text('Back'))
          else
            const SizedBox(),
          ElevatedButton(
            onPressed: _currentStep < _totalSteps - 1
                ? _nextStep
                : _saveCampaign,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _currentStep < _totalSteps - 1 ? 'Next' : 'Create Campaign',
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && !_formKey.currentState!.validate()) {
      return;
    }

    if (_currentStep == 1 && _getTotalRecipients() == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipient')),
      );
      return;
    }

    if (_currentStep == 2 && _selectedTemplate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a template')));
      return;
    }

    setState(() {
      _currentStep++;
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _saveCampaign() async {
    // Validate template selection
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a template')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Combine scheduled date and time
      DateTime? scheduledDateTime;
      if (_scheduledDate != null && _scheduledTime != null) {
        scheduledDateTime = DateTime(
          _scheduledDate!.year,
          _scheduledDate!.month,
          _scheduledDate!.day,
          _scheduledTime!.hour,
          _scheduledTime!.minute,
        );
      }

      final now = DateTime.now();
      final campaign = Campaign(
        id: widget.campaign?.id ?? '',
        userId: userId,
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        type: _campaignType,
        status: scheduledDateTime != null
            ? CampaignStatus.scheduled
            : CampaignStatus.draft,
        templateId: _selectedTemplate!.id,
        customSubject: _customSubjectController.text.isNotEmpty
            ? _customSubjectController.text
            : null,
        customBody: _customBodyController.text.isNotEmpty
            ? _customBodyController.text
            : null,
        contactIds: _selectedContacts.map((c) => c.id).toList(),
        contactListIds: _selectedContactLists.map((l) => l.id).toList(),
        totalRecipients: _getTotalRecipients(),
        scheduledAt: scheduledDateTime,
        dailyLimit: int.tryParse(_dailyLimitController.text),
        hourlyLimit: int.tryParse(_hourlyLimitController.text),
        trackOpens: _trackOpens,
        trackClicks: _trackClicks,
        trackReplies: _trackReplies,
        createdAt: widget.campaign?.createdAt ?? now,
        updatedAt: now,
      );

      Campaign savedCampaign;
      if (widget.campaign == null) {
        // Create new campaign
        savedCampaign = await _campaignService.createCampaign(campaign);

        // Prepare recipients
        await _campaignService.prepareCampaignRecipients(
          savedCampaign,
          _selectedTemplate!,
        );
      } else {
        // Update existing campaign
        await _campaignService.updateCampaign(campaign);
        savedCampaign = campaign;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.campaign == null
                  ? 'Campaign created successfully!'
                  : 'Campaign updated successfully!',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving campaign: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
