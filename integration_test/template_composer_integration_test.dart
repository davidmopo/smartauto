import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartautomailer/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Template Composer Integration Tests', () {
    testWidgets('Create and save new template flow', (
      WidgetTester tester,
    ) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to template composer
      final createTemplateButton = find.byIcon(Icons.add);
      await tester.tap(createTemplateButton);
      await tester.pumpAndSettle();

      // Fill template details
      await tester.enterText(
        find.byType(TextFormField).first,
        'Integration Test Template',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Test Subject {{firstName}}',
      );

      // Add content to editor
      final editor = find.byType(TextFormField).last;
      await tester.tap(editor);
      await tester.enterText(
        editor,
        'Hello {{firstName}},\n\nThis is a test template.',
      );

      // Add a tag
      final addTagButton = find.byIcon(Icons.add);
      await tester.tap(addTagButton);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'integration-test');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Save template
      final saveButton = find.byIcon(Icons.save);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Template saved successfully!'), findsOneWidget);
    });

    testWidgets('Template preview and variable replacement', (
      WidgetTester tester,
    ) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Open existing template
      final templateTile = find.text('Integration Test Template');
      await tester.tap(templateTile);
      await tester.pumpAndSettle();

      // Toggle preview mode
      final previewButton = find.byIcon(Icons.preview);
      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      // Verify variable replacement in preview
      expect(find.text('Hello John,'), findsOneWidget);
    });

    testWidgets('Template version history flow', (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Open existing template
      final templateTile = find.text('Integration Test Template');
      await tester.tap(templateTile);
      await tester.pumpAndSettle();

      // Make changes
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Updated Subject {{firstName}}',
      );

      // Save changes
      final saveButton = find.byIcon(Icons.save);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Open version history
      final historyButton = find.byIcon(Icons.history);
      await tester.tap(historyButton);
      await tester.pumpAndSettle();

      // Verify version list
      expect(find.text('Version 2'), findsOneWidget);
      expect(find.text('Version 1'), findsOneWidget);
    });
  });

  group('Template Validation Integration Tests', () {
    testWidgets('Should show validation errors', (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to template composer
      final createTemplateButton = find.byIcon(Icons.add);
      await tester.tap(createTemplateButton);
      await tester.pumpAndSettle();

      // Try to save empty template
      final saveButton = find.byIcon(Icons.save);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify validation errors
      expect(find.text('Template name is required'), findsOneWidget);
      expect(find.text('Email subject is required'), findsOneWidget);
      expect(find.text('Email content cannot be empty'), findsOneWidget);
    });

    testWidgets('Should validate variable syntax', (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to template composer
      final createTemplateButton = find.byIcon(Icons.add);
      await tester.tap(createTemplateButton);
      await tester.pumpAndSettle();

      // Enter invalid variable syntax
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Hello {{firstName',
      );

      // Try to save
      final saveButton = find.byIcon(Icons.save);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Found unclosed variable placeholders'), findsOneWidget);
    });
  });

  group('Template Performance Integration Tests', () {
    testWidgets('Should handle large content', (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to template composer
      final createTemplateButton = find.byIcon(Icons.add);
      await tester.tap(createTemplateButton);
      await tester.pumpAndSettle();

      // Generate large content
      final largeContent = List.generate(1000, (i) => 'Line $i\n').join();

      // Enter large content
      final editor = find.byType(TextFormField).last;
      await tester.tap(editor);
      await tester.enterText(editor, largeContent);
      await tester.pumpAndSettle();

      // Verify editor is responsive
      expect(find.text('Line 999'), findsOneWidget);
    });
  });
}
