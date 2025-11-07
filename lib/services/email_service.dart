import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart' hide Address;
import 'package:mailer/smtp_server.dart';
import '../models/email_message.dart';
import '../models/email_event.dart';
import '../models/email_send_result.dart';
import 'email_service_config.dart';

/// Email service for sending emails through various providers
class EmailService {
  final EmailServiceConfig config;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EmailService({required this.config});

  /// Send an email message
  Future<EmailSendResult> sendEmail(EmailMessage message) async {
    try {
      // Validate message
      _validateMessage(message);

      // Send based on provider
      EmailSendResult result;
      switch (config.provider) {
        case EmailProvider.smtp:
          result = await _sendViaSMTP(message);
          break;
        case EmailProvider.sendgrid:
          result = await _sendViaSendGrid(message);
          break;
        case EmailProvider.mailgun:
          result = await _sendViaMailgun(message);
          break;
        case EmailProvider.resend:
          result = await _sendViaResend(message);
          break;
        case EmailProvider.mock:
          result = await _sendViaMock(message);
          break;
        default:
          throw EmailServiceException(
            'Provider ${config.provider.displayName} not implemented',
          );
      }

      // Track email event if successful
      if (result.success && result.messageId != null) {
        await _trackEmailEvent(
          messageId: result.messageId!,
          email: message.to,
          eventType: EmailEventType.sent,
          metadata: message.metadata,
        );
      }

      return result;
    } catch (e) {
      if (e is EmailServiceException) rethrow;
      throw EmailServiceException('Failed to send email: $e');
    }
  }

  /// Send email via SMTP
  Future<EmailSendResult> _sendViaSMTP(EmailMessage message) async {
    if (config.smtpHost == null || config.smtpPort == null || config.username == null || config.password == null) {
      throw EmailServiceException('SMTP configuration is incomplete');
    }

    try {
      // Configure SMTP server
      SmtpServer smtpServer;
      
      // Handle different SMTP security options
      if (config.security == EmailSecurity.ssl) {
        smtpServer = SmtpServer(
          config.smtpHost!,
          port: config.smtpPort!,
          username: config.username!,
          password: config.password!,
          ssl: true,
        );
      } else if (config.security == EmailSecurity.tls) {
        smtpServer = SmtpServer(
          config.smtpHost!,
          port: config.smtpPort!,
          username: config.username!,
          password: config.password!,
          allowInsecure: false,
          ignoreBadCertificate: false,
        );
      } else {
        smtpServer = SmtpServer(
          config.smtpHost!,
          port: config.smtpPort!,
          username: config.username!,
          password: config.password!,
        );
      }

      // Create the email message
      final mailerMessage = Message()
        ..from = Address(message.from, message.fromName)
        ..recipients.add(Address(message.to, message.toName))
        ..ccRecipients.addAll(message.cc?.map((e) => Address(e)) ?? [])
        ..bccRecipients.addAll(message.bcc?.map((e) => Address(e)) ?? [])
        ..subject = message.subject
        ..html = message.htmlBody;

      if (message.plainTextBody != null) {
        mailerMessage.text = message.plainTextBody;
      }

      if (message.replyTo != null) {
        mailerMessage.replyTo = message.replyTo!;
      }

      if (message.headers != null) {
        mailerMessage.headers.addAll(message.headers!);
      }

      // Send the message
      final sendReport = await send(mailerMessage, smtpServer);

      // Generate a message ID if one wasn't provided by the SMTP server
      final messageId = sendReport.messagePaths.isNotEmpty ? 
        sendReport.messagePaths.first : 
        'smtp_${DateTime.now().millisecondsSinceEpoch}';

      return EmailSendResult.success(
        messageId: messageId,
        metadata: {
          'provider': 'smtp',
          'smtp_host': config.smtpHost,
          'smtp_port': config.smtpPort,
        },
      );
    } catch (e) {
      return EmailSendResult.failure(error: 'SMTP error: $e');
    }
  }

  /// Send email via SendGrid
  Future<EmailSendResult> _sendViaSendGrid(EmailMessage message) async {
    if (config.apiKey == null) {
      throw EmailServiceException('SendGrid API key not configured');
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [
                {
                  'email': message.to,
                  if (message.toName != null) 'name': message.toName,
                }
              ],
              if (message.cc != null && message.cc!.isNotEmpty)
                'cc': message.cc!.map((e) => {'email': e}).toList(),
              if (message.bcc != null && message.bcc!.isNotEmpty)
                'bcc': message.bcc!.map((e) => {'email': e}).toList(),
            }
          ],
          'from': {
            'email': message.from,
            if (message.fromName != null) 'name': message.fromName,
          },
          'subject': message.subject,
          'content': [
            {
              'type': 'text/html',
              'value': message.htmlBody,
            },
            if (message.plainTextBody != null)
              {
                'type': 'text/plain',
                'value': message.plainTextBody,
              },
          ],
          if (message.replyTo != null)
            'reply_to': {'email': message.replyTo},
          if (message.headers != null) 'headers': message.headers,
          if (message.metadata != null)
            'custom_args': message.metadata,
        }),
      );

      if (response.statusCode == 202) {
        // SendGrid returns message ID in X-Message-Id header
        final messageId = response.headers['x-message-id'] ??
            DateTime.now().millisecondsSinceEpoch.toString();
        return EmailSendResult.success(
          messageId: messageId,
          metadata: {'provider': 'sendgrid'},
        );
      } else {
        final error = jsonDecode(response.body);
        return EmailSendResult.failure(
          error: error['errors']?[0]?['message'] ?? 'Unknown error',
          metadata: {'status_code': response.statusCode},
        );
      }
    } catch (e) {
      return EmailSendResult.failure(error: 'SendGrid error: $e');
    }
  }

  /// Send email via Mailgun
  Future<EmailSendResult> _sendViaMailgun(EmailMessage message) async {
    if (config.apiKey == null || config.domain == null) {
      throw EmailServiceException('Mailgun API key and domain not configured');
    }

    try {
      final auth = base64Encode(utf8.encode('api:${config.apiKey}'));
      final response = await http.post(
        Uri.parse('https://api.mailgun.net/v3/${config.domain}/messages'),
        headers: {
          'Authorization': 'Basic $auth',
        },
        body: {
          'from': message.fromName != null
              ? '${message.fromName} <${message.from}>'
              : message.from,
          'to': message.toName != null
              ? '${message.toName} <${message.to}>'
              : message.to,
          'subject': message.subject,
          'html': message.htmlBody,
          if (message.plainTextBody != null) 'text': message.plainTextBody,
          if (message.cc != null && message.cc!.isNotEmpty)
            'cc': message.cc!.join(','),
          if (message.bcc != null && message.bcc!.isNotEmpty)
            'bcc': message.bcc!.join(','),
          if (message.replyTo != null) 'h:Reply-To': message.replyTo!,
          if (message.metadata != null)
            ...message.metadata!.map((k, v) => MapEntry('v:$k', v.toString())),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EmailSendResult.success(
          messageId: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          metadata: {'provider': 'mailgun'},
        );
      } else {
        final error = jsonDecode(response.body);
        return EmailSendResult.failure(
          error: error['message'] ?? 'Unknown error',
          metadata: {'status_code': response.statusCode},
        );
      }
    } catch (e) {
      return EmailSendResult.failure(error: 'Mailgun error: $e');
    }
  }

  /// Send email via Resend
  Future<EmailSendResult> _sendViaResend(EmailMessage message) async {
    if (config.apiKey == null) {
      throw EmailServiceException('Resend API key not configured');
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': message.fromName != null
              ? '${message.fromName} <${message.from}>'
              : message.from,
          'to': [message.to],
          'subject': message.subject,
          'html': message.htmlBody,
          if (message.plainTextBody != null) 'text': message.plainTextBody,
          if (message.cc != null && message.cc!.isNotEmpty) 'cc': message.cc,
          if (message.bcc != null && message.bcc!.isNotEmpty) 'bcc': message.bcc,
          if (message.replyTo != null) 'reply_to': message.replyTo,
          if (message.headers != null) 'headers': message.headers,
          if (message.metadata != null) 'tags': message.metadata,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EmailSendResult.success(
          messageId: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          metadata: {'provider': 'resend'},
        );
      } else {
        final error = jsonDecode(response.body);
        return EmailSendResult.failure(
          error: error['message'] ?? 'Unknown error',
          metadata: {'status_code': response.statusCode},
        );
      }
    } catch (e) {
      return EmailSendResult.failure(error: 'Resend error: $e');
    }
  }

  /// Send email via mock provider (for testing)
  Future<EmailSendResult> _sendViaMock(EmailMessage message) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Generate mock message ID
    final messageId = 'mock_${DateTime.now().millisecondsSinceEpoch}';

    // Log the email (in production, you might save to a test collection)
    print('📧 MOCK EMAIL SENT:');
    print('  To: ${message.to} ${message.toName ?? ''}');
    print('  From: ${message.from} ${message.fromName ?? ''}');
    print('  Subject: ${message.subject}');
    print('  Message ID: $messageId');

    return EmailSendResult.success(
      messageId: messageId,
      metadata: {
        'provider': 'mock',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Validate email message
  void _validateMessage(EmailMessage message) {
    if (message.to.isEmpty) {
      throw EmailServiceException('Recipient email is required');
    }
    if (message.from.isEmpty) {
      throw EmailServiceException('Sender email is required');
    }
    if (message.subject.isEmpty) {
      throw EmailServiceException('Subject is required');
    }
    if (message.htmlBody.isEmpty && (message.plainTextBody?.isEmpty ?? true)) {
      throw EmailServiceException('Email body is required');
    }
  }

  /// Track email event in Firestore
  Future<void> _trackEmailEvent({
    required String messageId,
    required String email,
    required EmailEventType eventType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final event = EmailEvent(
        id: '',
        messageId: messageId,
        email: email,
        eventType: eventType,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _firestore.collection('email_events').add(event.toFirestore());
    } catch (e) {
      // Don't throw - tracking failure shouldn't fail the send
      print('Failed to track email event: $e');
    }
  }
}

  /// Email provider types
enum EmailProvider {
  smtp,
  sendgrid,
  mailgun,
  resend,
  mock,
}

extension EmailProviderName on EmailProvider {
  String get displayName {
    switch (this) {
      case EmailProvider.smtp:
        return 'SMTP';
      case EmailProvider.sendgrid:
        return 'SendGrid';
      case EmailProvider.mailgun:
        return 'Mailgun';
      case EmailProvider.resend:
        return 'Resend';
      case EmailProvider.mock:
        return 'Mock';
    }
  }
}

/// Email security types for SMTP
enum EmailSecurity {
  none,
  ssl,
  tls,
}

/// Email service configuration
class EmailServiceConfig {
  final EmailProvider provider;
  final String? apiKey;
  final String? domain;
  
  // SMTP specific configuration
  final String? smtpHost;
  final int? smtpPort;
  final String? username;
  final String? password;
  final EmailSecurity security;

  const EmailServiceConfig({
    required this.provider,
    this.apiKey,
    this.domain,
    this.smtpHost,
    this.smtpPort,
    this.username,
    this.password,
    this.security = EmailSecurity.tls,
  });
}

/// Send email via SMTP
  Future<EmailSendResult> _sendViaSMTP(EmailMessage message) async {
    if (config.smtpHost == null || config.smtpPort == null || config.username == null || config.password == null) {
      throw EmailServiceException('SMTP configuration is incomplete');
    }

    try {
      // Configure SMTP server
      SmtpServer smtpServer;
      
      // Handle different SMTP security options
      if (config.security == EmailSecurity.ssl) {
        smtpServer = SmtpServer(
          config.smtpHost!,
          port: config.smtpPort!,
          username: config.username,
          password: config.password,
          ssl: true,
        );
      } else if (config.security == EmailSecurity.tls) {
        smtpServer = SmtpServer(
          config.smtpHost!,
          port: config.smtpPort!,
          username: config.username,
          password: config.password,
          allowInsecure: false,
          ignoreBadCertificate: false,
        );
      } else {
        smtpServer = SmtpServer(
          config.smtpHost!,
          port: config.smtpPort!,
          username: config.username,
          password: config.password,
        );
      }

      // Create the email message
      final mailerMessage = Message()
        ..from = Address(message.from, message.fromName)
        ..recipients.add(Address(message.to, message.toName))
        ..ccRecipients.addAll(message.cc?.map((e) => Address(e)) ?? [])
        ..bccRecipients.addAll(message.bcc?.map((e) => Address(e)) ?? [])
        ..subject = message.subject
        ..html = message.htmlBody
        ..text = message.plainTextBody;

      if (message.replyTo != null) {
        mailerMessage.replyTo = message.replyTo!;
      }

      if (message.headers != null) {
        mailerMessage.headers.addAll(message.headers!);
      }

      // Send the message
      final sendReport = await send(mailerMessage, smtpServer);

      // Generate a message ID if one wasn't provided by the SMTP server
      final messageId = sendReport.messagePaths.isNotEmpty ? 
        sendReport.messagePaths.first : 
        'smtp_${DateTime.now().millisecondsSinceEpoch}';

      return EmailSendResult.success(
        messageId: messageId,
        metadata: {
          'provider': 'smtp',
          'smtp_host': config.smtpHost,
          'smtp_port': config.smtpPort,
        },
      );
    } catch (e) {
      return EmailSendResult.failure(error: 'SMTP error: $e');
    }
  }

  /// Send email via SendGrid
  Future<EmailSendResult> _sendViaSendGrid(EmailMessage message) async {
    if (config.apiKey == null) {
      throw EmailServiceException('SendGrid API key not configured');
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [
                {
                  'email': message.to,
                  if (message.toName != null) 'name': message.toName,
                }
              ],
              if (message.cc != null && message.cc!.isNotEmpty)
                'cc': message.cc!.map((e) => {'email': e}).toList(),
              if (message.bcc != null && message.bcc!.isNotEmpty)
                'bcc': message.bcc!.map((e) => {'email': e}).toList(),
            }
          ],
          'from': {
            'email': message.from,
            if (message.fromName != null) 'name': message.fromName,
          },
          'subject': message.subject,
          'content': [
            {
              'type': 'text/html',
              'value': message.htmlBody,
            },
            if (message.plainTextBody != null)
              {
                'type': 'text/plain',
                'value': message.plainTextBody,
              },
          ],
          if (message.replyTo != null)
            'reply_to': {'email': message.replyTo},
          if (message.headers != null) 'headers': message.headers,
          if (message.metadata != null)
            'custom_args': message.metadata,
        }),
      );

      if (response.statusCode == 202) {
        // SendGrid returns message ID in X-Message-Id header
        final messageId = response.headers['x-message-id'] ??
            DateTime.now().millisecondsSinceEpoch.toString();
        return EmailSendResult.success(
          messageId: messageId,
          metadata: {'provider': 'sendgrid'},
        );
      } else {
        final error = jsonDecode(response.body);
        return EmailSendResult.failure(
          error: error['errors']?[0]?['message'] ?? 'Unknown error',
          metadata: {'status_code': response.statusCode},
        );
      }
    } catch (e) {
      return EmailSendResult.failure(error: 'SendGrid error: $e');
    }
  }

  /// Send email via Mailgun
  Future<EmailSendResult> _sendViaMailgun(EmailMessage message) async {
    if (config.apiKey == null || config.domain == null) {
      throw EmailServiceException('Mailgun API key and domain not configured');
    }

    try {
      final auth = base64Encode(utf8.encode('api:${config.apiKey}'));
      final response = await http.post(
        Uri.parse('https://api.mailgun.net/v3/${config.domain}/messages'),
        headers: {
          'Authorization': 'Basic $auth',
        },
        body: {
          'from': message.fromName != null
              ? '${message.fromName} <${message.from}>'
              : message.from,
          'to': message.toName != null
              ? '${message.toName} <${message.to}>'
              : message.to,
          'subject': message.subject,
          'html': message.htmlBody,
          if (message.plainTextBody != null) 'text': message.plainTextBody,
          if (message.cc != null && message.cc!.isNotEmpty)
            'cc': message.cc!.join(','),
          if (message.bcc != null && message.bcc!.isNotEmpty)
            'bcc': message.bcc!.join(','),
          if (message.replyTo != null) 'h:Reply-To': message.replyTo!,
          if (message.metadata != null)
            ...message.metadata!.map((k, v) => MapEntry('v:$k', v.toString())),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EmailSendResult.success(
          messageId: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          metadata: {'provider': 'mailgun'},
        );
      } else {
        final error = jsonDecode(response.body);
        return EmailSendResult.failure(
          error: error['message'] ?? 'Unknown error',
          metadata: {'status_code': response.statusCode},
        );
      }
    } catch (e) {
      return EmailSendResult.failure(error: 'Mailgun error: $e');
    }
  }

  /// Send email via Resend
  Future<EmailSendResult> _sendViaResend(EmailMessage message) async {
    if (config.apiKey == null) {
      throw EmailServiceException('Resend API key not configured');
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': message.fromName != null
              ? '${message.fromName} <${message.from}>'
              : message.from,
          'to': [message.to],
          'subject': message.subject,
          'html': message.htmlBody,
          if (message.plainTextBody != null) 'text': message.plainTextBody,
          if (message.cc != null && message.cc!.isNotEmpty) 'cc': message.cc,
          if (message.bcc != null && message.bcc!.isNotEmpty) 'bcc': message.bcc,
          if (message.replyTo != null) 'reply_to': message.replyTo,
          if (message.headers != null) 'headers': message.headers,
          if (message.metadata != null) 'tags': message.metadata,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EmailSendResult.success(
          messageId: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          metadata: {'provider': 'resend'},
        );
      } else {
        final error = jsonDecode(response.body);
        return EmailSendResult.failure(
          error: error['message'] ?? 'Unknown error',
          metadata: {'status_code': response.statusCode},
        );
      }
    } catch (e) {
      return EmailSendResult.failure(error: 'Resend error: $e');
    }
  }

  /// Send email via mock provider (for testing)
  Future<EmailSendResult> _sendViaMock(EmailMessage message) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Generate mock message ID
    final messageId = 'mock_${DateTime.now().millisecondsSinceEpoch}';

    // Log the email (in production, you might save to a test collection)
    print('📧 MOCK EMAIL SENT:');
    print('  To: ${message.to} ${message.toName ?? ''}');
    print('  From: ${message.from} ${message.fromName ?? ''}');
    print('  Subject: ${message.subject}');
    print('  Message ID: $messageId');

    return EmailSendResult.success(
      messageId: messageId,
      metadata: {
        'provider': 'mock',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Validate email message
  void _validateMessage(EmailMessage message) {
    if (message.to.isEmpty) {
      throw EmailServiceException('Recipient email is required');
    }
    if (message.from.isEmpty) {
      throw EmailServiceException('Sender email is required');
    }
    if (message.subject.isEmpty) {
      throw EmailServiceException('Subject is required');
    }
    if (message.htmlBody.isEmpty && (message.plainTextBody?.isEmpty ?? true)) {
      throw EmailServiceException('Email body is required');
    }
  }

  /// Track email event in Firestore
  Future<void> _trackEmailEvent({
    required String messageId,
    required String email,
    required EmailEventType eventType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final event = EmailEvent(
        id: '',
        messageId: messageId,
        email: email,
        eventType: eventType,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _firestore.collection('email_events').add(event.toFirestore());
    } catch (e) {
      // Don't throw - tracking failure shouldn't fail the send
      print('Failed to track email event: $e');
    }
  }
}

/// Email service exception
class EmailServiceException implements Exception {
  final String message;

  EmailServiceException(this.message);

  @override
  String toString() => message;
}

