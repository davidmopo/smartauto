import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:smartautomailer/models/email_template.dart';
import 'package:smartautomailer/providers/auth_provider.dart';
import 'package:smartautomailer/screens/templates/template_composer_screen.dart';
import 'package:smartautomailer/services/template_service.dart';

class MockTemplateService extends Mock implements TemplateService {}

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late MockTemplateService mockTemplateService;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockTemplateService = MockTemplateService();
    mockAuthProvider = MockAuthProvider();
  });

  Widget createTestWidget({EmailTemplate? template}) {
    return MaterialApp(
      home: MultiProvider(
        providers: [Provider<AuthProvider>(create: (_) => mockAuthProvider)],
        child: TemplateComposerScreen(template: template),
      ),
    );
  }

  group('Template Composer Screen UI Tests', () {
    testWidgets('renders empty template form correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Template'), findsOneWidget);
      expect(
        find.byType(TextFormField),
        findsNWidgets(3),
      ); // name, subject, description
      expect(find.byType(QuillEditor), findsOneWidget);
    });

    testWidgets('shows validation errors on empty form submission', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Try to save without entering data
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a template name'), findsOneWidget);
      expect(find.text('Please enter an email subject'), findsOneWidget);
    });

    testWidgets('toggles preview mode correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially in edit mode
      expect(find.byType(QuillEditor), findsOneWidget);
      expect(find.byType(PreviewTemplate), findsNothing);

      // Toggle preview
      await tester.tap(find.byTooltip('Preview Template'));
      await tester.pumpAndSettle();

      // Should show preview
      expect(find.byType(QuillEditor), findsNothing);
      expect(find.byType(PreviewTemplate), findsOneWidget);
    });

    testWidgets('adds and removes tags correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add tag
      await tester.tap(find.text('Add Tag'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'TestTag');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('TestTag'), findsOneWidget);

      // Remove tag
      await tester.tap(find.byIcon(Icons.cancel).first);
      await tester.pumpAndSettle();

      expect(find.text('TestTag'), findsNothing);
    });

    testWidgets('inserts variables correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open variable menu
      await tester.tap(find.byIcon(Icons.code));
      await tester.pumpAndSettle();

      // Insert a variable
      await tester.tap(find.text('{{firstName}}'));
      await tester.pumpAndSettle();

      // Variable should be inserted in the editor
      expect(find.text('{{firstName}}'), findsOneWidget);
    });
  });

  group('Template Composer Functionality Tests', () {
    testWidgets('saves new template correctly', (WidgetTester tester) async {
      when(mockAuthProvider.user).thenReturn(TestUser(uid: 'test-user'));
      when(mockTemplateService.createTemplate(any)).thenAnswer(
        (_) async => EmailTemplate(
          id: 'test-id',
          userId: 'test-user',
          name: 'Test Template',
          subject: 'Test Subject',
          htmlBody: 'Test content',
          category: TemplateCategory.general,
          tags: [],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Fill in the form
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        'Test Template',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Subject'),
        'Test Subject',
      );

      // Save the template
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(mockTemplateService.createTemplate(any)).called(1);
      expect(find.text('Template saved successfully!'), findsOneWidget);
    });

    testWidgets('handles validation errors correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter invalid data (empty fields)
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please fix the following errors:'), findsOneWidget);
    });

    testWidgets('autosaves template periodically', (WidgetTester tester) async {
      when(mockAuthProvider.user).thenReturn(TestUser(uid: 'test-user'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter some text
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        'Test Template',
      );
      await tester.pump(const Duration(minutes: 2));

      // Verify autosave was triggered
      expect(find.textContaining('Auto-saved'), findsOneWidget);
    });
  });

  group('Template Composer Performance Tests', () {
    testWidgets('handles large content efficiently', (
      WidgetTester tester,
    ) async {
      final largeTemplate = EmailTemplate(
        id: 'test-id',
        userId: 'test-user',
        name: 'Large Template',
        subject: 'Test Subject',
        htmlBody: 'A' * 10000, // Large content
        category: TemplateCategory.general,
        tags: List.generate(100, (index) => 'tag$index'),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(template: largeTemplate));
      final stopwatch = Stopwatch()..start();
      await tester.pumpAndSettle();
      stopwatch.stop();

      // Loading should take less than 1 second
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('Template Composer Accessibility Tests', () {
    testWidgets('supports screen readers', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify semantic labels
      expect(
        tester.getSemantics(find.byType(TextFormField).first),
        matchesSemantics(isTextField: true, hasLabel: true, hasTapAction: true),
      );
    });
  });
}

class TestUser {
  final String uid;
  TestUser({required this.uid});
}
