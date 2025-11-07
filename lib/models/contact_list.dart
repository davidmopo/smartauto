import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ContactList model representing a collection of contacts
class ContactList extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final int contactCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? color;
  final bool isDefault;

  const ContactList({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.contactCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.color,
    this.isDefault = false,
  });

  /// Create a copy with updated fields
  ContactList copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    int? contactCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? color,
    bool? isDefault,
  }) {
    return ContactList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      contactCount: contactCount ?? this.contactCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'description': description,
      'contact_count': contactCount,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'color': color,
      'is_default': isDefault,
    };
  }

  /// Create from Firestore document
  factory ContactList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContactList(
      id: doc.id,
      userId: data['user_id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      contactCount: data['contact_count'] ?? 0,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      tags: List<String>.from(data['tags'] ?? []),
      color: data['color'],
      isDefault: data['is_default'] ?? false,
    );
  }

  /// Create from JSON
  factory ContactList.fromJson(Map<String, dynamic> json) {
    return ContactList(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      contactCount: json['contact_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      tags: List<String>.from(json['tags'] ?? []),
      color: json['color'],
      isDefault: json['is_default'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'contact_count': contactCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'tags': tags,
      'color': color,
      'is_default': isDefault,
    };
  }

  @override
  List<Object?> get props => [id, name];
}

