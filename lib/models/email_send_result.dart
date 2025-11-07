/// Result of an email send operation
class EmailSendResult {
  final bool success;
  final String? messageId;
  final String? error;
  final Map<String, dynamic>? metadata;

  EmailSendResult._({
    required this.success,
    this.messageId,
    this.error,
    this.metadata,
  });

  factory EmailSendResult.success({
    required String messageId,
    Map<String, dynamic>? metadata,
  }) {
    return EmailSendResult._(
      success: true,
      messageId: messageId,
      metadata: metadata,
    );
  }

  factory EmailSendResult.failure({
    required String error,
    Map<String, dynamic>? metadata,
  }) {
    return EmailSendResult._(success: false, error: error, metadata: metadata);
  }
}
