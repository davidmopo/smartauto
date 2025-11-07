import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Contact model representing a person in the contact list
class Contact extends Equatable {
  final String id;
  final String userId;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? company;
  final String? position;
  final String? phone;
  final String? location;
  final String? website;
  final String? linkedinUrl;
  final String? twitterHandle;
  final Map<String, dynamic> customFields;
  final VerificationStatus verificationStatus;
  final int verificationScore;
  final List<String> tags;
  final List<String> lists;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastEmailedAt;
  final DateTime? lastOpenedAt;
  final DateTime? lastClickedAt;
  final int emailsSent;
  final int emailsOpened;
  final int emailsClicked;
  final bool isUnsubscribed;
  final bool isBounced;

  const Contact({
    required this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    required this.email,
    this.company,
    this.position,
    this.phone,
    this.location,
    this.website,
    this.linkedinUrl,
    this.twitterHandle,
    this.customFields = const {},
    this.verificationStatus = VerificationStatus.pending,
    this.verificationScore = 0,
    this.tags = const [],
    this.lists = const [],
    required this.createdAt,
    required this.updatedAt,
    this.lastEmailedAt,
    this.lastOpenedAt,
    this.lastClickedAt,
    this.emailsSent = 0,
    this.emailsOpened = 0,
    this.emailsClicked = 0,
    this.isUnsubscribed = false,
    this.isBounced = false,
  });

  /// Get full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return email;
  }

  /// Get initials for avatar
  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    } else if (firstName != null) {
      return firstName![0].toUpperCase();
    } else if (lastName != null) {
      return lastName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  /// Calculate engagement score
  double get engagementScore {
    if (emailsSent == 0) return 0;
    return ((emailsOpened * 1 + emailsClicked * 3) / emailsSent) * 100;
  }

  /// Check if contact is active
  bool get isActive {
    return !isUnsubscribed && !isBounced;
  }

  /// Create a copy with updated fields
  Contact copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? company,
    String? position,
    String? phone,
    String? location,
    String? website,
    String? linkedinUrl,
    String? twitterHandle,
    Map<String, dynamic>? customFields,
    VerificationStatus? verificationStatus,
    int? verificationScore,
    List<String>? tags,
    List<String>? lists,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastEmailedAt,
    DateTime? lastOpenedAt,
    DateTime? lastClickedAt,
    int? emailsSent,
    int? emailsOpened,
    int? emailsClicked,
    bool? isUnsubscribed,
    bool? isBounced,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      company: company ?? this.company,
      position: position ?? this.position,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      website: website ?? this.website,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      twitterHandle: twitterHandle ?? this.twitterHandle,
      customFields: customFields ?? this.customFields,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationScore: verificationScore ?? this.verificationScore,
      tags: tags ?? this.tags,
      lists: lists ?? this.lists,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastEmailedAt: lastEmailedAt ?? this.lastEmailedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      lastClickedAt: lastClickedAt ?? this.lastClickedAt,
      emailsSent: emailsSent ?? this.emailsSent,
      emailsOpened: emailsOpened ?? this.emailsOpened,
      emailsClicked: emailsClicked ?? this.emailsClicked,
      isUnsubscribed: isUnsubscribed ?? this.isUnsubscribed,
      isBounced: isBounced ?? this.isBounced,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'company': company,
      'position': position,
      'phone': phone,
      'location': location,
      'website': website,
      'linkedin_url': linkedinUrl,
      'twitter_handle': twitterHandle,
      'custom_fields': customFields,
      'verification_status': verificationStatus.name,
      'verification_score': verificationScore,
      'tags': tags,
      'lists': lists,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'last_emailed_at': lastEmailedAt != null ? Timestamp.fromDate(lastEmailedAt!) : null,
      'last_opened_at': lastOpenedAt != null ? Timestamp.fromDate(lastOpenedAt!) : null,
      'last_clicked_at': lastClickedAt != null ? Timestamp.fromDate(lastClickedAt!) : null,
      'emails_sent': emailsSent,
      'emails_opened': emailsOpened,
      'emails_clicked': emailsClicked,
      'is_unsubscribed': isUnsubscribed,
      'is_bounced': isBounced,
    };
  }

  /// Create from Firestore document
  factory Contact.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Contact(
      id: doc.id,
      userId: data['user_id'] ?? '',
      firstName: data['first_name'],
      lastName: data['last_name'],
      email: data['email'] ?? '',
      company: data['company'],
      position: data['position'],
      phone: data['phone'],
      location: data['location'],
      website: data['website'],
      linkedinUrl: data['linkedin_url'],
      twitterHandle: data['twitter_handle'],
      customFields: Map<String, dynamic>.from(data['custom_fields'] ?? {}),
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == data['verification_status'],
        orElse: () => VerificationStatus.pending,
      ),
      verificationScore: data['verification_score'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      lists: List<String>.from(data['lists'] ?? []),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      lastEmailedAt: data['last_emailed_at'] != null
          ? (data['last_emailed_at'] as Timestamp).toDate()
          : null,
      lastOpenedAt: data['last_opened_at'] != null
          ? (data['last_opened_at'] as Timestamp).toDate()
          : null,
      lastClickedAt: data['last_clicked_at'] != null
          ? (data['last_clicked_at'] as Timestamp).toDate()
          : null,
      emailsSent: data['emails_sent'] ?? 0,
      emailsOpened: data['emails_opened'] ?? 0,
      emailsClicked: data['emails_clicked'] ?? 0,
      isUnsubscribed: data['is_unsubscribed'] ?? false,
      isBounced: data['is_bounced'] ?? false,
    );
  }

  /// Create from JSON
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'] ?? '',
      company: json['company'],
      position: json['position'],
      phone: json['phone'],
      location: json['location'],
      website: json['website'],
      linkedinUrl: json['linkedin_url'],
      twitterHandle: json['twitter_handle'],
      customFields: Map<String, dynamic>.from(json['custom_fields'] ?? {}),
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == json['verification_status'],
        orElse: () => VerificationStatus.pending,
      ),
      verificationScore: json['verification_score'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      lists: List<String>.from(json['lists'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastEmailedAt: json['last_emailed_at'] != null
          ? DateTime.parse(json['last_emailed_at'])
          : null,
      lastOpenedAt: json['last_opened_at'] != null
          ? DateTime.parse(json['last_opened_at'])
          : null,
      lastClickedAt: json['last_clicked_at'] != null
          ? DateTime.parse(json['last_clicked_at'])
          : null,
      emailsSent: json['emails_sent'] ?? 0,
      emailsOpened: json['emails_opened'] ?? 0,
      emailsClicked: json['emails_clicked'] ?? 0,
      isUnsubscribed: json['is_unsubscribed'] ?? false,
      isBounced: json['is_bounced'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, email];
}

/// Email verification status enum
enum VerificationStatus {
  pending,
  verified,
  invalid,
  risky,
  unknown,
}

