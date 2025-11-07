import 'package:flutter_test/flutter_test.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:sanitize_html/sanitize_html.dart';
import 'package:smartautomailer/models/email_template.dart';
import 'package:smartautomailer/services/template_service.dart';

void main() {
  group('Template Security Tests', () {
    late TemplateService templateService;
    final htmlUnescape = HtmlUnescape();

    setUp(() {
      templateService = TemplateService();
    });

    test('Prevents XSS in template content', () {
      final maliciousContent = '''
        <script>alert('xss')</script>
        <img src="x" onerror="alert('xss')">
        <a href="javascript:alert('xss')">Click me</a>
      ''';

      final sanitized = sanitizeHtml(maliciousContent);

      expect(sanitized, isNot(contains('<script>')));
      expect(sanitized, isNot(contains('onerror')));
      expect(sanitized, isNot(contains('javascript:')));
    });

    test('Validates variable syntax', () {
      const validVariables = ['{{firstName}}', '{{lastName}}', '{{email}}'];

      const invalidVariables = [
        '{firstName}',
        '{{first name}}',
        '{{123}}',
        '{{script}}',
        '{{alert()}}',
      ];

      for (final variable in validVariables) {
        expect(EmailTemplate.isValidVariable(variable), isTrue);
      }

      for (final variable in invalidVariables) {
        expect(EmailTemplate.isValidVariable(variable), isFalse);
      }
    });

    test('Sanitizes template name and description', () {
      final maliciousTemplate = EmailTemplate(
        id: 'test',
        userId: 'user123',
        name: '<script>alert("xss")</script>Template',
        subject: 'Normal Subject',
        htmlBody: 'Normal Body',
        category: TemplateCategory.general,
        tags: [],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: '<img src="x" onerror="alert(1)">Description',
      );

      final sanitized = maliciousTemplate.sanitized();

      expect(sanitized.name, isNot(contains('<script>')));
      expect(sanitized.description, isNot(contains('onerror')));
    });

    test('Prevents SQL injection in template fields', () {
      final maliciousQueries = [
        "'; DROP TABLE templates; --",
        "' OR '1'='1",
        "); DELETE FROM templates; --",
      ];

      for (final query in maliciousQueries) {
        final template = EmailTemplate(
          id: 'test',
          userId: 'user123',
          name: query,
          subject: 'Subject',
          htmlBody: 'Body',
          category: TemplateCategory.general,
          tags: [],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          () => templateService.createTemplate(template),
          throwsA(isA<TemplateServiceException>()),
        );
      }
    });

    test('Validates file upload MIME types', () {
      const allowedTypes = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'application/pdf',
      ];

      const disallowedTypes = [
        'application/javascript',
        'application/x-msdownload',
        'application/x-httpd-php',
        'application/octet-stream',
      ];

      for (final type in allowedTypes) {
        expect(TemplateService.isAllowedFileType(type), isTrue);
      }

      for (final type in disallowedTypes) {
        expect(TemplateService.isAllowedFileType(type), isFalse);
      }
    });

    test('Prevents template data exfiltration', () {
      const sensitiveData = [
        'API_KEY',
        'SECRET_KEY',
        'PASSWORD',
        'CREDENTIALS',
      ];

      final template = EmailTemplate(
        id: 'test',
        userId: 'user123',
        name: 'Test Template',
        subject: 'Test Subject',
        htmlBody: 'Test Body',
        category: TemplateCategory.general,
        tags: [],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final serialized = template.toFirestore();

      for (final key in sensitiveData) {
        expect(serialized.toString(), isNot(contains(key)));
      }
    });

    test('Rate limits template creation', () async {
      const maxTemplatesPerMinute = 10;
      int createdCount = 0;

      // Try to create templates rapidly
      for (int i = 0; i < maxTemplatesPerMinute + 5; i++) {
        try {
          await templateService.createTemplate(
            EmailTemplate(
              id: 'test$i',
              userId: 'user123',
              name: 'Template $i',
              subject: 'Subject',
              htmlBody: 'Body',
              category: TemplateCategory.general,
              tags: [],
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          createdCount++;
        } catch (e) {
          // Rate limit reached
          break;
        }
      }

      expect(createdCount, lessThanOrEqualTo(maxTemplatesPerMinute));
    });
  });
}
