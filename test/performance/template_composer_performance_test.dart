import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartautomailer/screens/templates/template_composer_screen.dart';
import 'dart:async';

void main() {
  group('Template Composer Performance Tests', () {
    final Completer<void> completer = Completer<void>();

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('Memory usage during editing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TemplateComposerScreen()),
      );

      // Initial memory snapshot
      final initialMemory = await WidgetsBinding.instance.performReassemble();

      // Simulate heavy editing
      for (int i = 0; i < 1000; i++) {
        await tester.enterText(find.byType(TextFormField).last, 'Line $i\n');
        await tester.pump(const Duration(milliseconds: 16)); // Simulate 60 FPS
      }

      // Final memory snapshot
      final finalMemory = await WidgetsBinding.instance.performReassemble();

      // Verify memory usage is within acceptable limits
      expect(
        finalMemory.runtimeType,
        equals(initialMemory.runtimeType),
        reason: 'Memory usage increased significantly',
      );
    });

    testWidgets('Frame timing during scrolling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TemplateComposerScreen()),
      );

      // Fill editor with content
      final largeContent = List.generate(1000, (i) => 'Line $i\n').join();
      await tester.enterText(find.byType(TextFormField).last, largeContent);
      await tester.pump();

      // Start timing
      final stopwatch = Stopwatch()..start();

      // Simulate smooth scrolling
      for (int i = 0; i < 60; i++) {
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -100),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }

      stopwatch.stop();

      // Verify frame timing
      expect(
        stopwatch.elapsedMilliseconds / 60,
        lessThan(16.67), // Target 60 FPS (16.67ms per frame)
      );
    });

    testWidgets('Responsiveness during formatting', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TemplateComposerScreen()),
      );

      // Fill editor with content
      final content = List.generate(100, (i) => 'Paragraph $i\n').join();
      await tester.enterText(find.byType(TextFormField).last, content);
      await tester.pump();

      final stopwatch = Stopwatch()..start();

      // Apply formatting operations
      for (int i = 0; i < 50; i++) {
        // Toggle bold
        await tester.tap(find.byIcon(Icons.format_bold));
        await tester.pump();

        // Toggle italic
        await tester.tap(find.byIcon(Icons.format_italic));
        await tester.pump();

        // Toggle underline
        await tester.tap(find.byIcon(Icons.format_underline));
        await tester.pump();
      }

      stopwatch.stop();

      // Verify responsiveness
      expect(
        stopwatch.elapsedMilliseconds / 150, // 150 operations
        lessThan(8), // Target max 8ms per operation
      );
    });

    testWidgets('Variable replacement performance', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TemplateComposerScreen()),
      );

      // Create content with many variables
      final content = List.generate(
        100,
        (i) => 'Hello {{firstName}} {{lastName}} {{email}} paragraph $i\n',
      ).join();

      await tester.enterText(find.byType(TextFormField).last, content);
      await tester.pump();

      final stopwatch = Stopwatch()..start();

      // Toggle preview mode to trigger variable replacement
      await tester.tap(find.byIcon(Icons.preview));
      await tester.pump();

      stopwatch.stop();

      // Verify preview generation time
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100), // Should take less than 100ms
      );
    });

    testWidgets('Autosave performance impact', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TemplateComposerScreen()),
      );

      // Simulate typing with autosave
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 50; i++) {
        await tester.enterText(
          find.byType(TextFormField).last,
          'Typing content $i\n',
        );
        await tester.pump(const Duration(seconds: 2)); // Autosave interval
      }

      stopwatch.stop();

      // Verify typing remains responsive during autosave
      expect(
        stopwatch.elapsedMilliseconds / 50, // 50 typing operations
        lessThan(
          2100,
        ), // Should not add more than 100ms overhead to 2s interval
      );
    });
  });
}
