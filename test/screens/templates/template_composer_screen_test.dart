import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:provider/provider.dart';
import 'package:smartautomailer/models/email_template.dart';
import 'package:smartautomailer/models/user_model.dart';
import 'package:smartautomailer/providers/auth_provider.dart';
import 'package:smartautomailer/screens/templates/template_composer_screen.dart';
import 'package:smartautomailer/services/template_service.dart';
import 'package:smartautomailer/widgets/preview_template.dart';

// Mock classes that match the real implementations
class MockTemplateService extends Fake implements TemplateService {
  @override
  Future<EmailTemplate> createTemplate(EmailTemplate template) async {
    return template.copyWith(id: 'test-template-id');
  }

  @override
  Future<void> createVersion(
    String templateId,
    EmailTemplate template,
    String message,
  ) async {}
}

class MockAuthProvider extends Fake implements AuthProvider {
  @override
  UserModel? get user => UserModel(
    uid: 'test-user-id',
    email: 'test@example.com',
    emailVerified: true,
    createdAt: DateTime.now(),
  );
}

// Mock classes that match the real implementations
class MockTemplateService implements TemplateService {
  @override
  Future<EmailTemplate> createTemplate(EmailTemplate template) async {
    return template.copyWith(id: 'test-template-id');
  }

  @override
  Future<void> createVersion(
    String templateId,
    EmailTemplate template,
    String message,
  ) async {}

  @override
  Future<List<EmailTemplate>> getTemplates() async => [];

  @override
  Future<void> deleteTemplate(String templateId) async {}

  @override
  Future<void> updateTemplate(EmailTemplate template) async {}

  // Add other required methods with empty implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthProvider implements AuthProvider {
  @override
  UserModel? get user => UserModel(
    uid: 'test-user-id',
    email: 'test@example.com',
    emailVerified: true,
    createdAt: DateTime.now(),
  );

  // Add other required methods with empty implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockTemplateService mockTemplateService;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockTemplateService = MockTemplateService();
    mockAuthProvider = MockAuthProvider();

    // Mock auth provider user
    when(mockAuthProvider.user).thenReturn(const User(uid: 'test-user-id'));
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
      expect(find.byType(QuillToolbar), findsOneWidget); // Toolbar
      expect(find.byType(SwitchListTile), findsOneWidget); // Active status
    });

    testWidgets('validates required fields and shows errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Try to save without entering required fields
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      // Check for validation error messages
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

      // Remove the tag by finding its chip and tapping the delete icon
      final chip = find.byWidgetPredicate(
        (widget) => widget is Chip && (widget.label as Text).data == 'TestTag',
      );
      expect(chip, findsOneWidget);

      await tester.tap(
        find.descendant(of: chip, matching: find.byIcon(Icons.cancel)),
      );
      await tester.pumpAndSettle();

      expect(find.text('TestTag'), findsNothing);
    });

    testWidgets('shows preview mode', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Toggle preview mode
      await tester.tap(find.byIcon(Icons.preview));
      await tester.pumpAndSettle();

      expect(find.byType(PreviewTemplate), findsOneWidget);
      expect(find.byType(QuillEditor), findsNothing);
    });

    testWidgets('inserts variables from toolbar', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Open variable menu
      await tester.tap(find.byIcon(Icons.code));
      await tester.pumpAndSettle();

      // Select a variable
      await tester.tap(find.text('{{firstName}}'));
      await tester.pumpAndSettle();

      // Verify the variable was inserted into the editor
      final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      expect(
        editor.controller.document.toPlainText(),
        contains('{{firstName}}'),
      );
    });

    testWidgets('saves template successfully', (WidgetTester tester) async {
      // Setup mock service response
      when(mockTemplateService.createTemplate(any)).thenAnswer(
        (_) async => EmailTemplate(
          id: 'new-template-id',
          userId: 'test-user-id',
          name: 'Test Template',
          subject: 'Test Subject',
          htmlBody: 'Test Content',
          plainTextBody: 'Test Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      when(
        mockTemplateService.createVersion(any, any, any),
      ).thenAnswer((_) async => null);

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
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      // Verify save was called
      verify(mockTemplateService.createTemplate(any)).called(1);
      verify(mockTemplateService.createVersion(any, any, any)).called(1);

      // Verify success message
      expect(find.text('Template saved successfully!'), findsOneWidget);
    });

    testWidgets('handles keyboard shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Test formatting shortcuts
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      expect(find.text('Bold enabled'), findsOneWidget);

      // Test preview shortcut
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      expect(find.byType(PreviewTemplate), findsOneWidget);
    });
  });
}
