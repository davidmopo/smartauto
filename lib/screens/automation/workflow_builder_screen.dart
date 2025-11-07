import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/automation_workflow.dart';
import '../../services/automation_service.dart';

/// Workflow builder screen - create and edit automation workflows
class WorkflowBuilderScreen extends StatefulWidget {
  final AutomationWorkflow? workflow;

  const WorkflowBuilderScreen({super.key, this.workflow});

  @override
  State<WorkflowBuilderScreen> createState() => _WorkflowBuilderScreenState();
}

class _WorkflowBuilderScreenState extends State<WorkflowBuilderScreen> {
  final AutomationService _automationService = AutomationService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TriggerType _selectedTriggerType = TriggerType.emailOpened;
  final List<AutomationAction> _actions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.workflow != null) {
      _nameController.text = widget.workflow!.name;
      _descriptionController.text = widget.workflow!.description ?? '';
      _selectedTriggerType = widget.workflow!.trigger.type;
      _actions.addAll(widget.workflow!.actions);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workflow == null ? 'Create Automation' : 'Edit Automation'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveWorkflow,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Workflow name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workflow Name',
                hintText: 'e.g., Follow-up after email opened',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a workflow name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Describe what this automation does',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Trigger section
            Text(
              'Trigger',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'When should this automation run?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),

            _buildTriggerSelector(),

            const SizedBox(height: 24),

            // Actions section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: _addAction,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Action'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'What should happen when the trigger fires?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),

            if (_actions.isEmpty)
              _buildEmptyActionsState()
            else
              ..._actions.asMap().entries.map((entry) {
                return _buildActionCard(entry.key, entry.value);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<TriggerType>(
              initialValue: _selectedTriggerType,
              decoration: const InputDecoration(
                labelText: 'Trigger Type',
                border: OutlineInputBorder(),
              ),
              items: TriggerType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(type.displayName),
                      Text(
                        type.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTriggerType = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActionsState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.touch_app, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No actions yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add actions to define what happens when the trigger fires',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(int index, AutomationAction action) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text('${index + 1}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.type.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        action.type.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => _actions.removeAt(index));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addAction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ActionType.values.map((type) {
            return ListTile(
              title: Text(type.displayName),
              subtitle: Text(type.description),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _actions.add(AutomationAction(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: type,
                  ));
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _saveWorkflow() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    if (_actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one action')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final workflow = AutomationWorkflow(
        id: widget.workflow?.id ?? '',
        userId: _currentUser.uid,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        status: WorkflowStatus.draft,
        trigger: AutomationTrigger(type: _selectedTriggerType),
        actions: _actions,
        createdAt: widget.workflow?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.workflow == null) {
        await _automationService.createWorkflow(workflow);
      } else {
        await _automationService.updateWorkflow(
          widget.workflow!.id,
          workflow.toFirestore(),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.workflow == null
                  ? 'Workflow created successfully'
                  : 'Workflow updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

