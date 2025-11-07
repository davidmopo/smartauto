/// Email provider types
enum EmailProvider { smtp, sendgrid, mailgun, resend, mock }

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
enum EmailSecurity { none, ssl, tls }

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
