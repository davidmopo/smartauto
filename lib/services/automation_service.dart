import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/automation_workflow.dart';
import '../models/workflow_execution.dart';

/// Custom exception for automation service errors
class AutomationServiceException implements Exception {
  final String message;
  AutomationServiceException(this.message);

  @override
  String toString() => 'AutomationServiceException: $message';
}

/// Service for managing automation workflows
class AutomationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _workflowsCollection =>
      _firestore.collection('automation_workflows');

  CollectionReference<Map<String, dynamic>> get _executionsCollection =>
      _firestore.collection('workflow_executions');

  CollectionReference<Map<String, dynamic>> get _contactsCollection =>
      _firestore.collection('contacts');

  CollectionReference<Map<String, dynamic>> get _campaignsCollection =>
      _firestore.collection('campaigns');

  CollectionReference<Map<String, dynamic>> get _templatesCollection =>
      _firestore.collection('email_templates');

  // ==================== Workflow CRUD Operations ====================

  /// Create a new automation workflow
  Future<String> createWorkflow(AutomationWorkflow workflow) async {
    try {
      final docRef = await _workflowsCollection.add(workflow.toFirestore());
      return docRef.id;
    } catch (e) {
      throw AutomationServiceException('Failed to create workflow: $e');
    }
  }

  /// Get a workflow by ID
  Future<AutomationWorkflow?> getWorkflow(String workflowId) async {
    try {
      final doc = await _workflowsCollection.doc(workflowId).get();
      if (!doc.exists) return null;
      return AutomationWorkflow.fromFirestore(doc);
    } catch (e) {
      throw AutomationServiceException('Failed to get workflow: $e');
    }
  }

  /// Get all workflows for a user
  Future<List<AutomationWorkflow>> getWorkflows(
    String userId, {
    WorkflowStatus? status,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _workflowsCollection
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AutomationWorkflow.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw AutomationServiceException('Failed to get workflows: $e');
    }
  }

  /// Update a workflow
  Future<void> updateWorkflow(
    String workflowId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _workflowsCollection.doc(workflowId).update({
        ...updates,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      throw AutomationServiceException('Failed to update workflow: $e');
    }
  }

  /// Delete a workflow
  Future<void> deleteWorkflow(String workflowId) async {
    try {
      // Delete all executions for this workflow
      final executions = await _executionsCollection
          .where('workflow_id', isEqualTo: workflowId)
          .get();

      final batch = _firestore.batch();
      for (var doc in executions.docs) {
        batch.delete(doc.reference);
      }

      // Delete the workflow
      batch.delete(_workflowsCollection.doc(workflowId));

      await batch.commit();
    } catch (e) {
      throw AutomationServiceException('Failed to delete workflow: $e');
    }
  }

  /// Activate a workflow
  Future<void> activateWorkflow(String workflowId) async {
    await updateWorkflow(workflowId, {'status': WorkflowStatus.active.name});
  }

  /// Pause a workflow
  Future<void> pauseWorkflow(String workflowId) async {
    await updateWorkflow(workflowId, {'status': WorkflowStatus.paused.name});
  }

  /// Archive a workflow
  Future<void> archiveWorkflow(String workflowId) async {
    await updateWorkflow(workflowId, {'status': WorkflowStatus.archived.name});
  }

  // ==================== Workflow Execution Operations ====================

  /// Create a new workflow execution
  Future<String> createExecution(WorkflowExecution execution) async {
    try {
      final docRef = await _executionsCollection.add(execution.toFirestore());
      return docRef.id;
    } catch (e) {
      throw AutomationServiceException('Failed to create execution: $e');
    }
  }

  /// Get an execution by ID
  Future<WorkflowExecution?> getExecution(String executionId) async {
    try {
      final doc = await _executionsCollection.doc(executionId).get();
      if (!doc.exists) return null;
      return WorkflowExecution.fromFirestore(doc);
    } catch (e) {
      throw AutomationServiceException('Failed to get execution: $e');
    }
  }

  /// Get executions for a workflow
  Future<List<WorkflowExecution>> getExecutions(
    String workflowId, {
    ExecutionStatus? status,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _executionsCollection
          .where('workflow_id', isEqualTo: workflowId)
          .orderBy('created_at', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => WorkflowExecution.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw AutomationServiceException('Failed to get executions: $e');
    }
  }

  /// Update an execution
  Future<void> updateExecution(
    String executionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _executionsCollection.doc(executionId).update(updates);
    } catch (e) {
      throw AutomationServiceException('Failed to update execution: $e');
    }
  }

  /// Get execution statistics for a workflow
  Future<Map<String, int>> getExecutionStats(String workflowId) async {
    try {
      final executions = await _executionsCollection
          .where('workflow_id', isEqualTo: workflowId)
          .get();

      int total = executions.docs.length;
      int completed = 0;
      int failed = 0;
      int pending = 0;
      int running = 0;

      for (var doc in executions.docs) {
        final status = doc.data()['status'] as String?;
        switch (status) {
          case 'completed':
            completed++;
            break;
          case 'failed':
            failed++;
            break;
          case 'pending':
            pending++;
            break;
          case 'running':
            running++;
            break;
        }
      }

      return {
        'total': total,
        'completed': completed,
        'failed': failed,
        'pending': pending,
        'running': running,
      };
    } catch (e) {
      throw AutomationServiceException('Failed to get execution stats: $e');
    }
  }

  // ==================== Trigger Evaluation ====================

  /// Check if a trigger condition is met for a contact
  Future<bool> evaluateTrigger(
    AutomationTrigger trigger,
    String contactId, {
    String? campaignId,
    Map<String, dynamic>? eventData,
  }) async {
    try {
      switch (trigger.type) {
        case TriggerType.emailOpened:
        case TriggerType.emailClicked:
        case TriggerType.emailReplied:
        case TriggerType.emailBounced:
          // These are event-based triggers, evaluated when events occur
          return eventData != null;

        case TriggerType.emailNotOpened:
        case TriggerType.emailNotClicked:
          // Check if email was sent but not opened/clicked within timeframe
          return await _checkNegativeTrigger(trigger, contactId, campaignId);

        case TriggerType.contactAdded:
          // Trigger when contact is newly added
          final contact = await _contactsCollection.doc(contactId).get();
          if (!contact.exists) return false;
          final createdAt = (contact.data()!['created_at'] as Timestamp)
              .toDate();
          final now = DateTime.now();
          return now.difference(createdAt).inMinutes < 5; // Within 5 minutes

        case TriggerType.contactTagged:
          // Check if contact has the specified tag
          final contact = await _contactsCollection.doc(contactId).get();
          if (!contact.exists) return false;
          final tags = contact.data()!['tags'] as List?;
          return tags != null && tags.contains(trigger.tagName);

        case TriggerType.timeDelay:
          // Time-based trigger, handled by scheduler
          return true;

        case TriggerType.specificDate:
          // Check if current time matches specific date
          if (trigger.specificDate == null) return false;
          final now = DateTime.now();
          return now.isAfter(trigger.specificDate!);

        case TriggerType.campaignCompleted:
          // Check if campaign is completed
          if (campaignId == null) return false;
          final campaign = await _campaignsCollection.doc(campaignId).get();
          if (!campaign.exists) return false;
          final status = campaign.data()!['status'] as String?;
          return status == 'completed';
      }
    } catch (e) {
      throw AutomationServiceException('Failed to evaluate trigger: $e');
    }
  }

  /// Check negative triggers (email not opened, not clicked)
  Future<bool> _checkNegativeTrigger(
    AutomationTrigger trigger,
    String contactId,
    String? campaignId,
  ) async {
    if (campaignId == null) return false;

    // Calculate the timeframe
    final delayHours = trigger.delayHours ?? 0;
    final delayDays = trigger.delayDays ?? 0;
    final totalHours = delayHours + (delayDays * 24);

    if (totalHours == 0) return false;

    // Get email events for this contact and campaign
    final events = await _firestore
        .collection('email_events')
        .where('campaign_id', isEqualTo: campaignId)
        .where('recipient_id', isEqualTo: contactId)
        .get();

    final now = DateTime.now();
    bool emailSent = false;
    DateTime? sentAt;
    bool actionTaken = false;

    for (var event in events.docs) {
      final eventType = event.data()['event_type'] as String?;
      final timestamp = (event.data()['timestamp'] as Timestamp).toDate();

      if (eventType == 'sent') {
        emailSent = true;
        sentAt = timestamp;
      }

      if (trigger.type == TriggerType.emailNotOpened && eventType == 'opened') {
        actionTaken = true;
      }

      if (trigger.type == TriggerType.emailNotClicked &&
          eventType == 'clicked') {
        actionTaken = true;
      }
    }

    // Email was sent, action not taken, and timeframe has passed
    if (emailSent && !actionTaken && sentAt != null) {
      final hoursSinceSent = now.difference(sentAt).inHours;
      return hoursSinceSent >= totalHours;
    }

    return false;
  }

  // ==================== Workflow Execution Engine ====================

  /// Execute a workflow for a contact
  Future<String> executeWorkflow(
    String workflowId,
    String contactId, {
    String? campaignId,
    Map<String, dynamic>? triggerData,
  }) async {
    try {
      // Get the workflow
      final workflow = await getWorkflow(workflowId);
      if (workflow == null) {
        throw AutomationServiceException('Workflow not found');
      }

      if (!workflow.isActive) {
        throw AutomationServiceException('Workflow is not active');
      }

      // Create execution record
      final execution = WorkflowExecution(
        id: '',
        workflowId: workflowId,
        userId: workflow.userId,
        contactId: contactId,
        campaignId: campaignId,
        status: ExecutionStatus.pending,
        createdAt: DateTime.now(),
        triggerData: triggerData,
      );

      final executionId = await createExecution(execution);

      // Start execution asynchronously
      _executeWorkflowAsync(executionId, workflow, contactId);

      return executionId;
    } catch (e) {
      throw AutomationServiceException('Failed to execute workflow: $e');
    }
  }

  /// Execute workflow asynchronously
  Future<void> _executeWorkflowAsync(
    String executionId,
    AutomationWorkflow workflow,
    String contactId,
  ) async {
    try {
      // Update execution status to running
      await updateExecution(executionId, {
        'status': ExecutionStatus.running.name,
        'started_at': Timestamp.now(),
      });

      final actionResults = <ActionExecutionResult>[];

      // Execute each action in sequence
      for (var action in workflow.actions) {
        try {
          // Check if action has conditions
          if (action.conditions != null && action.conditions!.isNotEmpty) {
            final conditionsMet = await _evaluateConditions(
              action.conditions!,
              contactId,
            );
            if (!conditionsMet) {
              // Skip this action
              continue;
            }
          }

          // Execute the action
          await _executeAction(action, contactId, workflow.userId);

          // Record success
          actionResults.add(
            ActionExecutionResult(
              actionId: action.id,
              success: true,
              executedAt: DateTime.now(),
            ),
          );
        } catch (e) {
          // Record failure
          actionResults.add(
            ActionExecutionResult(
              actionId: action.id,
              success: false,
              errorMessage: e.toString(),
              executedAt: DateTime.now(),
            ),
          );

          // Continue with next action (don't stop on failure)
        }
      }

      // Update execution as completed
      await updateExecution(executionId, {
        'status': ExecutionStatus.completed.name,
        'completed_at': Timestamp.now(),
        'action_results': actionResults.map((r) => r.toFirestore()).toList(),
      });

      // Update workflow statistics
      await _updateWorkflowStats(workflow.id, true);
    } catch (e) {
      // Update execution as failed
      await updateExecution(executionId, {
        'status': ExecutionStatus.failed.name,
        'completed_at': Timestamp.now(),
        'error_message': e.toString(),
      });

      // Update workflow statistics
      await _updateWorkflowStats(workflow.id, false);
    }
  }

  /// Execute a single action
  Future<void> _executeAction(
    AutomationAction action,
    String contactId,
    String userId,
  ) async {
    switch (action.type) {
      case ActionType.sendEmail:
        await _executeSendEmail(action, contactId, userId);
        break;

      case ActionType.addTag:
        await _executeAddTag(action, contactId);
        break;

      case ActionType.removeTag:
        await _executeRemoveTag(action, contactId);
        break;

      case ActionType.updateField:
        await _executeUpdateField(action, contactId);
        break;

      case ActionType.addToList:
        await _executeAddToList(action, contactId);
        break;

      case ActionType.removeFromList:
        await _executeRemoveFromList(action, contactId);
        break;

      case ActionType.sendNotification:
        await _executeSendNotification(action, userId);
        break;

      case ActionType.createTask:
        await _executeCreateTask(action, contactId, userId);
        break;

      case ActionType.waitDelay:
        await _executeWaitDelay(action);
        break;

      case ActionType.stopWorkflow:
        throw Exception('Workflow stopped by action');
    }
  }

  /// Execute send email action
  Future<void> _executeSendEmail(
    AutomationAction action,
    String contactId,
    String userId,
  ) async {
    if (action.templateId == null) {
      throw AutomationServiceException(
        'Template ID is required for send email action',
      );
    }

    // Get contact details
    final contactDoc = await _contactsCollection.doc(contactId).get();
    if (!contactDoc.exists) {
      throw AutomationServiceException('Contact not found');
    }

    // Get template
    final templateDoc = await _templatesCollection.doc(action.templateId).get();
    if (!templateDoc.exists) {
      throw AutomationServiceException('Template not found');
    }

    // TODO: Integrate with email sending service
    // For now, we'll just log that the email would be sent
    print(
      'Would send email to contact $contactId using template ${action.templateId}',
    );
  }

  /// Execute add tag action
  Future<void> _executeAddTag(AutomationAction action, String contactId) async {
    if (action.tagName == null) {
      throw AutomationServiceException('Tag name is required');
    }

    await _contactsCollection.doc(contactId).update({
      'tags': FieldValue.arrayUnion([action.tagName]),
      'updated_at': Timestamp.now(),
    });
  }

  /// Execute remove tag action
  Future<void> _executeRemoveTag(
    AutomationAction action,
    String contactId,
  ) async {
    if (action.tagName == null) {
      throw AutomationServiceException('Tag name is required');
    }

    await _contactsCollection.doc(contactId).update({
      'tags': FieldValue.arrayRemove([action.tagName]),
      'updated_at': Timestamp.now(),
    });
  }

  /// Execute update field action
  Future<void> _executeUpdateField(
    AutomationAction action,
    String contactId,
  ) async {
    if (action.fieldName == null) {
      throw AutomationServiceException('Field name is required');
    }

    await _contactsCollection.doc(contactId).update({
      action.fieldName!: action.fieldValue,
      'updated_at': Timestamp.now(),
    });
  }

  /// Execute add to list action
  Future<void> _executeAddToList(
    AutomationAction action,
    String contactId,
  ) async {
    if (action.listId == null) {
      throw AutomationServiceException('List ID is required');
    }

    await _contactsCollection.doc(contactId).update({
      'lists': FieldValue.arrayUnion([action.listId]),
      'updated_at': Timestamp.now(),
    });
  }

  /// Execute remove from list action
  Future<void> _executeRemoveFromList(
    AutomationAction action,
    String contactId,
  ) async {
    if (action.listId == null) {
      throw AutomationServiceException('List ID is required');
    }

    await _contactsCollection.doc(contactId).update({
      'lists': FieldValue.arrayRemove([action.listId]),
      'updated_at': Timestamp.now(),
    });
  }

  /// Execute send notification action
  Future<void> _executeSendNotification(
    AutomationAction action,
    String userId,
  ) async {
    // TODO: Implement notification system
    print('Would send notification: ${action.notificationMessage}');
  }

  /// Execute create task action
  Future<void> _executeCreateTask(
    AutomationAction action,
    String contactId,
    String userId,
  ) async {
    // TODO: Implement task management system
    print('Would create task for contact $contactId');
  }

  /// Execute wait/delay action
  Future<void> _executeWaitDelay(AutomationAction action) async {
    final delayHours = action.delayHours ?? 0;
    final delayDays = action.delayDays ?? 0;
    final totalSeconds = (delayHours * 3600) + (delayDays * 86400);

    if (totalSeconds > 0) {
      await Future.delayed(Duration(seconds: totalSeconds));
    }
  }

  /// Evaluate conditions for an action
  Future<bool> _evaluateConditions(
    List<AutomationCondition> conditions,
    String contactId,
  ) async {
    final contactDoc = await _contactsCollection.doc(contactId).get();
    if (!contactDoc.exists) return false;

    final contactData = contactDoc.data()!;

    // All conditions must be met (AND logic)
    for (var condition in conditions) {
      final fieldValue = contactData[condition.field];
      if (!condition.evaluate(fieldValue)) {
        return false;
      }
    }

    return true;
  }

  /// Update workflow statistics
  Future<void> _updateWorkflowStats(String workflowId, bool success) async {
    await _workflowsCollection.doc(workflowId).update({
      'execution_count': FieldValue.increment(1),
      if (success) 'success_count': FieldValue.increment(1),
      if (!success) 'failure_count': FieldValue.increment(1),
      'last_executed_at': Timestamp.now(),
      'updated_at': Timestamp.now(),
    });
  }
}
