import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:provider/provider.dart';
import 'package:smartautomailer/models/email_template.dart';
import 'package:smartautomailer/models/template_variant.dart';
import 'package:smartautomailer/models/template_version.dart';
import 'package:smartautomailer/models/user_model.dart';
import 'package:smartautomailer/providers/auth_provider.dart';
import 'package:smartautomailer/screens/templates/template_composer_screen.dart';
import 'package:smartautomailer/services/template_service.dart';
import 'package:smartautomailer/widgets/preview_template.dart';

// Mock implementation of TemplateService for testing
class MockTemplateService implements TemplateService {
  final Map<String, EmailTemplate> _templates = {};
  final Map<String, List<TemplateVariant>> _variants = {};
  final Map<String, List<TemplateVersion>> _versions = {};

  @override
  Future<EmailTemplate> createTemplate(EmailTemplate template) async {
    final newTemplate = template.copyWith(
      id: 'test-template-id-${_templates.length + 1}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _templates[newTemplate.id] = newTemplate;
    return newTemplate;
  }

  @override
  Future<void> createVersion(
    String templateId,
    EmailTemplate template,
    String message,
  ) async {
    final versions = _versions[templateId] ?? [];
    final nextVersion = versions.length + 1;

    final version = TemplateVersion(
      id: 'version-$templateId-$nextVersion',
      templateId: templateId,
      userId: template.userId,
      versionNumber: nextVersion,
      name: template.name,
      subject: template.subject,
      htmlBody: template.htmlBody,
      plainTextBody: template.plainTextBody,
      description: template.description,
      variables: template.variables,
      tags: template.tags,
      changeDescription: message,
      createdAt: DateTime.now(),
    );

    versions.add(version);
    _versions[templateId] = versions;
  }

  @override
  Future<List<EmailTemplate>> getTemplates(
    String userId, {
    TemplateCategory? category,
    bool? isActive,
    String? searchQuery,
    int? limit,
  }) async {
    var templates = _templates.values.where((t) => t.userId == userId).toList();

    if (category != null) {
      templates = templates.where((t) => t.category == category).toList();
    }

    if (isActive != null) {
      templates = templates.where((t) => t.isActive == isActive).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      templates = templates
          .where(
            (t) =>
                t.name.toLowerCase().contains(query) ||
                t.subject.toLowerCase().contains(query) ||
                (t.description?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    templates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (limit != null && templates.length > limit) {
      templates = templates.take(limit).toList();
    }

    return templates;
  }

  @override
  Future<void> updateTemplate(EmailTemplate template) async {
    if (_templates.containsKey(template.id)) {
      _templates[template.id] = template.copyWith(updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    _templates.remove(templateId);
    _variants.remove(templateId);
    _versions.remove(templateId);
  }

  @override
  Future<EmailTemplate?> getTemplate(String templateId) async {
    return _templates[templateId];
  }

  @override
  Future<EmailTemplate> duplicateTemplate(
    String templateId,
    String userId,
  ) async {
    final original = _templates[templateId];
    if (original == null) {
      throw TemplateServiceException('Template not found');
    }

    final now = DateTime.now();
    final duplicate = EmailTemplate(
      id: '',
      userId: userId,
      name: '${original.name} (Copy)',
      subject: original.subject,
      htmlBody: original.htmlBody,
      plainTextBody: original.plainTextBody,
      description: original.description,
      variables: original.variables,
      category: original.category,
      tags: original.tags,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    return createTemplate(duplicate);
  }

  @override
  Future<void> incrementUsageCount(String templateId) async {
    if (_templates.containsKey(templateId)) {
      final template = _templates[templateId]!;
      _templates[templateId] = template.copyWith(
        usageCount: (template.usageCount ?? 0) + 1,
      );
    }
  }

  // Mock implementations for variant-related methods
  @override
  Future<void> updatePerformanceMetrics(
    String templateId, {
    double? averageOpenRate,
    double? averageClickRate,
  }) async {}

  @override
  Future<TemplateVariant> createVariant(TemplateVariant variant) async {
    final variants = _variants[variant.templateId] ?? [];
    final newVariant = variant.copyWith(
      id: 'variant-${variant.templateId}-${variants.length + 1}',
    );
    variants.add(newVariant);
    _variants[variant.templateId] = variants;
    return newVariant;
  }

  @override
  Future<TemplateVariant?> getVariant(String variantId) async {
    for (final variants in _variants.values) {
      for (final variant in variants) {
        if (variant.id == variantId) return variant;
      }
    }
    return null;
  }

  @override
  Future<List<TemplateVariant>> getVariants(String templateId) async {
    return _variants[templateId] ?? [];
  }

  @override
  Future<void> updateVariant(TemplateVariant variant) async {
    final variants = _variants[variant.templateId] ?? [];
    final index = variants.indexWhere((v) => v.id == variant.id);
    if (index >= 0) {
      variants[index] = variant;
      _variants[variant.templateId] = variants;
    }
  }

  @override
  Future<void> deleteVariant(String variantId) async {
    for (final templateId in _variants.keys) {
      _variants[templateId] =
          _variants[templateId]!.where((v) => v.id != variantId).toList();
    }
  }

  @override
  Future<void> updateVariantMetrics(
    String variantId, {
    int? sentCount,
    int? openCount,
    int? clickCount,
    int? replyCount,
  }) async {
    final variant = await getVariant(variantId);
    if (variant != null) {
      final updatedVariant = variant.copyWith(
        sentCount: sentCount ?? variant.sentCount,
        openCount: openCount ?? variant.openCount,
        clickCount: clickCount ?? variant.clickCount,
        replyCount: replyCount ?? variant.replyCount,
        openRate: sentCount != null && sentCount > 0
            ? (openCount ?? 0) / sentCount * 100
            : variant.openRate,
        clickRate: sentCount != null && sentCount > 0
            ? (clickCount ?? 0) / sentCount * 100
            : variant.clickRate,
        replyRate: sentCount != null && sentCount > 0
            ? (replyCount ?? 0) / sentCount * 100
            : variant.replyRate,
      );
      await updateVariant(updatedVariant);
    }
  }

  @override
  Future<TemplateVariant?> getWinningVariant(String templateId) async {
    final variants = await getVariants(templateId);
    if (variants.isEmpty) return null;

    final significantVariants = variants.where((v) => v.hasSignificantData);
    if (significantVariants.isEmpty) return null;

    return significantVariants.reduce(
      (a, b) => a.performanceScore > b.performanceScore ? a : b,
    );
  } // Mock implementations for version-related methods

  @override
  Future<TemplateVersion> getVersion(String versionId) async {
    for (final versions in _versions.values) {
      for (final version in versions) {
        if (version.id == versionId) return version;
      }
    }
    throw TemplateServiceException('Version not found');
  }

  @override
  Future<List<TemplateVersion>> getTemplateVersions(String templateId) async {
    return _versions[templateId] ?? [];
  }

  @override
  Future<void> restoreVersion(String templateId, String versionId) async {
    final version = await getVersion(versionId);
    final template = _templates[templateId];
    if (template != null) {
      _templates[templateId] = template.copyWith(
        name: version.name,
        subject: version.subject,
        htmlBody: version.htmlBody,
        plainTextBody: version.plainTextBody,
        description: version.description,
        variables: version.variables,
        tags: version.tags,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> compareVersions(
    String version1Id,
    String version2Id,
  ) async {
    final v1 = await getVersion(version1Id);
    final v2 = await getVersion(version2Id);

    return {
      'nameChanged': v1.name != v2.name,
      'subjectChanged': v1.subject != v2.subject,
      'bodyChanged': v1.htmlBody != v2.htmlBody,
      'descriptionChanged': v1.description != v2.description,
      'variablesChanged': !_listsEqual(v1.variables, v2.variables),
      'tagsChanged': !_listsEqual(v1.tags, v2.tags),
    };
  }

  bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (var i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}

class MockAuthProvider with ChangeNotifier implements AuthProvider {
  final UserModel _user = UserModel(
    uid: 'test-user-id',
    email: 'test@example.com',
    emailVerified: true,
    createdAt: DateTime.now(),
  );

  @override
  UserModel? get user => _user;

  @override
  Future<bool> signIn({required String email, required String password}) async {
    return true;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> signUp({
    String? displayName,
    required String email,
    required String password,
  }) async {
    return true;
  }

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    return true;
  }

  @override
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    return true;
  }

  @override
  Future<bool> deleteAccount() async {
    return true;
  }

  @override
  Future<void> reloadUser() async {}

  @override
  Future<bool> sendEmailVerification() async {
    return true;
  }

  @override
  Future<bool> updatePassword(String newPassword) async {
    return true;
  }

  @override
  void clearError() {}

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  bool get isAuthenticated => true;

  @override
  bool get isEmailVerified => true;

  @override
  AuthStatus get status => AuthStatus.authenticated;
}

void main() {
  late MockTemplateService mockTemplateService;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockTemplateService = MockTemplateService();
    mockAuthProvider = MockAuthProvider();
  });

  Widget createWidgetUnderTest({EmailTemplate? template}) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<AuthProvider>.value(value: mockAuthProvider),
          Provider<TemplateService>.value(value: mockTemplateService),
        ],
        child: TemplateComposerScreen(template: template),
      ),
    );
  }

  group('TemplateComposerScreen', () {
    testWidgets('renders correctly for new template', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('New Template'), findsOneWidget);
      expect(
        find.byType(TextFormField),
        findsNWidgets(3),
      ); // Name, Subject, Description
      expect(find.byType(QuillEditor), findsOneWidget); // Editor
      expect(find.byType(SwitchListTile), findsOneWidget); // Active status
    });

    testWidgets('validates required fields and shows errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Try to save without entering required fields
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Template name is required'), findsOneWidget);
      expect(find.text('Email subject is required'), findsOneWidget);
      expect(find.text('Email content cannot be empty'), findsOneWidget);
    });

    testWidgets('adds and removes tags', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Add a tag
      await tester.tap(find.text('Add Tag'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'TestTag');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('TestTag'), findsOneWidget);

      // Remove the tag
      final chip = find.widgetWithText(Chip, 'TestTag');
      await tester.tap(
        find.descendant(of: chip, matching: find.byIcon(Icons.cancel)),
      );
      await tester.pumpAndSettle();

      expect(find.text('TestTag'), findsNothing);
    });

    testWidgets('shows preview mode', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.preview));
      await tester.pumpAndSettle();

      expect(find.byType(PreviewTemplate), findsOneWidget);
      expect(find.byType(QuillEditor), findsNothing);
    });

    testWidgets('handles keyboard shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Test preview shortcut
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      expect(find.byType(PreviewTemplate), findsOneWidget);
    });

    testWidgets('saves template successfully', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Fill in required fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        'Test Template',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Subject'),
        'Test Subject',
      );

      // Add content to the editor
      final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      editor.controller.document.insert(0, 'Test Content');

      // Save the template
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Success message should appear
      expect(find.text('Template saved successfully!'), findsOneWidget);
    });

    testWidgets('loads and edits existing template', (
      WidgetTester tester,
    ) async {
      final existingTemplate = EmailTemplate(
        id: 'test-template-1',
        userId: 'test-user-id',
        name: 'Existing Template',
        subject: 'Existing Subject',
        htmlBody: '<p>Existing Content</p>',
        plainTextBody: 'Existing Content',
        description: 'Existing Description',
        tags: ['tag1', 'tag2'],
        isActive: true,
        category: TemplateCategory.general,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(template: existingTemplate),
      );
      await tester.pumpAndSettle();

      // Verify existing template data is loaded
      expect(find.text('Edit Template'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Existing Template'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Existing Subject'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Existing Description'),
        findsOneWidget,
      );

      // Verify tags are loaded
      expect(find.text('tag1'), findsOneWidget);
      expect(find.text('tag2'), findsOneWidget);

      // Edit template
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Existing Template'),
        'Updated Template',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Existing Subject'),
        'Updated Subject',
      );

      // Save changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Template saved successfully!'), findsOneWidget);
    });

    testWidgets('handles version control actions', (WidgetTester tester) async {
      final existingTemplate = EmailTemplate(
        id: 'test-template-1',
        userId: 'test-user-id',
        name: 'Existing Template',
        subject: 'Existing Subject',
        htmlBody: '<p>Original Content</p>',
        plainTextBody: 'Original Content',
        isActive: true,
        category: TemplateCategory.general,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(template: existingTemplate),
      );
      await tester.pumpAndSettle();

      // Make some changes
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Existing Template'),
        'Updated Template',
      );

      // Open version history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Should show version history dialog
      expect(find.text('Version History'), findsOneWidget);

      // Should have original version
      expect(find.text('Version 1'), findsOneWidget);

      // Save changes to create new version
      await tester.tap(find.text('Close')); // Close version history
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify version was created
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.text('Version 2'), findsOneWidget);
    });
  });
}
