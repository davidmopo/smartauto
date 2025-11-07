# Phase 7: Follow-up Automation System Implementation

## Overview
This document outlines the implementation of the Follow-up Automation system for creating intelligent, behavior-triggered email workflows.

## Completed Features

### 1. Automation Models ✅
**Files:**
- `lib/models/automation_workflow.dart`
- `lib/models/workflow_execution.dart`

**AutomationWorkflow Model Features:**
- Complete workflow definition with trigger and actions
- 4 workflow statuses (draft, active, paused, archived)
- Execution tracking (count, success, failure)
- Success rate calculation
- Firestore integration with timestamps

**Trigger Types (11 types):**
1. **Email Opened** - When a contact opens an email
2. **Email Clicked** - When a contact clicks a link
3. **Email Replied** - When a contact replies
4. **Email Bounced** - When an email bounces
5. **Email Not Opened** - When email isn't opened within timeframe
6. **Email Not Clicked** - When email isn't clicked within timeframe
7. **Contact Added** - When a new contact is added
8. **Contact Tagged** - When a contact receives a tag
9. **Time Delay** - After a specific time delay
10. **Specific Date** - On a specific date and time
11. **Campaign Completed** - When a campaign finishes

**Action Types (10 types):**
1. **Send Email** - Send an email using a template
2. **Add Tag** - Add a tag to the contact
3. **Remove Tag** - Remove a tag from the contact
4. **Update Field** - Update a contact field
5. **Add to List** - Add contact to a list
6. **Remove from List** - Remove contact from a list
7. **Send Notification** - Send notification to team
8. **Create Task** - Create a follow-up task
9. **Wait/Delay** - Wait for a specified time
10. **Stop Workflow** - Stop the workflow execution

**Condition Operators (8 types):**
- Equals, Not Equals
- Contains, Not Contains
- Greater Than, Less Than
- Is Empty, Is Not Empty

**AutomationTrigger Model:**
- Trigger type configuration
- Campaign and template references
- Delay configuration (hours, days)
- Specific date/time support
- Tag name for tag-based triggers
- Custom metadata support

**AutomationAction Model:**
- Action type and configuration
- Template, tag, list, field references
- Conditional execution support
- Delay configuration
- Notification messages
- Custom metadata

**AutomationCondition Model:**
- Field-based conditions
- Operator selection
- Value comparison
- Condition evaluation logic

**WorkflowExecution Model:**
- Execution status tracking (pending, running, completed, failed, cancelled)
- Action execution results
- Error tracking
- Timing information (scheduled, started, completed)
- Trigger data capture
- Duration calculation
- Success/failure metrics

### 2. Automation Service ✅
**File:** `lib/services/automation_service.dart`

**Workflow CRUD Operations:**
- `createWorkflow()` - Create new automation workflow
- `getWorkflow()` - Get workflow by ID
- `getWorkflows()` - Get all workflows for user with filtering
- `updateWorkflow()` - Update workflow configuration
- `deleteWorkflow()` - Delete workflow and all executions
- `activateWorkflow()` - Activate a workflow
- `pauseWorkflow()` - Pause a workflow
- `archiveWorkflow()` - Archive a workflow

**Execution Operations:**
- `createExecution()` - Create execution record
- `getExecution()` - Get execution by ID
- `getExecutions()` - Get executions for workflow
- `updateExecution()` - Update execution status
- `getExecutionStats()` - Get execution statistics

**Trigger Evaluation:**
- `evaluateTrigger()` - Check if trigger condition is met
- Event-based trigger evaluation (opened, clicked, replied, bounced)
- Negative trigger evaluation (not opened, not clicked)
- Contact-based triggers (added, tagged)
- Time-based triggers (delay, specific date)
- Campaign-based triggers (completed)

**Workflow Execution Engine:**
- `executeWorkflow()` - Execute workflow for a contact
- Asynchronous execution with status tracking
- Sequential action execution
- Conditional action execution
- Error handling and recovery
- Action result tracking
- Workflow statistics updates

**Action Executors:**
- `_executeSendEmail()` - Send email action (ready for email service integration)
- `_executeAddTag()` - Add tag to contact
- `_executeRemoveTag()` - Remove tag from contact
- `_executeUpdateField()` - Update contact field
- `_executeAddToList()` - Add contact to list
- `_executeRemoveFromList()` - Remove contact from list
- `_executeSendNotification()` - Send notification (placeholder)
- `_executeCreateTask()` - Create task (placeholder)
- `_executeWaitDelay()` - Wait/delay execution
- `_evaluateConditions()` - Evaluate action conditions

### 3. Automation Screens ✅

#### Automations List Screen
**File:** `lib/screens/automation/automations_screen.dart`

**Features:**
- List all automation workflows
- Search workflows by name/description
- Filter by status (all, draft, active, paused, archived)
- Workflow cards showing:
  - Name and description
  - Status chip with color coding
  - Trigger type and description
  - Action count
  - Execution statistics (total, success, failed)
- Quick actions menu:
  - Activate/Pause workflow
  - Edit workflow
  - Delete workflow (with confirmation)
- Empty state with call-to-action
- Refresh functionality
- Floating action button to create new automation

**UI Components:**
- Status chips with icons and colors
- Trigger info cards
- Statistics display
- Action menu
- Search bar
- Filter dropdown

#### Workflow Builder Screen
**File:** `lib/screens/automation/workflow_builder_screen.dart`

**Features:**
- Create new workflows
- Edit existing workflows
- Workflow name and description
- Trigger type selector with descriptions
- Action builder:
  - Add multiple actions
  - Remove actions
  - Action type selection dialog
  - Sequential action display
- Form validation
- Save workflow (draft status)
- Loading states
- Error handling

**UI Components:**
- Form fields for name and description
- Trigger selector dropdown
- Action cards with numbering
- Add action button
- Empty actions state
- Save button in app bar

### 4. Dashboard Integration ✅
**File:** `lib/screens/dashboard/dashboard_screen.dart`

**Updates:**
- Added "Automations" navigation item with auto_awesome icon
- Added navigation logic for sidebar (desktop)
- Added navigation logic for drawer (mobile)
- Integrated AutomationsScreen into navigation flow

## File Structure

```
lib/
├── models/
│   ├── automation_workflow.dart      # Workflow, trigger, action, condition models
│   └── workflow_execution.dart       # Execution tracking models
├── services/
│   └── automation_service.dart       # Automation CRUD and execution engine
├── screens/
│   ├── automation/
│   │   ├── automations_screen.dart   # Automation list screen
│   │   └── workflow_builder_screen.dart  # Workflow creation/editing
│   └── dashboard/
│       └── dashboard_screen.dart     # Updated with automation navigation
└── PHASE7_AUTOMATION_IMPLEMENTATION.md  # This file
```

## Database Schema

### Firestore Collections

#### `automation_workflows`
```javascript
{
  user_id: string,
  name: string,
  description: string | null,
  status: string,  // draft, active, paused, archived
  trigger: {
    type: string,
    campaign_id: string | null,
    template_id: string | null,
    delay_hours: number | null,
    delay_days: number | null,
    specific_date: timestamp | null,
    tag_name: string | null,
    metadata: map | null
  },
  actions: [
    {
      id: string,
      type: string,
      template_id: string | null,
      tag_name: string | null,
      list_id: string | null,
      field_name: string | null,
      field_value: any | null,
      notification_message: string | null,
      delay_hours: number | null,
      delay_days: number | null,
      conditions: [
        {
          field: string,
          operator: string,
          value: any
        }
      ] | null,
      metadata: map | null
    }
  ],
  execution_count: number,
  success_count: number,
  failure_count: number,
  last_executed_at: timestamp | null,
  created_at: timestamp,
  updated_at: timestamp
}
```

**Indexes Required:**
- `user_id` + `status` + `created_at` (for filtered workflow lists)
- `user_id` + `created_at` (for all workflows)

#### `workflow_executions`
```javascript
{
  workflow_id: string,
  user_id: string,
  contact_id: string | null,
  campaign_id: string | null,
  status: string,  // pending, running, completed, failed, cancelled
  action_results: [
    {
      action_id: string,
      success: boolean,
      error_message: string | null,
      executed_at: timestamp,
      metadata: map | null
    }
  ],
  error_message: string | null,
  scheduled_for: timestamp | null,
  started_at: timestamp | null,
  completed_at: timestamp | null,
  created_at: timestamp,
  trigger_data: map | null
}
```

**Indexes Required:**
- `workflow_id` + `created_at` (for workflow execution history)
- `workflow_id` + `status` + `created_at` (for filtered executions)
- `contact_id` + `created_at` (for contact execution history)
- `status` + `scheduled_for` (for scheduled execution processing)

## Configuration Required

### Firestore Security Rules
Update your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Automation workflows collection
    match /automation_workflows/{workflowId} {
      allow read: if request.auth != null && 
                  request.auth.uid == resource.data.user_id;
      allow write: if request.auth != null && 
                   request.auth.uid == request.resource.data.user_id;
    }
    
    // Workflow executions collection
    match /workflow_executions/{executionId} {
      allow read: if request.auth != null && 
                  request.auth.uid == resource.data.user_id;
      allow write: if request.auth != null && 
                   request.auth.uid == request.resource.data.user_id;
    }
  }
}
```

### Firestore Indexes
Create composite indexes in Firebase Console:

1. **automation_workflows (user workflows)**
   - Collection: `automation_workflows`
   - Fields: `user_id` (Ascending), `created_at` (Descending)

2. **automation_workflows (filtered)**
   - Collection: `automation_workflows`
   - Fields: `user_id` (Ascending), `status` (Ascending), `created_at` (Descending)

3. **workflow_executions (workflow history)**
   - Collection: `workflow_executions`
   - Fields: `workflow_id` (Ascending), `created_at` (Descending)

4. **workflow_executions (filtered)**
   - Collection: `workflow_executions`
   - Fields: `workflow_id` (Ascending), `status` (Ascending), `created_at` (Descending)

5. **workflow_executions (scheduled)**
   - Collection: `workflow_executions`
   - Fields: `status` (Ascending), `scheduled_for` (Ascending)

## Usage Examples

### Creating a Simple Follow-up Workflow

```dart
final automationService = AutomationService();

// Create workflow: Send follow-up if email not opened in 3 days
final workflow = AutomationWorkflow(
  id: '',
  userId: currentUser.uid,
  name: 'Follow-up if not opened',
  description: 'Send a follow-up email if the initial email is not opened within 3 days',
  status: WorkflowStatus.draft,
  trigger: AutomationTrigger(
    type: TriggerType.emailNotOpened,
    campaignId: 'campaign_123',
    delayDays: 3,
  ),
  actions: [
    AutomationAction(
      id: '1',
      type: ActionType.sendEmail,
      templateId: 'follow_up_template_id',
    ),
    AutomationAction(
      id: '2',
      type: ActionType.addTag,
      tagName: 'needs_follow_up',
    ),
  ],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final workflowId = await automationService.createWorkflow(workflow);
await automationService.activateWorkflow(workflowId);
```

### Creating a Tag-based Workflow

```dart
// Create workflow: Send welcome email when contact is tagged as "new_lead"
final workflow = AutomationWorkflow(
  id: '',
  userId: currentUser.uid,
  name: 'Welcome new leads',
  description: 'Automatically send welcome email to new leads',
  status: WorkflowStatus.draft,
  trigger: AutomationTrigger(
    type: TriggerType.contactTagged,
    tagName: 'new_lead',
  ),
  actions: [
    AutomationAction(
      id: '1',
      type: ActionType.sendEmail,
      templateId: 'welcome_template_id',
    ),
    AutomationAction(
      id: '2',
      type: ActionType.waitDelay,
      delayDays: 2,
    ),
    AutomationAction(
      id: '3',
      type: ActionType.sendEmail,
      templateId: 'follow_up_template_id',
    ),
  ],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

### Executing a Workflow

```dart
// Execute workflow for a contact
final executionId = await automationService.executeWorkflow(
  workflowId,
  contactId,
  campaignId: campaignId,
  triggerData: {
    'email_opened': false,
    'days_since_sent': 3,
  },
);

// Check execution status
final execution = await automationService.getExecution(executionId);
print('Status: ${execution?.status.displayName}');
print('Success: ${execution?.successfulActions}');
print('Failed: ${execution?.failedActions}');
```

## Testing Instructions

### 1. Test Workflow Creation
1. Navigate to Automations screen
2. Click "New Automation" button
3. Fill in workflow name and description
4. Select a trigger type
5. Add one or more actions
6. Save the workflow
7. Verify workflow appears in list

### 2. Test Workflow Management
1. View workflow in list
2. Test activate/pause actions
3. Test edit workflow
4. Test delete workflow (with confirmation)
5. Test search functionality
6. Test status filtering

### 3. Test Workflow Execution (Manual)
1. Create a simple workflow
2. Activate the workflow
3. Use automation service to execute manually
4. Check execution results
5. Verify action execution
6. Check workflow statistics update

## Known Limitations

1. **Email Sending Integration**: Email sending action is a placeholder - needs integration with email service
2. **Notification System**: Notification action is a placeholder
3. **Task Management**: Task creation action is a placeholder
4. **Visual Workflow Editor**: Current builder is form-based, not drag-and-drop visual
5. **Trigger Automation**: Triggers are not automatically evaluated - needs background job/scheduler
6. **Advanced Conditions**: Only basic AND logic for conditions (no OR, complex nesting)
7. **A/B Testing**: Not yet integrated with workflow actions
8. **Workflow Templates**: No pre-built workflow templates yet

## Next Steps

### Immediate Improvements
1. **Integrate Email Sending** - Connect send email action with actual email service
2. **Build Trigger Scheduler** - Create background job to evaluate triggers automatically
3. **Add Visual Workflow Editor** - Drag-and-drop interface for building workflows
4. **Enhance Action Configuration** - Add detailed configuration UI for each action type
5. **Add Workflow Analytics** - Detailed analytics for workflow performance
6. **Create Workflow Templates** - Pre-built workflows for common use cases
7. **Add Workflow Testing** - Test mode to simulate workflow execution

### Future Enhancements
1. **Advanced Conditions**
   - OR logic support
   - Nested conditions
   - Complex condition groups
   - Custom condition functions

2. **Workflow Features**
   - Branching workflows (if/else paths)
   - Parallel action execution
   - Workflow versioning
   - Workflow cloning
   - Workflow import/export

3. **Trigger Enhancements**
   - Custom event triggers
   - Webhook triggers
   - API triggers
   - Time-based recurring triggers
   - Multi-condition triggers

4. **Action Enhancements**
   - HTTP request action
   - Database update action
   - CRM integration actions
   - Slack/Teams notification
   - SMS sending action
   - Custom code execution

5. **Analytics & Monitoring**
   - Real-time execution monitoring
   - Workflow performance metrics
   - Conversion tracking
   - ROI calculation
   - Execution logs and debugging
   - Alert system for failures

6. **Collaboration**
   - Workflow sharing
   - Team workflows
   - Approval workflows
   - Comments and notes
   - Activity history

## Best Practices

### Workflow Design
1. **Keep It Simple**: Start with simple workflows and add complexity gradually
2. **Test Thoroughly**: Test workflows with small contact groups first
3. **Monitor Performance**: Track execution success rates and adjust
4. **Use Delays Wisely**: Don't overwhelm contacts with too many emails
5. **Handle Failures**: Plan for action failures and have fallback strategies

### Trigger Configuration
1. **Be Specific**: Use specific triggers that match your goals
2. **Avoid Overlap**: Ensure triggers don't conflict with each other
3. **Set Appropriate Delays**: Give contacts time to respond
4. **Consider Time Zones**: Account for recipient time zones
5. **Test Trigger Conditions**: Verify triggers fire when expected

### Action Configuration
1. **Sequence Matters**: Order actions logically
2. **Use Conditions**: Add conditions to actions for better targeting
3. **Provide Context**: Use meaningful names and descriptions
4. **Track Results**: Monitor action execution results
5. **Optimize Performance**: Minimize unnecessary actions

## Conclusion

Phase 7: Follow-up Automation System has been successfully implemented with core features:
- ✅ Automation models (workflow, trigger, action, condition, execution)
- ✅ Automation service with CRUD and execution engine
- ✅ Automations list screen
- ✅ Workflow builder screen
- ✅ Dashboard integration
- ✅ Trigger evaluation logic
- ✅ Action execution engine
- ✅ Execution tracking and analytics
- ⏭️ Email sending integration (ready for connection)
- ⏭️ Trigger scheduler (future enhancement)
- ⏭️ Visual workflow editor (future enhancement)

The automation system provides a solid foundation for creating intelligent, behavior-triggered email workflows. The infrastructure is in place and ready for integration with the email sending service and trigger scheduling system.

**Note**: To make automations fully functional, you need to:
1. Integrate email sending service with the `_executeSendEmail()` action
2. Create a background scheduler to evaluate triggers automatically
3. Connect trigger evaluation with email events from analytics system
4. Test end-to-end workflow execution with real contacts and campaigns

For testing purposes, you can manually execute workflows using the automation service and simulate trigger events.

