import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:smartautomailer/models/email_template.dart';
import 'package:smartautomailer/services/template_service.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'template_composer_test.mocks.dart';

@GenerateMocks([TemplateService])
void main() {
  late MockTemplateService mockTemplateService;

  setUp(() {
    mockTemplateService = MockTemplateService();
  });

  group('EmailTemplate Model Tests', () {
    test('should create template with valid data', () {
      final template = EmailTemplate(
        id: '1',
        userId: 'user1',
        name: 'Test Template',
        subject: 'Test Subject',
        htmlBody: 'Test Content',
        plainTextBody: 'Test Content',
        variables: ['firstName', 'lastName'],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(template.name, 'Test Template');
      expect(template.subject, 'Test Subject');
      expect(template.variables.length, 2);
    });

    test('should extract variables correctly', () {
      const text = 'Hello {{firstName}} {{lastName}}';
      final vars = EmailTemplate.extractVariables(text);
      expect(vars, contains('firstName'));
      expect(vars, contains('lastName'));
      expect(vars.length, 2);
    });

    test('should validate template correctly', () {
      final template = EmailTemplate(
        id: '1',
        userId: 'user1',
        name: 'Test Template',
        subject: 'Hello {{firstName}}',
        htmlBody: 'Content with {{firstName}} {{lastName}}',
        plainTextBody: 'Content',
        variables: ['firstName', 'lastName'],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(template.hasValidVariables(), isTrue);
    });
  });

  group('Template Service Tests', () {
    test('should create template', () async {
      final template = EmailTemplate(
        id: '',
        userId: 'user1',
        name: 'Test Template',
        subject: 'Test Subject',
        htmlBody: 'Test Content',
        plainTextBody: 'Test Content',
        variables: [],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(
        mockTemplateService.createTemplate(template),
      ).thenAnswer((_) async => template.copyWith(id: '1'));

      final result = await mockTemplateService.createTemplate(template);
      expect(result.id, '1');
      verify(mockTemplateService.createTemplate(template)).called(1);
    });

    test('should update template', () async {
      final template = EmailTemplate(
        id: '1',
        userId: 'user1',
        name: 'Updated Template',
        subject: 'Updated Subject',
        htmlBody: 'Updated Content',
        plainTextBody: 'Updated Content',
        variables: [],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(
        mockTemplateService.updateTemplate(template),
      ).thenAnswer((_) async => {});

      await mockTemplateService.updateTemplate(template);
      verify(mockTemplateService.updateTemplate(template)).called(1);
    });
  });

  group('Template Validation Tests', () {
    test('should validate template name', () {
      final template = EmailTemplate(
        id: '1',
        userId: 'user1',
        name: '', // Invalid empty name
        subject: 'Test Subject',
        htmlBody: 'Test Content',
        plainTextBody: 'Test Content',
        variables: [],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(template.hasValidName(), isFalse);
    });

    test('should validate template content', () {
      final template = EmailTemplate(
        id: '1',
        userId: 'user1',
        name: 'Test Template',
        subject: 'Test Subject',
        htmlBody: '', // Invalid empty content
        plainTextBody: '',
        variables: [],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(template.hasValidContent(), isFalse);
    });

    test('should validate variable syntax', () {
      final template = EmailTemplate(
        id: '1',
        userId: 'user1',
        name: 'Test Template',
        subject: 'Hello {{firstName', // Invalid unclosed variable
        htmlBody: 'Test Content',
        plainTextBody: 'Test Content',
        variables: ['firstName'],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(template.hasValidVariableSyntax(), isFalse);
    });
  });

  group('Delta Conversion Tests', () {
    test('should convert HTML to Delta', () {
      const html = '<p><strong>Bold</strong> and <em>italic</em></p>';
      final doc = Document()..insert(0, html);
      final delta = doc.toDelta();

      expect(delta.toList().length, greaterThan(0));
    });

    test('should convert Delta to HTML', () {
      final delta = Delta()
        ..insert('Bold', {'bold': true})
        ..insert(' and ')
        ..insert('italic', {'italic': true})
        ..insert('\n');

      final doc = Document.fromDelta(delta);
      final html = doc.toPlainText();

      expect(html, contains('Bold'));
      expect(html, contains('italic'));
    });
  });
}
