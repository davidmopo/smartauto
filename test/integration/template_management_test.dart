import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:smartautomailer/main.dart' as app;
import 'package:smartautomailer/models/email_template.dart';
import 'package:smartautomailer/screens/templates/template_composer_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Template Management Tests', () {
    testWidgets('Complete template creation flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to template composer
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill template details
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        'Integration Test Template',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Subject'),
        'Integration Test Subject',
      );

      // Add content
      final editor = find.byType(QuillEditor);
      await tester.tap(editor);
      await tester.enterText(editor, 'Integration test content');

      // Add a tag
      await tester.tap(find.text('Add Tag'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'integration-test');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Toggle preview
      await tester.tap(find.byTooltip('Preview Template'));
      await tester.pumpAndSettle();
      expect(find.text('Integration test content'), findsOneWidget);

      // Save template
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify success
      expect(find.text('Template saved successfully!'), findsOneWidget);
    });

    testWidgets('Template editing and version control flow', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // Create initial template
      final template = EmailTemplate(
        id: 'test-id',
        userId: 'test-user',
        name: 'Test Template',
        subject: 'Test Subject',
        htmlBody: 'Original content',
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(home: TemplateComposerScreen(template: template)),
      );
      await tester.pumpAndSettle();

      // Modify content
      final editor = find.byType(QuillEditor);
      await tester.tap(editor);
      await tester.enterText(editor, 'Updated content');

      // Save changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Check version history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Verify versions are listed
      expect(find.text('Version 1'), findsOneWidget);
      expect(find.text('Version 2'), findsOneWidget);
    });
  });
}
