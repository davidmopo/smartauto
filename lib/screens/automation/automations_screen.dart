import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/automation_workflow.dart';
import '../../services/automation_service.dart';
import 'workflow_builder_screen.dart';

/// Automations list screen
class AutomationsScreen extends StatefulWidget {
  const AutomationsScreen({super.key});

  @override
  State<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends State<AutomationsScreen> {
  final AutomationService _automationService = AutomationService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<AutomationWorkflow> _workflows = [];
  bool _isLoading = false;
  WorkflowStatus? _filterStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWorkflows();
  }

  Future<void> _loadWorkflows() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final workflows = await _automationService.getWorkflows(
        _currentUser.uid,
        status: _filterStatus,
      );

      setState(() {
        _workflows = workflows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading workflows: $e')),
        );
      }
    }
  }

  List<AutomationWorkflow> get _filteredWorkflows {
    if (_searchQuery.isEmpty) return _workflows;

    return _workflows.where((workflow) {
      return workflow.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (workflow.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automations'),
        actions: [
          // Filter by status
          PopupMenuButton<WorkflowStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by status',
            onSelected: (status) {
              setState(() => _filterStatus = status);
              _loadWorkflows();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Workflows'),
              ),
              ...WorkflowStatus.values.map((status) {
                return PopupMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }),
            ],
          ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadWorkflows,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search workflows...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Workflows list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWorkflows.isEmpty
                    ? _buildEmptyState()
                    : _buildWorkflowsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WorkflowBuilderScreen(),
            ),
          );

          if (result == true) {
            _loadWorkflows();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Automation'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No workflows found'
                : 'No automations yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Create your first automation workflow',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkflowBuilderScreen(),
                  ),
                );

                if (result == true) {
                  _loadWorkflows();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Automation'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkflowsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredWorkflows.length,
      itemBuilder: (context, index) {
        final workflow = _filteredWorkflows[index];
        return _buildWorkflowCard(workflow);
      },
    );
  }

  Widget _buildWorkflowCard(AutomationWorkflow workflow) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to workflow details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workflow.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (workflow.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            workflow.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildStatusChip(workflow.status),
                ],
              ),

              const SizedBox(height: 16),

              // Trigger info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flash_on, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trigger',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            workflow.trigger.type.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Actions count
              Row(
                children: [
                  Icon(Icons.list_alt, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${workflow.actions.length} action${workflow.actions.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _buildStatItem(
                    'Executions',
                    workflow.executionCount.toString(),
                    Icons.play_circle_outline,
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    'Success',
                    workflow.successCount.toString(),
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    'Failed',
                    workflow.failureCount.toString(),
                    Icons.error_outline,
                    color: Colors.red,
                  ),
                  const Spacer(),
                  // Actions menu
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      if (!workflow.isActive)
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.play_arrow, size: 20),
                              SizedBox(width: 8),
                              Text('Activate'),
                            ],
                          ),
                          onTap: () => _activateWorkflow(workflow.id),
                        ),
                      if (workflow.isActive)
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.pause, size: 20),
                              SizedBox(width: 8),
                              Text('Pause'),
                            ],
                          ),
                          onTap: () => _pauseWorkflow(workflow.id),
                        ),
                      const PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        onTap: () => _deleteWorkflow(workflow.id),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(WorkflowStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case WorkflowStatus.active:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case WorkflowStatus.paused:
        color = Colors.orange;
        icon = Icons.pause_circle;
        break;
      case WorkflowStatus.draft:
        color = Colors.grey;
        icon = Icons.edit;
        break;
      case WorkflowStatus.archived:
        color = Colors.blueGrey;
        icon = Icons.archive;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _activateWorkflow(String workflowId) async {
    try {
      await _automationService.activateWorkflow(workflowId);
      _loadWorkflows();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workflow activated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pauseWorkflow(String workflowId) async {
    try {
      await _automationService.pauseWorkflow(workflowId);
      _loadWorkflows();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workflow paused')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteWorkflow(String workflowId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workflow'),
        content: const Text(
          'Are you sure you want to delete this workflow? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _automationService.deleteWorkflow(workflowId);
        _loadWorkflows();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workflow deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

