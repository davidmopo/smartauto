import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class for Hunter.io API integration
/// Provides email finding and verification functionality
class HunterService {
  // Hunter.io API configuration
  static const String _baseUrl = 'https://api.hunter.io/v2';
  final String _apiKey;

  HunterService({required String apiKey}) : _apiKey = apiKey;

  /// Find email address by name and company domain
  ///
  /// Parameters:
  /// - [firstName]: First name of the person
  /// - [lastName]: Last name of the person
  /// - [domain]: Company domain (e.g., 'google.com')
  ///
  /// Returns: Map containing email and confidence score
  Future<EmailFinderResult> findEmail({
    required String firstName,
    required String lastName,
    required String domain,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/email-finder').replace(
        queryParameters: {
          'domain': domain,
          'first_name': firstName,
          'last_name': lastName,
          'api_key': _apiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EmailFinderResult.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw HunterException('Invalid API key');
      } else if (response.statusCode == 429) {
        throw HunterException('API rate limit exceeded');
      } else {
        final error = json.decode(response.body);
        throw HunterException(
          error['errors']?[0]?['details'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      if (e is HunterException) rethrow;
      throw HunterException('Failed to find email: $e');
    }
  }

  /// Verify email address deliverability
  ///
  /// Parameters:
  /// - [email]: Email address to verify
  ///
  /// Returns: EmailVerificationResult with status and score
  Future<EmailVerificationResult> verifyEmail(String email) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/email-verifier',
      ).replace(queryParameters: {'email': email, 'api_key': _apiKey});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EmailVerificationResult.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw HunterException('Invalid API key');
      } else if (response.statusCode == 429) {
        throw HunterException('API rate limit exceeded');
      } else {
        final error = json.decode(response.body);
        throw HunterException(
          error['errors']?[0]?['details'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      if (e is HunterException) rethrow;
      throw HunterException('Failed to verify email: $e');
    }
  }

  /// Get domain search results
  ///
  /// Parameters:
  /// - [domain]: Company domain to search
  /// - [limit]: Maximum number of results (default: 10)
  ///
  /// Returns: List of emails found for the domain
  Future<DomainSearchResult> searchDomain({
    required String domain,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/domain-search').replace(
        queryParameters: {
          'domain': domain,
          'limit': limit.toString(),
          'offset': offset.toString(),
          'api_key': _apiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DomainSearchResult.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw HunterException('Invalid API key');
      } else if (response.statusCode == 429) {
        throw HunterException('API rate limit exceeded');
      } else {
        final error = json.decode(response.body);
        throw HunterException(
          error['errors']?[0]?['details'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      if (e is HunterException) rethrow;
      throw HunterException('Failed to search domain: $e');
    }
  }

  /// Get account information (remaining requests, etc.)
  Future<AccountInfo> getAccountInfo() async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/account',
      ).replace(queryParameters: {'api_key': _apiKey});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AccountInfo.fromJson(data['data']);
      } else {
        throw HunterException('Failed to get account info');
      }
    } catch (e) {
      if (e is HunterException) rethrow;
      throw HunterException('Failed to get account info: $e');
    }
  }
}

/// Result from email finder API
class EmailFinderResult {
  final String? email;
  final String? firstName;
  final String? lastName;
  final int? score;
  final String? position;
  final String? department;
  final List<EmailSource> sources;

  EmailFinderResult({
    this.email,
    this.firstName,
    this.lastName,
    this.score,
    this.position,
    this.department,
    this.sources = const [],
  });

  factory EmailFinderResult.fromJson(Map<String, dynamic> json) {
    return EmailFinderResult(
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      score: json['score'],
      position: json['position'],
      department: json['department'],
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((s) => EmailSource.fromJson(s))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'score': score,
      'position': position,
      'department': department,
      'sources': sources.map((s) => s.toJson()).toList(),
    };
  }
}

/// Email source information
class EmailSource {
  final String? domain;
  final String? uri;
  final String? extractedOn;
  final String? lastSeenOn;
  final bool? stillOnPage;

  EmailSource({
    this.domain,
    this.uri,
    this.extractedOn,
    this.lastSeenOn,
    this.stillOnPage,
  });

  factory EmailSource.fromJson(Map<String, dynamic> json) {
    return EmailSource(
      domain: json['domain'],
      uri: json['uri'],
      extractedOn: json['extracted_on'],
      lastSeenOn: json['last_seen_on'],
      stillOnPage: json['still_on_page'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'uri': uri,
      'extracted_on': extractedOn,
      'last_seen_on': lastSeenOn,
      'still_on_page': stillOnPage,
    };
  }
}

/// Result from email verification API
class EmailVerificationResult {
  final String email;
  final String
  status; // valid, invalid, accept_all, webmail, disposable, unknown
  final int score; // 0-100
  final bool regexp;
  final bool gibberish;
  final bool disposable;
  final bool webmail;
  final bool mxRecords;
  final bool smtpServer;
  final bool smtpCheck;
  final bool acceptAll;
  final bool block;

  EmailVerificationResult({
    required this.email,
    required this.status,
    required this.score,
    required this.regexp,
    required this.gibberish,
    required this.disposable,
    required this.webmail,
    required this.mxRecords,
    required this.smtpServer,
    required this.smtpCheck,
    required this.acceptAll,
    required this.block,
  });

  factory EmailVerificationResult.fromJson(Map<String, dynamic> json) {
    return EmailVerificationResult(
      email: json['email'] ?? '',
      status: json['status'] ?? 'unknown',
      score: json['score'] ?? 0,
      regexp: json['regexp'] ?? false,
      gibberish: json['gibberish'] ?? false,
      disposable: json['disposable'] ?? false,
      webmail: json['webmail'] ?? false,
      mxRecords: json['mx_records'] ?? false,
      smtpServer: json['smtp_server'] ?? false,
      smtpCheck: json['smtp_check'] ?? false,
      acceptAll: json['accept_all'] ?? false,
      block: json['block'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'status': status,
      'score': score,
      'regexp': regexp,
      'gibberish': gibberish,
      'disposable': disposable,
      'webmail': webmail,
      'mx_records': mxRecords,
      'smtp_server': smtpServer,
      'smtp_check': smtpCheck,
      'accept_all': acceptAll,
      'block': block,
    };
  }

  /// Get human-readable status message
  String get statusMessage {
    switch (status) {
      case 'valid':
        return 'Valid - Email is deliverable';
      case 'invalid':
        return 'Invalid - Email does not exist';
      case 'accept_all':
        return 'Accept All - Server accepts all emails';
      case 'webmail':
        return 'Webmail - Personal email address';
      case 'disposable':
        return 'Disposable - Temporary email address';
      default:
        return 'Unknown - Unable to verify';
    }
  }
}

/// Result from domain search API
class DomainSearchResult {
  final String domain;
  final bool disposable;
  final bool webmail;
  final int emailsCount;
  final List<DomainEmail> emails;
  final String? pattern;

  DomainSearchResult({
    required this.domain,
    required this.disposable,
    required this.webmail,
    required this.emailsCount,
    required this.emails,
    this.pattern,
  });

  factory DomainSearchResult.fromJson(Map<String, dynamic> json) {
    return DomainSearchResult(
      domain: json['domain'] ?? '',
      disposable: json['disposable'] ?? false,
      webmail: json['webmail'] ?? false,
      emailsCount: json['emails'] ?? 0,
      emails:
          (json['emails'] as List<dynamic>?)
              ?.map((e) => DomainEmail.fromJson(e))
              .toList() ??
          [],
      pattern: json['pattern'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'disposable': disposable,
      'webmail': webmail,
      'emails': emailsCount,
      'emails_list': emails.map((e) => e.toJson()).toList(),
      'pattern': pattern,
    };
  }
}

/// Email found in domain search
class DomainEmail {
  final String email;
  final String? firstName;
  final String? lastName;
  final String? position;
  final String? department;
  final int? confidence;
  final String? linkedinUrl;
  final String? twitterHandle;
  final String? phoneNumber;

  DomainEmail({
    required this.email,
    this.firstName,
    this.lastName,
    this.position,
    this.department,
    this.confidence,
    this.linkedinUrl,
    this.twitterHandle,
    this.phoneNumber,
  });

  factory DomainEmail.fromJson(Map<String, dynamic> json) {
    return DomainEmail(
      email: json['value'] ?? json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      position: json['position'],
      department: json['department'],
      confidence: json['confidence'],
      linkedinUrl: json['linkedin'],
      twitterHandle: json['twitter'],
      phoneNumber: json['phone_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'position': position,
      'department': department,
      'confidence': confidence,
      'linkedin': linkedinUrl,
      'twitter': twitterHandle,
      'phone_number': phoneNumber,
    };
  }
}

/// Hunter.io account information
class AccountInfo {
  final String? email;
  final String? firstName;
  final String? lastName;
  final int requestsAvailable;
  final int requestsUsed;
  final String? planName;
  final String? planLevel;
  final String? resetDate;

  AccountInfo({
    this.email,
    this.firstName,
    this.lastName,
    required this.requestsAvailable,
    required this.requestsUsed,
    this.planName,
    this.planLevel,
    this.resetDate,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      requestsAvailable: json['requests']?['searches']?['available'] ?? 0,
      requestsUsed: json['requests']?['searches']?['used'] ?? 0,
      planName: json['plan_name'],
      planLevel: json['plan_level'],
      resetDate: json['reset_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'requests_available': requestsAvailable,
      'requests_used': requestsUsed,
      'plan_name': planName,
      'plan_level': planLevel,
      'reset_date': resetDate,
    };
  }

  int get totalRequests => requestsAvailable + requestsUsed;
  double get usagePercentage =>
      totalRequests > 0 ? (requestsUsed / totalRequests) * 100 : 0;
}

/// Custom exception for Hunter.io API errors
class HunterException implements Exception {
  final String message;

  HunterException(this.message);

  @override
  String toString() => 'HunterException: $message';
}
