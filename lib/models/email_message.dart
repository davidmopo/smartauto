import 'package:equatable/equatable.dart';

/// Email message model for sending emails
class EmailMessage extends Equatable {
  final String to;
  final String? toName;
  final String from;
  final String? fromName;
  final String subject;
  final String htmlBody;
  final String? plainTextBody;
  final List<String>? cc;
  final List<String>? bcc;
  final String? replyTo;
  final Map<String, String>? headers;
  final List<EmailAttachment>? attachments;
  final Map<String, dynamic>? metadata;

  const EmailMessage({
    required this.to,
    this.toName,
    required this.from,
    this.fromName,
    required this.subject,
    required this.htmlBody,
    this.plainTextBody,
    this.cc,
    this.bcc,
    this.replyTo,
    this.headers,
    this.attachments,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        to,
        toName,
        from,
        fromName,
        subject,
        htmlBody,
        plainTextBody,
        cc,
        bcc,
        replyTo,
        headers,
        attachments,
        metadata,
      ];

  EmailMessage copyWith({
    String? to,
    String? toName,
    String? from,
    String? fromName,
    String? subject,
    String? htmlBody,
    String? plainTextBody,
    List<String>? cc,
    List<String>? bcc,
    String? replyTo,
    Map<String, String>? headers,
    List<EmailAttachment>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return EmailMessage(
      to: to ?? this.to,
      toName: toName ?? this.toName,
      from: from ?? this.from,
      fromName: fromName ?? this.fromName,
      subject: subject ?? this.subject,
      htmlBody: htmlBody ?? this.htmlBody,
      plainTextBody: plainTextBody ?? this.plainTextBody,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      replyTo: replyTo ?? this.replyTo,
      headers: headers ?? this.headers,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'to': to,
      'to_name': toName,
      'from': from,
      'from_name': fromName,
      'subject': subject,
      'html_body': htmlBody,
      'plain_text_body': plainTextBody,
      'cc': cc,
      'bcc': bcc,
      'reply_to': replyTo,
      'headers': headers,
      'attachments': attachments?.map((a) => a.toJson()).toList(),
      'metadata': metadata,
    };
  }
}

/// Email attachment model
class EmailAttachment extends Equatable {
  final String filename;
  final String content; // Base64 encoded content
  final String contentType;
  final String? contentId; // For inline images

  const EmailAttachment({
    required this.filename,
    required this.content,
    required this.contentType,
    this.contentId,
  });

  @override
  List<Object?> get props => [filename, content, contentType, contentId];

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'content': content,
      'content_type': contentType,
      'content_id': contentId,
    };
  }
}

/// Email send result
class EmailSendResult extends Equatable {
  final bool success;
  final String? messageId;
  final String? error;
  final Map<String, dynamic>? metadata;

  const EmailSendResult({
    required this.success,
    this.messageId,
    this.error,
    this.metadata,
  });

  @override
  List<Object?> get props => [success, messageId, error, metadata];

  factory EmailSendResult.success({
    required String messageId,
    Map<String, dynamic>? metadata,
  }) {
    return EmailSendResult(
      success: true,
      messageId: messageId,
      metadata: metadata,
    );
  }

  factory EmailSendResult.failure({
    required String error,
    Map<String, dynamic>? metadata,
  }) {
    return EmailSendResult(
      success: false,
      error: error,
      metadata: metadata,
    );
  }
}

/// Email service provider type
enum EmailProvider {
  smtp,
  sendgrid,
  mailgun,
  awsSes,
  resend,
  mock; // For testing

  String get displayName {
    switch (this) {
      case EmailProvider.smtp:
        return 'SMTP';
      case EmailProvider.sendgrid:
        return 'SendGrid';
      case EmailProvider.mailgun:
        return 'Mailgun';
      case EmailProvider.awsSes:
        return 'AWS SES';
      case EmailProvider.resend:
        return 'Resend';
      case EmailProvider.mock:
        return 'Mock (Testing)';
    }
  }
}

/// Email service configuration
class EmailServiceConfig extends Equatable {
  final EmailProvider provider;
  final String? smtpHost;
  final int? smtpPort;
  final String? smtpUsername;
  final String? smtpPassword;
  final bool? smtpUseSsl;
  final String? apiKey;
  final String? apiSecret;
  final String? domain;
  final String defaultFromEmail;
  final String? defaultFromName;

  const EmailServiceConfig({
    required this.provider,
    this.smtpHost,
    this.smtpPort,
    this.smtpUsername,
    this.smtpPassword,
    this.smtpUseSsl,
    this.apiKey,
    this.apiSecret,
    this.domain,
    required this.defaultFromEmail,
    this.defaultFromName,
  });

  @override
  List<Object?> get props => [
        provider,
        smtpHost,
        smtpPort,
        smtpUsername,
        smtpPassword,
        smtpUseSsl,
        apiKey,
        apiSecret,
        domain,
        defaultFromEmail,
        defaultFromName,
      ];

  /// Create SMTP configuration
  factory EmailServiceConfig.smtp({
    required String host,
    required int port,
    required String username,
    required String password,
    bool useSsl = true,
    required String defaultFromEmail,
    String? defaultFromName,
  }) {
    return EmailServiceConfig(
      provider: EmailProvider.smtp,
      smtpHost: host,
      smtpPort: port,
      smtpUsername: username,
      smtpPassword: password,
      smtpUseSsl: useSsl,
      defaultFromEmail: defaultFromEmail,
      defaultFromName: defaultFromName,
    );
  }

  /// Create SendGrid configuration
  factory EmailServiceConfig.sendgrid({
    required String apiKey,
    required String defaultFromEmail,
    String? defaultFromName,
  }) {
    return EmailServiceConfig(
      provider: EmailProvider.sendgrid,
      apiKey: apiKey,
      defaultFromEmail: defaultFromEmail,
      defaultFromName: defaultFromName,
    );
  }

  /// Create Mailgun configuration
  factory EmailServiceConfig.mailgun({
    required String apiKey,
    required String domain,
    required String defaultFromEmail,
    String? defaultFromName,
  }) {
    return EmailServiceConfig(
      provider: EmailProvider.mailgun,
      apiKey: apiKey,
      domain: domain,
      defaultFromEmail: defaultFromEmail,
      defaultFromName: defaultFromName,
    );
  }

  /// Create Resend configuration
  factory EmailServiceConfig.resend({
    required String apiKey,
    required String defaultFromEmail,
    String? defaultFromName,
  }) {
    return EmailServiceConfig(
      provider: EmailProvider.resend,
      apiKey: apiKey,
      defaultFromEmail: defaultFromEmail,
      defaultFromName: defaultFromName,
    );
  }

  /// Create mock configuration for testing
  factory EmailServiceConfig.mock({
    required String defaultFromEmail,
    String? defaultFromName,
  }) {
    return EmailServiceConfig(
      provider: EmailProvider.mock,
      defaultFromEmail: defaultFromEmail,
      defaultFromName: defaultFromName,
    );
  }
}

