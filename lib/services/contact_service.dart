import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact.dart';
import '../models/contact_list.dart';

/// Service for managing contacts in Firestore
class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _contactsCollection =>
      _firestore.collection('contacts');
  CollectionReference get _listsCollection =>
      _firestore.collection('contact_lists');

  /// Create a new contact
  Future<Contact> createContact(Contact contact) async {
    try {
      final docRef = await _contactsCollection.add(contact.toFirestore());
      final doc = await docRef.get();
      return Contact.fromFirestore(doc);
    } catch (e) {
      throw ContactServiceException('Failed to create contact: $e');
    }
  }

  /// Get a single contact by ID
  Future<Contact?> getContact(String contactId) async {
    try {
      final doc = await _contactsCollection.doc(contactId).get();
      if (!doc.exists) return null;
      return Contact.fromFirestore(doc);
    } catch (e) {
      throw ContactServiceException('Failed to get contact: $e');
    }
  }

  /// Get all contacts for a user
  Future<List<Contact>> getContacts(String userId, {
    int? limit,
    DocumentSnapshot? startAfter,
    String? searchQuery,
    VerificationStatus? status,
    List<String>? tags,
    String? listId,
  }) async {
    try {
      Query query = _contactsCollection.where('user_id', isEqualTo: userId);

      // Apply filters
      if (status != null) {
        query = query.where('verification_status', isEqualTo: status.name);
      }

      if (tags != null && tags.isNotEmpty) {
        query = query.where('tags', arrayContainsAny: tags);
      }

      if (listId != null) {
        query = query.where('lists', arrayContains: listId);
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      // Order by created date
      query = query.orderBy('created_at', descending: true);

      final snapshot = await query.get();
      List<Contact> contacts = snapshot.docs
          .map((doc) => Contact.fromFirestore(doc))
          .toList();

      // Apply search filter (client-side for now)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        contacts = contacts.where((contact) {
          return contact.email.toLowerCase().contains(lowerQuery) ||
              (contact.firstName?.toLowerCase().contains(lowerQuery) ?? false) ||
              (contact.lastName?.toLowerCase().contains(lowerQuery) ?? false) ||
              (contact.company?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }

      return contacts;
    } catch (e) {
      throw ContactServiceException('Failed to get contacts: $e');
    }
  }

  /// Update a contact
  Future<void> updateContact(String contactId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = Timestamp.now();
      await _contactsCollection.doc(contactId).update(updates);
    } catch (e) {
      throw ContactServiceException('Failed to update contact: $e');
    }
  }

  /// Delete a contact
  Future<void> deleteContact(String contactId) async {
    try {
      await _contactsCollection.doc(contactId).delete();
    } catch (e) {
      throw ContactServiceException('Failed to delete contact: $e');
    }
  }

  /// Bulk delete contacts
  Future<void> bulkDeleteContacts(List<String> contactIds) async {
    try {
      final batch = _firestore.batch();
      for (final id in contactIds) {
        batch.delete(_contactsCollection.doc(id));
      }
      await batch.commit();
    } catch (e) {
      throw ContactServiceException('Failed to bulk delete contacts: $e');
    }
  }

  /// Import contacts from list
  Future<List<Contact>> importContacts(
    String userId,
    List<Map<String, dynamic>> contactsData,
  ) async {
    try {
      final batch = _firestore.batch();
      final List<Contact> contacts = [];
      final now = DateTime.now();

      for (final data in contactsData) {
        final contact = Contact(
          id: '', // Will be set by Firestore
          userId: userId,
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
          tags: List<String>.from(data['tags'] ?? []),
          lists: List<String>.from(data['lists'] ?? []),
          createdAt: now,
          updatedAt: now,
        );

        final docRef = _contactsCollection.doc();
        batch.set(docRef, contact.toFirestore());
        contacts.add(contact.copyWith(id: docRef.id));
      }

      await batch.commit();
      return contacts;
    } catch (e) {
      throw ContactServiceException('Failed to import contacts: $e');
    }
  }

  /// Check if email exists
  Future<bool> emailExists(String userId, String email) async {
    try {
      final snapshot = await _contactsCollection
          .where('user_id', isEqualTo: userId)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw ContactServiceException('Failed to check email: $e');
    }
  }

  /// Get contact count for user
  Future<int> getContactCount(String userId) async {
    try {
      final snapshot = await _contactsCollection
          .where('user_id', isEqualTo: userId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw ContactServiceException('Failed to get contact count: $e');
    }
  }

  // ==================== Contact List Methods ====================

  /// Create a new contact list
  Future<ContactList> createContactList(ContactList list) async {
    try {
      final docRef = await _listsCollection.add(list.toFirestore());
      final doc = await docRef.get();
      return ContactList.fromFirestore(doc);
    } catch (e) {
      throw ContactServiceException('Failed to create contact list: $e');
    }
  }

  /// Get all contact lists for a user
  Future<List<ContactList>> getContactLists(String userId) async {
    try {
      final snapshot = await _listsCollection
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ContactList.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ContactServiceException('Failed to get contact lists: $e');
    }
  }

  /// Update a contact list
  Future<void> updateContactList(
    String listId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = Timestamp.now();
      await _listsCollection.doc(listId).update(updates);
    } catch (e) {
      throw ContactServiceException('Failed to update contact list: $e');
    }
  }

  /// Delete a contact list
  Future<void> deleteContactList(String listId) async {
    try {
      // Remove list from all contacts
      final contacts = await _contactsCollection
          .where('lists', arrayContains: listId)
          .get();

      final batch = _firestore.batch();
      for (final doc in contacts.docs) {
        batch.update(doc.reference, {
          'lists': FieldValue.arrayRemove([listId]),
        });
      }

      // Delete the list
      batch.delete(_listsCollection.doc(listId));
      await batch.commit();
    } catch (e) {
      throw ContactServiceException('Failed to delete contact list: $e');
    }
  }

  /// Add contacts to a list
  Future<void> addContactsToList(String listId, List<String> contactIds) async {
    try {
      final batch = _firestore.batch();
      for (final contactId in contactIds) {
        batch.update(_contactsCollection.doc(contactId), {
          'lists': FieldValue.arrayUnion([listId]),
        });
      }
      await batch.commit();

      // Update list contact count
      await _updateListContactCount(listId);
    } catch (e) {
      throw ContactServiceException('Failed to add contacts to list: $e');
    }
  }

  /// Remove contacts from a list
  Future<void> removeContactsFromList(
    String listId,
    List<String> contactIds,
  ) async {
    try {
      final batch = _firestore.batch();
      for (final contactId in contactIds) {
        batch.update(_contactsCollection.doc(contactId), {
          'lists': FieldValue.arrayRemove([listId]),
        });
      }
      await batch.commit();

      // Update list contact count
      await _updateListContactCount(listId);
    } catch (e) {
      throw ContactServiceException('Failed to remove contacts from list: $e');
    }
  }

  /// Update contact count for a list
  Future<void> _updateListContactCount(String listId) async {
    final count = await _contactsCollection
        .where('lists', arrayContains: listId)
        .count()
        .get();

    await _listsCollection.doc(listId).update({
      'contact_count': count.count ?? 0,
      'updated_at': Timestamp.now(),
    });
  }
}

/// Custom exception for contact service errors
class ContactServiceException implements Exception {
  final String message;

  ContactServiceException(this.message);

  @override
  String toString() => 'ContactServiceException: $message';
}

