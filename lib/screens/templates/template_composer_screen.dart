import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../models/email_template.dart';
import '../../services/template_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/preview_template.dart';
import 'template_version_history_screen.dart';

/// Screen for creating and editing email templates
class TemplateComposerScreen extends StatefulWidget {
  final EmailTemplate? template; // Null for new template, existing for edit

  const TemplateComposerScreen({super.key, this.template});

  @override
  State<TemplateComposerScreen> createState() => _TemplateComposerScreenState();
}

class _TemplateComposerScreenState extends State<TemplateComposerScreen>
    with WidgetsBindingObserver {
  // Keyboard shortcut bindings
  final Map<ShortcutActivator, VoidCallback> _shortcuts = {};
  final FocusNode _editorFocusNode = FocusNode();

  // History for undo/redo
  final List<Document> _undoStack = [];
  final List<Document> _redoStack = [];
  static const int _maxHistorySize = 100;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  late QuillController _quillController;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  final TemplateService _templateService = TemplateService();

  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isPreviewMode = false;
  int _wordCount = 0;
  int _charCount = 0;
  DateTime? _lastAutoSave;

  // Template versioning
  int _version = 1;
  List<EmailTemplate> _history = [];

  // Template validation
  final Map<String, String> _validationErrors = {};
  bool _isValid = true;
  TemplateCategory _selectedCategory = TemplateCategory.general;
  List<String> _tags = [];
  bool _isActive = true;
  bool _isSaving = false;

  void _initializeShortcuts() {
    _shortcuts.addAll({
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
          _saveTemplate,
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP): () =>
          setState(() => _isPreviewMode = !_isPreviewMode),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): () =>
          _toggleStyleAttribute(Attribute.bold),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI): () =>
          _toggleStyleAttribute(Attribute.italic),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyU): () =>
          _toggleStyleAttribute(Attribute.underline),
    });
  }

  void _toggleStyleAttribute(Attribute attribute) {
    final selection = _quillController.selection;
    if (selection.baseOffset == -1) return;

    final currentStyle = _quillController.getSelectionStyle();
    final isEnabled = currentStyle.values.contains(attribute);

    try {
      _quillController.formatSelection(isEnabled ? null : attribute);

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${attribute.key[0].toUpperCase()}${attribute.key.substring(1)} ${!isEnabled ? 'enabled' : 'disabled'}',
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling style: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying style: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVariableMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + button.size.height,
        position.dx + button.size.width,
        position.dy + button.size.height + 200,
      ),
      items: const [
        PopupMenuItem(value: 'firstName', child: Text('{{firstName}}')),
        PopupMenuItem(value: 'lastName', child: Text('{{lastName}}')),
        PopupMenuItem(value: 'fullName', child: Text('{{fullName}}')),
        PopupMenuItem(value: 'email', child: Text('{{email}}')),
        PopupMenuItem(value: 'company', child: Text('{{company}}')),
        PopupMenuItem(value: 'position', child: Text('{{position}}')),
        PopupMenuItem(value: 'website', child: Text('{{website}}')),
      ],
    ).then((variable) {
      if (variable != null) {
        _insertVariable(variable);
      }
    });
  }

  void _insertVariable(String variable) {
    final index = _quillController.selection.baseOffset;
    final insertText = '{{$variable}}';
    if (index < 0) {
      // Append if selection invalid
      _quillController.document.insert(
        _quillController.document.length,
        insertText,
      );
      _quillController.updateSelection(
        TextSelection.collapsed(offset: _quillController.document.length),
        ChangeSource.LOCAL,
      );
    } else {
      _quillController.document.insert(index, insertText);
      _quillController.updateSelection(
        TextSelection.collapsed(offset: index + insertText.length),
        ChangeSource.LOCAL,
      );
    }
  }

  void _showVersionHistory() {
    if (widget.template == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TemplateVersionHistoryScreen(template: widget.template!),
      ),
    );
  }

  Future<void> _showTagDialog() async {
    await _showAddTagDialog();
  }

  void _pushToHistory() {
    _undoStack.add(Document.fromDelta(_quillController.document.toDelta()));
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;

    final currentDoc = Document.fromDelta(_quillController.document.toDelta());
    _redoStack.add(currentDoc);

    final previousDoc = _undoStack.removeLast();
    _quillController.document = previousDoc;
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    final currentDoc = Document.fromDelta(_quillController.document.toDelta());
    _undoStack.add(currentDoc);

    final nextDoc = _redoStack.removeLast();
    _quillController.document = nextDoc;
  }

  @override
  void initState() {
    super.initState();
    _initializeShortcuts();

    // Initialize FocusNode and ScrollController
    _focusNode = FocusNode();
    _scrollController = ScrollController();

    // Initialize Quill controller
    if (widget.template != null) {
      // Load existing template
      _nameController.text = widget.template!.name;
      _subjectController.text = widget.template!.subject;
      _descriptionController.text = widget.template!.description ?? '';
      _selectedCategory = widget.template!.category;
      _tags = List.from(widget.template!.tags);
      _isActive = widget.template!.isActive;

      // Setup autosave
      _setupAutosave();

      // Initialize with template content
      try {
        _quillController = QuillController(
          document: Document.fromJson([
            {"insert": widget.template!.htmlBody},
            {
              "insert": "\n",
              "attributes": {"header": 1},
            },
          ]),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        debugPrint('Error initializing editor: $e');
        // Fallback to empty document
        _quillController = QuillController.basic();
      }
    } else {
      // New template
      _quillController = QuillController.basic();
    }
  }

  void _setupAutosave() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_hasUnsavedChanges) {
        _autoSaveTemplate();
      }
    });

    // Listen for changes in the editor
    _quillController.changes.listen((_) {
      setState(() {
        _hasUnsavedChanges = true;
        _updateWordAndCharCount();
      });
    });
  }

  void _updateWordAndCharCount() {
    final text = _quillController.document.toPlainText();
    setState(() {
      _charCount = text.length;
      _wordCount = text.trim().split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _autoSaveTemplate() async {
    try {
      await _saveTemplate(showNotification: false);
      setState(() {
        _lastAutoSave = DateTime.now();
        _hasUnsavedChanges = false;
      });
    } catch (e) {
      // Silent fail for autosave
      debugPrint('Autosave failed: $e');
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _saveTemplate({bool showNotification = true}) async {
    if (!_formKey.currentState!.validate() || !_validateTemplate()) {
      if (_validationErrors.isNotEmpty && showNotification) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please fix the following errors:'),
                const SizedBox(height: 4),
                ..._validationErrors.values
                    .map(
                      (error) => Text(
                        '• $error',
                        style: const TextStyle(fontSize: 12),
                      ),
                    )
                    .toList(),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final htmlBody = _quillController.document.toPlainText();
      final subjectVars = EmailTemplate.extractVariables(
        _subjectController.text,
      );
      final bodyVars = EmailTemplate.extractVariables(htmlBody);
      final allVars = {...subjectVars, ...bodyVars}.toList();

      final now = DateTime.now();

      if (widget.template == null) {
        final template = EmailTemplate(
          id: '',
          userId: userId,
          name: _nameController.text.trim(),
          subject: _subjectController.text.trim(),
          htmlBody: htmlBody,
          plainTextBody: _quillController.document.toPlainText(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          variables: allVars,
          category: _selectedCategory,
          tags: _tags,
          isActive: _isActive,
          createdAt: now,
          updatedAt: now,
        );

        final createdTemplate = await _templateService.createTemplate(template);

        // Create initial version
        await _templateService.createVersion(
          createdTemplate.id,
          createdTemplate,
          'Initial version',
        );
      } else {
        final updatedTemplate = widget.template!.copyWith(
          name: _nameController.text.trim(),
          subject: _subjectController.text.trim(),
          htmlBody: htmlBody,
          plainTextBody: _quillController.document.toPlainText(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          variables: allVars,
          category: _selectedCategory,
          tags: _tags,
          isActive: _isActive,
          updatedAt: now,
        );

        await _templateService.updateTemplate(updatedTemplate);

        // Create new version
        await _templateService.createVersion(
          widget.template!.id,
          updatedTemplate,
          'Updated template content',
        );
      }

      if (mounted && showNotification) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template saved successfully!')),
        );
      }

      setState(() {
        _hasUnsavedChanges = false;
        if (showNotification) {
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      if (mounted && showNotification) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving template: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _nameController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.template == null ? 'New Template' : 'Edit Template',
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            // Preview toggle
            IconButton(
              icon: Icon(
                _isPreviewMode ? Icons.edit : Icons.preview,
                color: Colors.white,
              ),
              onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
              tooltip: _isPreviewMode ? 'Switch to Editor' : 'Preview Template',
            ),
            // Word count
            if (!_isPreviewMode)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$_wordCount words | $_charCount chars',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            // Last autosave indicator
            if (_lastAutoSave != null && _hasUnsavedChanges)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Auto-saved ${_getTimeAgo(_lastAutoSave!)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            // Version history
            if (widget.template != null)
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Version History',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TemplateVersionHistoryScreen(
                      template: widget.template!,
                    ),
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: _isSaving ? null : () => _saveTemplate(),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _isSaving ? 'Saving...' : 'Save',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Row(
            children: [
              // Main editor area
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildBasicInfoSection(),
                    const Divider(height: 1),
                    _buildToolbar(),
                    const Divider(height: 1),
                    Expanded(child: _buildEditor()),
                  ],
                ),
              ),
              // Sidebar
              Container(
                width: 300,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey.shade300)),
                ),
                child: _buildSidebar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50],
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Template Name',
              hintText: 'e.g., Cold Outreach - Tech Startups',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a template name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Email Subject',
              hintText: 'Use {{variables}} for personalization',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email subject';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.format_bold),
                    onPressed: () => _toggleStyleAttribute(Attribute.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_italic),
                    onPressed: () => _toggleStyleAttribute(Attribute.italic),
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_underline),
                    onPressed: () => _toggleStyleAttribute(Attribute.underline),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(),
          _buildVariableButton(),
        ],
      ),
    );
  }

  Widget _buildVariableButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.code),
      tooltip: 'Insert Variable',
      onSelected: (variable) {
        _insertVariable(variable);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'firstName', child: Text('{{firstName}}')),
        const PopupMenuItem(value: 'lastName', child: Text('{{lastName}}')),
        const PopupMenuItem(value: 'fullName', child: Text('{{fullName}}')),
        const PopupMenuItem(value: 'email', child: Text('{{email}}')),
        const PopupMenuItem(value: 'company', child: Text('{{company}}')),
        const PopupMenuItem(value: 'position', child: Text('{{position}}')),
        const PopupMenuItem(value: 'website', child: Text('{{website}}')),
      ],
    );
  }

  Widget _buildEditor() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: _isPreviewMode
          ? PreviewTemplate(
              subject: _subjectController.text,
              content: _quillController.document.toPlainText(),
            )
          : QuillToolbar(
              sharedConfigurations: const QuillSharedConfigurations(),
            ),
    );
  }

  Widget _buildSidebar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Template Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Category
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<TemplateCategory>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: TemplateCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Tags
          const Text('Tags', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                      backgroundColor: Colors.blue.shade50,
                    ),
                  )
                  .toList(),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Add Tag'),
                onPressed: _showAddTagDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Optional description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Active status
          SwitchListTile(
            title: const Text('Active'),
            subtitle: const Text('Template is available for use'),
            value: _isActive,
            onChanged: (value) {
              setState(() => _isActive = value);
            },
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),

          // Variables info
          const Text(
            'Available Variables',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildVariableChip('{{firstName}}'),
          _buildVariableChip('{{lastName}}'),
          _buildVariableChip('{{fullName}}'),
          _buildVariableChip('{{email}}'),
          _buildVariableChip('{{company}}'),
          _buildVariableChip('{{position}}'),
          _buildVariableChip('{{website}}'),
        ],
      ),
    );
  }

  Widget _buildVariableChip(String variable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Chip(
        label: Text(
          variable,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
        backgroundColor: Colors.blue.shade50,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _showAddTagDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tag Name',
            hintText: 'Enter a tag name',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_tags.contains(result)) {
          _tags.add(result);
        }
      });
    }
  }

  bool _validateTemplate() {
    _validationErrors.clear();
    bool isValid = true;

    // Validate name
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _validationErrors['name'] = 'Template name is required';
      isValid = false;
    } else if (name.length < 3) {
      _validationErrors['name'] = 'Template name must be at least 3 characters';
      isValid = false;
    } else if (name.length > 100) {
      _validationErrors['name'] = 'Template name cannot exceed 100 characters';
      isValid = false;
    }

    // Validate subject
    final subject = _subjectController.text.trim();
    if (subject.isEmpty) {
      _validationErrors['subject'] = 'Email subject is required';
      isValid = false;
    } else if (subject.length > 150) {
      _validationErrors['subject'] =
          'Subject line cannot exceed 150 characters';
      isValid = false;
    }

    // Validate content
    final content = _quillController.document.toPlainText().trim();
    if (content.isEmpty) {
      _validationErrors['content'] = 'Email content cannot be empty';
      isValid = false;
    } else if (content.length < 10) {
      _validationErrors['content'] =
          'Email content is too short (minimum 10 characters)';
      isValid = false;
    }

    // Validate variables
    final subjectVars = EmailTemplate.extractVariables(_subjectController.text);
    final bodyVars = EmailTemplate.extractVariables(content);

    // Check for unmatched variables
    final unmatchedVars = [
      ...subjectVars,
      ...bodyVars,
    ].where((v) => !_isValidVariable(v)).toList();
    if (unmatchedVars.isNotEmpty) {
      _validationErrors['variables'] =
          'Invalid variables found: ${unmatchedVars.join(', ')}';
      isValid = false;
    }

    // Check for missing closing variables
    final openVars = RegExp(r'\{\{([^}]+)').allMatches(content);
    final closeVars = RegExp(r'\}\}').allMatches(content);
    if (openVars.length != closeVars.length) {
      _validationErrors['syntax'] = 'Found unclosed variable placeholders';
      isValid = false;
    }

    // Check for empty lines at the beginning or end
    if (content.startsWith('\n') || content.endsWith('\n')) {
      _validationErrors['formatting'] =
          'Remove empty lines at the beginning and end';
      isValid = false;
    }

    // Check spam trigger words (basic example)
    const spamTriggers = [
      'free',
      'guarantee',
      'no obligation',
      'winner',
      'won',
      'prize',
      'urgent',
      '\$\$\$',
    ];

    final lowercaseContent = content.toLowerCase();
    final foundTriggers =
        spamTriggers.where((word) => lowercaseContent.contains(word)).toList();

    if (foundTriggers.isNotEmpty) {
      _validationErrors['spam'] =
          'Contains potential spam trigger words: ${foundTriggers.join(', ')}';
      isValid = false;
    }

    // Validate description if provided
    final description = _descriptionController.text.trim();
    if (description.isNotEmpty && description.length > 500) {
      _validationErrors['description'] =
          'Description cannot exceed 500 characters';
      isValid = false;
    }

    // Validate tags
    if (_tags.isEmpty) {
      _validationErrors['tags'] =
          'Add at least one tag for better organization';
      isValid = false;
    } else if (_tags.length > 10) {
      _validationErrors['tags'] = 'Cannot have more than 10 tags';
      isValid = false;
    }

    setState(() => _isValid = isValid);
    return isValid;
  }

  bool _isValidVariable(String variable) {
    const validVariables = {
      'firstName',
      'lastName',
      'fullName',
      'email',
      'company',
      'position',
      'website',
    };
    return validVariables.contains(variable);
  }
}
