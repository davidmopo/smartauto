import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:smartautomailer/services/template_service.dart';
import 'package:smartautomailer/providers/auth_provider.dart';
import 'package:smartautomailer/models/email_template.dart';
import '../mocks/mock_providers.dart';

void main() {
  group('Template Security Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockTemplateService mockTemplateService;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockTemplateService = MockTemplateService();
    });

    test('Should prevent XSS attacks', () {
      final maliciousContent = '''
        <script>alert('xss')</script>
        <img src="x" onerror="alert('xss')">
        javascript:alert('xss')
        data:text/html,<script>alert('xss')</script>
      ''';

      final template = EmailTemplate(
        id: '1',
        userId: 'user1',
        name: 'Test Template',
        subject: 'Test Subject',
        htmlBody: maliciousContent,
        plainTextBody: maliciousContent,
        variables: [],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final sanitizedHtml = template.sanitizedHtmlBody;

      // Verify script tags are removed
      expect(sanitizedHtml.contains('<script>'), isFalse);

      // Verify event handlers are removed
      expect(sanitizedHtml.contains('onerror='), isFalse);

      // Verify javascript: protocols are removed
      expect(sanitizedHtml.contains('javascript:'), isFalse);

      // Verify data: URLs are removed
      expect(sanitizedHtml.contains('data:text/html'), isFalse);
    });

    test('Should prevent SQL injection', () {
      final maliciousName = "'; DROP TABLE templates; --";
      final maliciousContent = "'; DELETE FROM templates WHERE 1=1; --";

      final template = EmailTemplate(
        id: '1',
        userId: 'user1',
        name: maliciousName,
        subject: 'Test Subject',
        htmlBody: maliciousContent,
        plainTextBody: maliciousContent,
        variables: [],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Verify Firestore sanitization (mock the service call)
      when(
        mockTemplateService.createTemplate(template),
      ).thenAnswer((_) async => template);

      expect(template.name, isNot(contains("'")));
      expect(template.name, isNot(contains(";")));
      expect(template.htmlBody, isNot(contains("'")));
      expect(template.htmlBody, isNot(contains(";")));
    });

    test('Should enforce authentication', () async {
      // Mock unauthenticated state
      when(mockAuthProvider.isAuthenticated).thenReturn(false);

      try {
        await mockTemplateService.createTemplate(
          EmailTemplate(
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
          ),
        );
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), contains('not authenticated'));
      }
    });

    test('Should prevent unauthorized access', () async {
      // Mock different user
      when(mockAuthProvider.user?.uid).thenReturn('user2');

      final template = EmailTemplate(
        id: '1',
        userId: 'user1', // Different user
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

      try {
        await mockTemplateService.updateTemplate(template);
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), contains('unauthorized'));
      }
    });

    test('Should validate input lengths', () {
      final longString = 'a' * 1001; // Exceed 1000 char limit

      final template = EmailTemplate(
        id: '1',
        userId: 'user1',
        name: longString,
        subject: longString,
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
      expect(template.hasValidSubject(), isFalse);
    });

    test('Should sanitize HTML attributes', () {
      final maliciousHtml = '''
        <a href="javascript:alert('xss')">Link</a>
        <img src="data:image/svg+xml,<svg onload='alert(1)'>">
        <div style="background-image: url('javascript:alert(1)')">
        <form action="javascript:alert('xss')">
      ''';

      final template = EmailTemplate(
        id: '1',
        userId: 'user1',
        name: 'Test Template',
        subject: 'Test Subject',
        htmlBody: maliciousHtml,
        plainTextBody: maliciousHtml,
        variables: [],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final sanitizedHtml = template.sanitizedHtmlBody;

      // Verify javascript: URLs are removed
      expect(sanitizedHtml.contains('javascript:'), isFalse);

      // Verify data: URLs are removed
      expect(sanitizedHtml.contains('data:'), isFalse);

      // Verify event handlers are removed
      expect(sanitizedHtml.contains('onload='), isFalse);
    });

    test('Should prevent template parameter injection', () {
      final maliciousVariable = '{{constructor.constructor("alert(1)")()}}';

      final template = EmailTemplate(
        id: '1',
        userId: 'user1',
        name: 'Test Template',
        subject: 'Test Subject',
        htmlBody: 'Hello $maliciousVariable',
        plainTextBody: 'Hello $maliciousVariable',
        variables: [],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(template.hasValidVariableSyntax(), isFalse);
    });
  });
}
