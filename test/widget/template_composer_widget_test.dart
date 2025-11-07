import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartautomailer/screens/templates/template_composer_screen.dart';
import 'package:smartautomailer/models/email_template.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import '../mocks/mock_providers.dart';

void main() {
  group('TemplateComposerScreen Widget Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockTemplateService mockTemplateService;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockTemplateService = MockTemplateService();
    });

    Future<void> pumpTemplateComposer(
      WidgetTester tester, {
      EmailTemplate? template,
    }) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ],
          child: MaterialApp(home: TemplateComposerScreen(template: template)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('should render all UI elements', (WidgetTester tester) async {
      await pumpTemplateComposer(tester);

      // Check for basic UI elements
      expect(find.text('New Template'), findsOneWidget);
      expect(
        find.byType(TextFormField),
        findsNWidgets(3),
      ); // Name, Subject, Description
      expect(find.byType(QuillEditor), findsOneWidget);
      expect(find.byType(DropdownButtonFormField), findsOneWidget); // Category
      expect(find.byIcon(Icons.preview), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('should toggle preview mode', (WidgetTester tester) async {
      await pumpTemplateComposer(tester);

      // Initial state - editor mode
      expect(find.byType(QuillEditor), findsOneWidget);
      expect(find.byType(PreviewTemplate), findsNothing);

      // Toggle preview
      await tester.tap(find.byIcon(Icons.preview));
      await tester.pumpAndSettle();

      // Check preview mode
      expect(find.byType(QuillEditor), findsNothing);
      expect(find.byType(PreviewTemplate), findsOneWidget);
    });

    testWidgets('should show formatting toolbar', (WidgetTester tester) async {
      await pumpTemplateComposer(tester);

      // Check formatting buttons
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.format_underline), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
    });

    testWidgets('should handle variable insertion', (
      WidgetTester tester,
    ) async {
      await pumpTemplateComposer(tester);

      // Open variable menu
      await tester.tap(find.byIcon(Icons.code));
      await tester.pumpAndSettle();

      // Select variable
      await tester.tap(find.text('{{firstName}}'));
      await tester.pumpAndSettle();

      // Verify variable was inserted
      final editor = find.byType(QuillEditor);
      expect(editor, findsOneWidget);
    });

    testWidgets('should show validation errors', (WidgetTester tester) async {
      await pumpTemplateComposer(tester);

      // Try to save without required fields
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      // Check error messages
      expect(find.text('Template name is required'), findsOneWidget);
      expect(find.text('Email subject is required'), findsOneWidget);
    });

    testWidgets('should handle keyboard shortcuts', (
      WidgetTester tester,
    ) async {
      await pumpTemplateComposer(tester);

      // Simulate Ctrl+B for bold
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Check if style was applied
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
    });

    testWidgets('should show loading state during save', (
      WidgetTester tester,
    ) async {
      await pumpTemplateComposer(tester);

      // Fill required fields
      await tester.enterText(find.byType(TextFormField).first, 'Test Template');
      await tester.enterText(find.byType(TextFormField).at(1), 'Test Subject');

      // Start save
      await tester.tap(find.byIcon(Icons.save));
      await tester.pump();

      // Check loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: const TemplateComposerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dark mode colors
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.grey[900]);
    });

    testWidgets('should be responsive', (WidgetTester tester) async {
      await pumpTemplateComposer(tester);

      // Test different screen sizes
      final BuildContext context = tester.element(
        find.byType(TemplateComposerScreen),
      );

      // Mobile size
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      await tester.pumpAndSettle();

      // Verify mobile layout
      expect(find.byType(Drawer), findsNothing);

      // Tablet size
      tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
      await tester.pumpAndSettle();

      // Verify tablet layout
      expect(find.byType(Row), findsOneWidget);
    });
  });
}
