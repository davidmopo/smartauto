import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Workflow status enum
enum WorkflowStatus {
  draft,
  active,
  paused,
  archived;

  String get displayName {
    switch (this) {
      case WorkflowStatus.draft:
        return 'Draft';
      case WorkflowStatus.active:
        return 'Active';
      case WorkflowStatus.paused:
        return 'Paused';
      case WorkflowStatus.archived:
        return 'Archived';
    }
  }
}

/// Trigger type enum
enum TriggerType {
  emailOpened,
  emailClicked,
  emailReplied,
  emailBounced,
  emailNotOpened,
  emailNotClicked,
  contactAdded,
  contactTagged,
  timeDelay,
  specificDate,
  campaignCompleted;

  String get displayName {
    switch (this) {
      case TriggerType.emailOpened:
        return 'Email Opened';
      case TriggerType.emailClicked:
        return 'Email Clicked';
      case TriggerType.emailReplied:
        return 'Email Replied';
      case TriggerType.emailBounced:
        return 'Email Bounced';
      case TriggerType.emailNotOpened:
        return 'Email Not Opened';
      case TriggerType.emailNotClicked:
        return 'Email Not Clicked';
      case TriggerType.contactAdded:
        return 'Contact Added';
      case TriggerType.contactTagged:
        return 'Contact Tagged';
      case TriggerType.timeDelay:
        return 'Time Delay';
      case TriggerType.specificDate:
        return 'Specific Date';
      case TriggerType.campaignCompleted:
        return 'Campaign Completed';
    }
  }

  String get description {
    switch (this) {
      case TriggerType.emailOpened:
        return 'When a contact opens an email';
      case TriggerType.emailClicked:
        return 'When a contact clicks a link in an email';
      case TriggerType.emailReplied:
        return 'When a contact replies to an email';
      case TriggerType.emailBounced:
        return 'When an email bounces';
      case TriggerType.emailNotOpened:
        return 'When a contact doesn\'t open an email within a timeframe';
      case TriggerType.emailNotClicked:
        return 'When a contact doesn\'t click within a timeframe';
      case TriggerType.contactAdded:
        return 'When a new contact is added';
      case TriggerType.contactTagged:
        return 'When a contact is tagged';
      case TriggerType.timeDelay:
        return 'After a specific time delay';
      case TriggerType.specificDate:
        return 'On a specific date and time';
      case TriggerType.campaignCompleted:
        return 'When a campaign finishes sending';
    }
  }
}

/// Action type enum
enum ActionType {
  sendEmail,
  addTag,
  removeTag,
  updateField,
  addToList,
  removeFromList,
  sendNotification,
  createTask,
  waitDelay,
  stopWorkflow;

  String get displayName {
    switch (this) {
      case ActionType.sendEmail:
        return 'Send Email';
      case ActionType.addTag:
        return 'Add Tag';
      case ActionType.removeTag:
        return 'Remove Tag';
      case ActionType.updateField:
        return 'Update Field';
      case ActionType.addToList:
        return 'Add to List';
      case ActionType.removeFromList:
        return 'Remove from List';
      case ActionType.sendNotification:
        return 'Send Notification';
      case ActionType.createTask:
        return 'Create Task';
      case ActionType.waitDelay:
        return 'Wait/Delay';
      case ActionType.stopWorkflow:
        return 'Stop Workflow';
    }
  }

  String get description {
    switch (this) {
      case ActionType.sendEmail:
        return 'Send an email to the contact';
      case ActionType.addTag:
        return 'Add a tag to the contact';
      case ActionType.removeTag:
        return 'Remove a tag from the contact';
      case ActionType.updateField:
        return 'Update a contact field';
      case ActionType.addToList:
        return 'Add contact to a list';
      case ActionType.removeFromList:
        return 'Remove contact from a list';
      case ActionType.sendNotification:
        return 'Send a notification to team';
      case ActionType.createTask:
        return 'Create a task for follow-up';
      case ActionType.waitDelay:
        return 'Wait for a specified time';
      case ActionType.stopWorkflow:
        return 'Stop the workflow execution';
    }
  }
}

/// Condition operator enum
enum ConditionOperator {
  equals,
  notEquals,
  contains,
  notContains,
  greaterThan,
  lessThan,
  isEmpty,
  isNotEmpty;

  String get displayName {
    switch (this) {
      case ConditionOperator.equals:
        return 'Equals';
      case ConditionOperator.notEquals:
        return 'Not Equals';
      case ConditionOperator.contains:
        return 'Contains';
      case ConditionOperator.notContains:
        return 'Not Contains';
      case ConditionOperator.greaterThan:
        return 'Greater Than';
      case ConditionOperator.lessThan:
        return 'Less Than';
      case ConditionOperator.isEmpty:
        return 'Is Empty';
      case ConditionOperator.isNotEmpty:
        return 'Is Not Empty';
    }
  }
}

/// Automation trigger model
class AutomationTrigger extends Equatable {
  final TriggerType type;
  final String? campaignId;
  final String? templateId;
  final int? delayHours;
  final int? delayDays;
  final DateTime? specificDate;
  final String? tagName;
  final Map<String, dynamic>? metadata;

  const AutomationTrigger({
    required this.type,
    this.campaignId,
    this.templateId,
    this.delayHours,
    this.delayDays,
    this.specificDate,
    this.tagName,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    type,
    campaignId,
    templateId,
    delayHours,
    delayDays,
    specificDate,
    tagName,
    metadata,
  ];

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'campaign_id': campaignId,
      'template_id': templateId,
      'delay_hours': delayHours,
      'delay_days': delayDays,
      'specific_date': specificDate != null
          ? Timestamp.fromDate(specificDate!)
          : null,
      'tag_name': tagName,
      'metadata': metadata,
    };
  }

  factory AutomationTrigger.fromFirestore(Map<String, dynamic> data) {
    return AutomationTrigger(
      type: TriggerType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TriggerType.timeDelay,
      ),
      campaignId: data['campaign_id'],
      templateId: data['template_id'],
      delayHours: data['delay_hours'],
      delayDays: data['delay_days'],
      specificDate: data['specific_date'] != null
          ? (data['specific_date'] as Timestamp).toDate()
          : null,
      tagName: data['tag_name'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  AutomationTrigger copyWith({
    TriggerType? type,
    String? campaignId,
    String? templateId,
    int? delayHours,
    int? delayDays,
    DateTime? specificDate,
    String? tagName,
    Map<String, dynamic>? metadata,
  }) {
    return AutomationTrigger(
      type: type ?? this.type,
      campaignId: campaignId ?? this.campaignId,
      templateId: templateId ?? this.templateId,
      delayHours: delayHours ?? this.delayHours,
      delayDays: delayDays ?? this.delayDays,
      specificDate: specificDate ?? this.specificDate,
      tagName: tagName ?? this.tagName,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Automation condition model
class AutomationCondition extends Equatable {
  final String field;
  final ConditionOperator operator;
  final dynamic value;

  const AutomationCondition({
    required this.field,
    required this.operator,
    this.value,
  });

  @override
  List<Object?> get props => [field, operator, value];

  Map<String, dynamic> toFirestore() {
    return {'field': field, 'operator': operator.name, 'value': value};
  }

  factory AutomationCondition.fromFirestore(Map<String, dynamic> data) {
    return AutomationCondition(
      field: data['field'] ?? '',
      operator: ConditionOperator.values.firstWhere(
        (e) => e.name == data['operator'],
        orElse: () => ConditionOperator.equals,
      ),
      value: data['value'],
    );
  }

  /// Evaluate the condition against a value
  bool evaluate(dynamic actualValue) {
    switch (operator) {
      case ConditionOperator.equals:
        return actualValue == value;
      case ConditionOperator.notEquals:
        return actualValue != value;
      case ConditionOperator.contains:
        return actualValue.toString().contains(value.toString());
      case ConditionOperator.notContains:
        return !actualValue.toString().contains(value.toString());
      case ConditionOperator.greaterThan:
        if (actualValue is num && value is num) {
          return actualValue > value;
        }
        return false;
      case ConditionOperator.lessThan:
        if (actualValue is num && value is num) {
          return actualValue < value;
        }
        return false;
      case ConditionOperator.isEmpty:
        return actualValue == null ||
            actualValue.toString().isEmpty ||
            (actualValue is List && actualValue.isEmpty);
      case ConditionOperator.isNotEmpty:
        return actualValue != null &&
            actualValue.toString().isNotEmpty &&
            (actualValue is! List || actualValue.isNotEmpty);
    }
  }
}

/// Automation action model
class AutomationAction extends Equatable {
  final String id;
  final ActionType type;
  final String? templateId;
  final String? tagName;
  final String? listId;
  final String? fieldName;
  final dynamic fieldValue;
  final String? notificationMessage;
  final int? delayHours;
  final int? delayDays;
  final List<AutomationCondition>? conditions;
  final Map<String, dynamic>? metadata;

  const AutomationAction({
    required this.id,
    required this.type,
    this.templateId,
    this.tagName,
    this.listId,
    this.fieldName,
    this.fieldValue,
    this.notificationMessage,
    this.delayHours,
    this.delayDays,
    this.conditions,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    templateId,
    tagName,
    listId,
    fieldName,
    fieldValue,
    notificationMessage,
    delayHours,
    delayDays,
    conditions,
    metadata,
  ];

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type.name,
      'template_id': templateId,
      'tag_name': tagName,
      'list_id': listId,
      'field_name': fieldName,
      'field_value': fieldValue,
      'notification_message': notificationMessage,
      'delay_hours': delayHours,
      'delay_days': delayDays,
      'conditions': conditions?.map((c) => c.toFirestore()).toList(),
      'metadata': metadata,
    };
  }

  factory AutomationAction.fromFirestore(Map<String, dynamic> data) {
    return AutomationAction(
      id: data['id'] ?? '',
      type: ActionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActionType.sendEmail,
      ),
      templateId: data['template_id'],
      tagName: data['tag_name'],
      listId: data['list_id'],
      fieldName: data['field_name'],
      fieldValue: data['field_value'],
      notificationMessage: data['notification_message'],
      delayHours: data['delay_hours'],
      delayDays: data['delay_days'],
      conditions: data['conditions'] != null
          ? (data['conditions'] as List)
                .map((c) => AutomationCondition.fromFirestore(c))
                .toList()
          : null,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  AutomationAction copyWith({
    String? id,
    ActionType? type,
    String? templateId,
    String? tagName,
    String? listId,
    String? fieldName,
    dynamic fieldValue,
    String? notificationMessage,
    int? delayHours,
    int? delayDays,
    List<AutomationCondition>? conditions,
    Map<String, dynamic>? metadata,
  }) {
    return AutomationAction(
      id: id ?? this.id,
      type: type ?? this.type,
      templateId: templateId ?? this.templateId,
      tagName: tagName ?? this.tagName,
      listId: listId ?? this.listId,
      fieldName: fieldName ?? this.fieldName,
      fieldValue: fieldValue ?? this.fieldValue,
      notificationMessage: notificationMessage ?? this.notificationMessage,
      delayHours: delayHours ?? this.delayHours,
      delayDays: delayDays ?? this.delayDays,
      conditions: conditions ?? this.conditions,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Automation workflow model
class AutomationWorkflow extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final WorkflowStatus status;
  final AutomationTrigger trigger;
  final List<AutomationAction> actions;
  final int executionCount;
  final int successCount;
  final int failureCount;
  final DateTime? lastExecutedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AutomationWorkflow({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.status,
    required this.trigger,
    required this.actions,
    this.executionCount = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.lastExecutedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    description,
    status,
    trigger,
    actions,
    executionCount,
    successCount,
    failureCount,
    lastExecutedAt,
    createdAt,
    updatedAt,
  ];

  /// Check if workflow is active
  bool get isActive => status == WorkflowStatus.active;

  /// Get success rate
  double get successRate {
    if (executionCount == 0) return 0.0;
    return (successCount / executionCount) * 100;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'description': description,
      'status': status.name,
      'trigger': trigger.toFirestore(),
      'actions': actions.map((a) => a.toFirestore()).toList(),
      'execution_count': executionCount,
      'success_count': successCount,
      'failure_count': failureCount,
      'last_executed_at': lastExecutedAt != null
          ? Timestamp.fromDate(lastExecutedAt!)
          : null,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory AutomationWorkflow.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return AutomationWorkflow(
      id: snapshot.id,
      userId: data['user_id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      status: WorkflowStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WorkflowStatus.draft,
      ),
      trigger: AutomationTrigger.fromFirestore(data['trigger'] ?? {}),
      actions: data['actions'] != null
          ? (data['actions'] as List)
                .map((a) => AutomationAction.fromFirestore(a))
                .toList()
          : [],
      executionCount: data['execution_count'] ?? 0,
      successCount: data['success_count'] ?? 0,
      failureCount: data['failure_count'] ?? 0,
      lastExecutedAt: data['last_executed_at'] != null
          ? (data['last_executed_at'] as Timestamp).toDate()
          : null,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  AutomationWorkflow copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    WorkflowStatus? status,
    AutomationTrigger? trigger,
    List<AutomationAction>? actions,
    int? executionCount,
    int? successCount,
    int? failureCount,
    DateTime? lastExecutedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AutomationWorkflow(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      trigger: trigger ?? this.trigger,
      actions: actions ?? this.actions,
      executionCount: executionCount ?? this.executionCount,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
