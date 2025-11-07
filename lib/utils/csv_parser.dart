import 'package:csv/csv.dart';

/// Utility class for parsing CSV files
class CsvParser {
  /// Parse CSV file content
  /// 
  /// Returns a list of maps where each map represents a row
  /// with column headers as keys
  static Future<List<Map<String, dynamic>>> parseCsv(String csvContent) async {
    try {
      // Convert CSV to list of lists
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
        csvContent,
        eol: '\n',
        shouldParseNumbers: false,
      );

      if (rows.isEmpty) {
        throw CsvParseException('CSV file is empty');
      }

      // First row is headers
      final List<String> headers = rows[0].map((e) => e.toString().trim()).toList();

      // Validate headers
      if (headers.isEmpty) {
        throw CsvParseException('CSV file has no headers');
      }

      // Parse data rows
      final List<Map<String, dynamic>> data = [];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
          continue; // Skip empty rows
        }

        final Map<String, dynamic> rowData = {};
        for (int j = 0; j < headers.length; j++) {
          final value = j < row.length ? row[j]?.toString().trim() : '';
          rowData[headers[j]] = value;
        }
        data.add(rowData);
      }

      return data;
    } catch (e) {
      if (e is CsvParseException) rethrow;
      throw CsvParseException('Failed to parse CSV: $e');
    }
  }

  /// Detect column mappings from CSV headers
  /// 
  /// Maps common column names to standard contact fields
  static Map<String, String> detectColumnMappings(List<String> headers) {
    final Map<String, String> mappings = {};

    for (final header in headers) {
      final lowerHeader = header.toLowerCase().trim();

      // Email
      if (lowerHeader.contains('email') || lowerHeader == 'e-mail') {
        mappings[header] = 'email';
      }
      // First Name
      else if (lowerHeader.contains('first') && lowerHeader.contains('name') ||
          lowerHeader == 'firstname' ||
          lowerHeader == 'fname') {
        mappings[header] = 'first_name';
      }
      // Last Name
      else if (lowerHeader.contains('last') && lowerHeader.contains('name') ||
          lowerHeader == 'lastname' ||
          lowerHeader == 'lname' ||
          lowerHeader == 'surname') {
        mappings[header] = 'last_name';
      }
      // Full Name
      else if (lowerHeader == 'name' || lowerHeader == 'full name') {
        mappings[header] = 'full_name';
      }
      // Company
      else if (lowerHeader.contains('company') ||
          lowerHeader.contains('organization') ||
          lowerHeader.contains('organisation')) {
        mappings[header] = 'company';
      }
      // Position/Title
      else if (lowerHeader.contains('position') ||
          lowerHeader.contains('title') ||
          lowerHeader.contains('job') ||
          lowerHeader.contains('role')) {
        mappings[header] = 'position';
      }
      // Phone
      else if (lowerHeader.contains('phone') ||
          lowerHeader.contains('mobile') ||
          lowerHeader.contains('tel')) {
        mappings[header] = 'phone';
      }
      // Location
      else if (lowerHeader.contains('location') ||
          lowerHeader.contains('city') ||
          lowerHeader.contains('country') ||
          lowerHeader.contains('address')) {
        mappings[header] = 'location';
      }
      // Website
      else if (lowerHeader.contains('website') ||
          lowerHeader.contains('url') ||
          lowerHeader.contains('site')) {
        mappings[header] = 'website';
      }
      // LinkedIn
      else if (lowerHeader.contains('linkedin')) {
        mappings[header] = 'linkedin_url';
      }
      // Twitter
      else if (lowerHeader.contains('twitter')) {
        mappings[header] = 'twitter_handle';
      }
      // Tags
      else if (lowerHeader.contains('tag')) {
        mappings[header] = 'tags';
      }
      // Custom field
      else {
        mappings[header] = 'custom_$header';
      }
    }

    return mappings;
  }

  /// Apply column mappings to parsed data
  /// 
  /// Converts raw CSV data to contact-ready format
  static List<Map<String, dynamic>> applyMappings(
    List<Map<String, dynamic>> data,
    Map<String, String> mappings,
  ) {
    final List<Map<String, dynamic>> mappedData = [];

    for (final row in data) {
      final Map<String, dynamic> contact = {
        'custom_fields': <String, dynamic>{},
        'tags': <String>[],
        'lists': <String>[],
      };

      for (final entry in row.entries) {
        final csvColumn = entry.key;
        final value = entry.value;

        if (value == null || value.toString().trim().isEmpty) {
          continue;
        }

        final mappedField = mappings[csvColumn];
        if (mappedField == null) continue;

        // Handle special cases
        if (mappedField == 'full_name') {
          // Split full name into first and last
          final parts = value.toString().split(' ');
          if (parts.isNotEmpty) {
            contact['first_name'] = parts.first;
            if (parts.length > 1) {
              contact['last_name'] = parts.sublist(1).join(' ');
            }
          }
        } else if (mappedField == 'tags') {
          // Parse tags (comma-separated)
          final tags = value.toString().split(',').map((t) => t.trim()).toList();
          contact['tags'] = tags;
        } else if (mappedField.startsWith('custom_')) {
          // Add to custom fields
          final fieldName = mappedField.substring(7);
          contact['custom_fields'][fieldName] = value;
        } else {
          // Standard field
          contact[mappedField] = value;
        }
      }

      // Validate required fields
      if (contact['email'] != null && contact['email'].toString().isNotEmpty) {
        mappedData.add(contact);
      }
    }

    return mappedData;
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Detect and remove duplicates
  static List<Map<String, dynamic>> removeDuplicates(
    List<Map<String, dynamic>> data,
  ) {
    final Set<String> seenEmails = {};
    final List<Map<String, dynamic>> unique = [];

    for (final contact in data) {
      final email = contact['email']?.toString().toLowerCase();
      if (email != null && !seenEmails.contains(email)) {
        seenEmails.add(email);
        unique.add(contact);
      }
    }

    return unique;
  }

  /// Validate contact data
  static ContactValidationResult validateContacts(
    List<Map<String, dynamic>> contacts,
  ) {
    int valid = 0;
    int invalid = 0;
    final List<String> errors = [];

    for (int i = 0; i < contacts.length; i++) {
      final contact = contacts[i];
      final email = contact['email']?.toString();

      if (email == null || email.isEmpty) {
        invalid++;
        errors.add('Row ${i + 1}: Missing email address');
      } else if (!isValidEmail(email)) {
        invalid++;
        errors.add('Row ${i + 1}: Invalid email format: $email');
      } else {
        valid++;
      }
    }

    return ContactValidationResult(
      valid: valid,
      invalid: invalid,
      total: contacts.length,
      errors: errors,
    );
  }
}

/// Result of contact validation
class ContactValidationResult {
  final int valid;
  final int invalid;
  final int total;
  final List<String> errors;

  ContactValidationResult({
    required this.valid,
    required this.invalid,
    required this.total,
    required this.errors,
  });

  bool get hasErrors => invalid > 0;
  double get validPercentage => total > 0 ? (valid / total) * 100 : 0;
}

/// Custom exception for CSV parsing errors
class CsvParseException implements Exception {
  final String message;

  CsvParseException(this.message);

  @override
  String toString() => 'CsvParseException: $message';
}

