import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Execution status enum
enum ExecutionStatus {
  pending,
  running,
  completed,
  failed,
  cancelled;

  String get displayName {
    switch (this) {
      case ExecutionStatus.pending:
        return 'Pending';
      case ExecutionStatus.running:
        return 'Running';
      case ExecutionStatus.completed:
        return 'Completed';
      case ExecutionStatus.failed:
        return 'Failed';
      case ExecutionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Action execution result model
class ActionExecutionResult extends Equatable {
  final String actionId;
  final bool success;
  final String? errorMessage;
  final DateTime executedAt;
  final Map<String, dynamic>? metadata;

  const ActionExecutionResult({
    required this.actionId,
    required this.success,
    this.errorMessage,
    required this.executedAt,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        actionId,
        success,
        errorMessage,
        executedAt,
        metadata,
      ];

  Map<String, dynamic> toFirestore() {
    return {
      'action_id': actionId,
      'success': success,
      'error_message': errorMessage,
      'executed_at': Timestamp.fromDate(executedAt),
      'metadata': metadata,
    };
  }

  factory ActionExecutionResult.fromFirestore(Map<String, dynamic> data) {
    return ActionExecutionResult(
      actionId: data['action_id'] ?? '',
      success: data['success'] ?? false,
      errorMessage: data['error_message'],
      executedAt: (data['executed_at'] as Timestamp).toDate(),
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }
}

/// Workflow execution model - tracks individual workflow runs
class WorkflowExecution extends Equatable {
  final String id;
  final String workflowId;
  final String userId;
  final String? contactId;
  final String? campaignId;
  final ExecutionStatus status;
  final List<ActionExecutionResult> actionResults;
  final String? errorMessage;
  final DateTime? scheduledFor;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final Map<String, dynamic>? triggerData;

  const WorkflowExecution({
    required this.id,
    required this.workflowId,
    required this.userId,
    this.contactId,
    this.campaignId,
    required this.status,
    this.actionResults = const [],
    this.errorMessage,
    this.scheduledFor,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    this.triggerData,
  });

  @override
  List<Object?> get props => [
        id,
        workflowId,
        userId,
        contactId,
        campaignId,
        status,
        actionResults,
        errorMessage,
        scheduledFor,
        startedAt,
        completedAt,
        createdAt,
        triggerData,
      ];

  /// Check if execution is complete
  bool get isComplete =>
      status == ExecutionStatus.completed ||
      status == ExecutionStatus.failed ||
      status == ExecutionStatus.cancelled;

  /// Get execution duration in seconds
  int? get durationSeconds {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!).inSeconds;
  }

  /// Get success count
  int get successfulActions =>
      actionResults.where((r) => r.success).length;

  /// Get failure count
  int get failedActions =>
      actionResults.where((r) => !r.success).length;

  Map<String, dynamic> toFirestore() {
    return {
      'workflow_id': workflowId,
      'user_id': userId,
      'contact_id': contactId,
      'campaign_id': campaignId,
      'status': status.name,
      'action_results': actionResults.map((r) => r.toFirestore()).toList(),
      'error_message': errorMessage,
      'scheduled_for': scheduledFor != null
          ? Timestamp.fromDate(scheduledFor!)
          : null,
      'started_at': startedAt != null
          ? Timestamp.fromDate(startedAt!)
          : null,
      'completed_at': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'created_at': Timestamp.fromDate(createdAt),
      'trigger_data': triggerData,
    };
  }

  factory WorkflowExecution.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return WorkflowExecution(
      id: snapshot.id,
      workflowId: data['workflow_id'] ?? '',
      userId: data['user_id'] ?? '',
      contactId: data['contact_id'],
      campaignId: data['campaign_id'],
      status: ExecutionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ExecutionStatus.pending,
      ),
      actionResults: data['action_results'] != null
          ? (data['action_results'] as List)
              .map((r) => ActionExecutionResult.fromFirestore(r))
              .toList()
          : [],
      errorMessage: data['error_message'],
      scheduledFor: data['scheduled_for'] != null
          ? (data['scheduled_for'] as Timestamp).toDate()
          : null,
      startedAt: data['started_at'] != null
          ? (data['started_at'] as Timestamp).toDate()
          : null,
      completedAt: data['completed_at'] != null
          ? (data['completed_at'] as Timestamp).toDate()
          : null,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      triggerData: data['trigger_data'] != null
          ? Map<String, dynamic>.from(data['trigger_data'])
          : null,
    );
  }

  WorkflowExecution copyWith({
    String? id,
    String? workflowId,
    String? userId,
    String? contactId,
    String? campaignId,
    ExecutionStatus? status,
    List<ActionExecutionResult>? actionResults,
    String? errorMessage,
    DateTime? scheduledFor,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    Map<String, dynamic>? triggerData,
  }) {
    return WorkflowExecution(
      id: id ?? this.id,
      workflowId: workflowId ?? this.workflowId,
      userId: userId ?? this.userId,
      contactId: contactId ?? this.contactId,
      campaignId: campaignId ?? this.campaignId,
      status: status ?? this.status,
      actionResults: actionResults ?? this.actionResults,
      errorMessage: errorMessage ?? this.errorMessage,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      triggerData: triggerData ?? this.triggerData,
    );
  }
}

