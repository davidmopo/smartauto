import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campaign.dart';
import '../models/campaign_recipient.dart';
import '../models/contact.dart';
import '../models/email_template.dart';

/// Custom exception for campaign service errors
class CampaignServiceException implements Exception {
  final String message;
  CampaignServiceException(this.message);

  @override
  String toString() => message;
}

/// Service for managing email campaigns
class CampaignService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _campaignsCollection =>
      _firestore.collection('campaigns');
  CollectionReference get _recipientsCollection =>
      _firestore.collection('campaign_recipients');
  CollectionReference get _contactsCollection =>
      _firestore.collection('contacts');

  /// Create a new campaign
  Future<Campaign> createCampaign(Campaign campaign) async {
    try {
      final docRef = await _campaignsCollection.add(campaign.toFirestore());
      return campaign.copyWith(id: docRef.id);
    } catch (e) {
      throw CampaignServiceException('Failed to create campaign: $e');
    }
  }

  /// Get campaign by ID
  Future<Campaign?> getCampaign(String campaignId) async {
    try {
      final doc = await _campaignsCollection.doc(campaignId).get();
      if (!doc.exists) return null;
      return Campaign.fromFirestore(doc);
    } catch (e) {
      throw CampaignServiceException('Failed to get campaign: $e');
    }
  }

  /// Get all campaigns for a user
  Future<List<Campaign>> getCampaigns(
    String userId, {
    CampaignStatus? status,
    CampaignType? type,
    String? searchQuery,
    int? limit,
  }) async {
    try {
      Query query = _campaignsCollection.where('user_id', isEqualTo: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      query = query.orderBy('created_at', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      List<Campaign> campaigns = snapshot.docs
          .map((doc) => Campaign.fromFirestore(doc))
          .toList();

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        campaigns = campaigns.where((campaign) {
          return campaign.name.toLowerCase().contains(lowerQuery) ||
              (campaign.description?.toLowerCase().contains(lowerQuery) ??
                  false);
        }).toList();
      }

      return campaigns;
    } catch (e) {
      throw CampaignServiceException('Failed to get campaigns: $e');
    }
  }

  /// Update campaign
  Future<void> updateCampaign(Campaign campaign) async {
    try {
      await _campaignsCollection
          .doc(campaign.id)
          .update(campaign.toFirestore());
    } catch (e) {
      throw CampaignServiceException('Failed to update campaign: $e');
    }
  }

  /// Delete campaign
  Future<void> deleteCampaign(String campaignId) async {
    try {
      // Delete all recipients first
      final recipientsSnapshot = await _recipientsCollection
          .where('campaign_id', isEqualTo: campaignId)
          .get();

      final batch = _firestore.batch();
      for (var doc in recipientsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete campaign
      batch.delete(_campaignsCollection.doc(campaignId));

      await batch.commit();
    } catch (e) {
      throw CampaignServiceException('Failed to delete campaign: $e');
    }
  }

  /// Duplicate campaign
  Future<Campaign> duplicateCampaign(String campaignId, String userId) async {
    try {
      final original = await getCampaign(campaignId);
      if (original == null) {
        throw CampaignServiceException('Campaign not found');
      }

      final now = DateTime.now();
      final duplicate = original.copyWith(
        id: '',
        name: '${original.name} (Copy)',
        status: CampaignStatus.draft,
        scheduledAt: null,
        startedAt: null,
        completedAt: null,
        sentCount: 0,
        deliveredCount: 0,
        openedCount: 0,
        clickedCount: 0,
        repliedCount: 0,
        bouncedCount: 0,
        unsubscribedCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      return await createCampaign(duplicate);
    } catch (e) {
      throw CampaignServiceException('Failed to duplicate campaign: $e');
    }
  }

  /// Get recipients for a campaign
  Future<List<CampaignRecipient>> getCampaignRecipients(
    String campaignId, {
    EmailStatus? status,
    int? limit,
  }) async {
    try {
      Query query = _recipientsCollection.where(
        'campaign_id',
        isEqualTo: campaignId,
      );

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('created_at', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CampaignRecipient.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw CampaignServiceException('Failed to get campaign recipients: $e');
    }
  }

  /// Prepare campaign recipients (create recipient records)
  Future<void> prepareCampaignRecipients(
    Campaign campaign,
    EmailTemplate template,
  ) async {
    try {
      // Get all contacts from contact IDs and contact lists
      final contacts = await _getContactsForCampaign(campaign);

      if (contacts.isEmpty) {
        throw CampaignServiceException('No contacts found for campaign');
      }

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (var contact in contacts) {
        // Replace variables in subject and body
        final variables = {
          'firstName': contact.firstName ?? '',
          'lastName': contact.lastName ?? '',
          'fullName': contact.fullName,
          'email': contact.email,
          'company': contact.company ?? '',
          'position': contact.position ?? '',
          'website': contact.website ?? '',
        };

        final subject = EmailTemplate.replaceVariables(
          campaign.customSubject ?? template.subject,
          variables,
        );

        final body = EmailTemplate.replaceVariables(
          campaign.customBody ?? template.htmlBody,
          variables,
        );

        final recipient = CampaignRecipient(
          id: '',
          campaignId: campaign.id,
          userId: campaign.userId,
          contactId: contact.id,
          email: contact.email,
          firstName: contact.firstName,
          lastName: contact.lastName,
          company: contact.company,
          subject: subject,
          body: body,
          stepNumber: 0,
          status: EmailStatus.pending,
          scheduledAt: campaign.scheduledAt,
          createdAt: now,
          updatedAt: now,
        );

        final docRef = _recipientsCollection.doc();
        batch.set(docRef, recipient.toFirestore());
      }

      // Update campaign total recipients
      batch.update(_campaignsCollection.doc(campaign.id), {
        'total_recipients': contacts.length,
        'updated_at': Timestamp.fromDate(now),
      });

      await batch.commit();
    } catch (e) {
      throw CampaignServiceException(
        'Failed to prepare campaign recipients: $e',
      );
    }
  }

  /// Get contacts for campaign (from contact IDs and lists)
  Future<List<Contact>> _getContactsForCampaign(Campaign campaign) async {
    final Set<String> contactIds = {};
    final List<Contact> contacts = [];

    // Add direct contact IDs
    contactIds.addAll(campaign.contactIds);

    // Get contacts from contact lists
    // Note: Contacts have a 'lists' field that contains list IDs
    // We need to query contacts where 'lists' array contains the list ID
    for (var listId in campaign.contactListIds) {
      final listContactsQuery = await _contactsCollection
          .where('user_id', isEqualTo: campaign.userId)
          .where('lists', arrayContains: listId)
          .get();

      for (var doc in listContactsQuery.docs) {
        contactIds.add(doc.id);
      }
    }

    // Fetch all contacts
    for (var contactId in contactIds) {
      final contactDoc = await _contactsCollection.doc(contactId).get();
      if (contactDoc.exists) {
        contacts.add(Contact.fromFirestore(contactDoc));
      }
    }

    return contacts;
  }

  /// Update campaign status
  Future<void> updateCampaignStatus(
    String campaignId,
    CampaignStatus status,
  ) async {
    try {
      final now = DateTime.now();
      final updates = <String, dynamic>{
        'status': status.name,
        'updated_at': Timestamp.fromDate(now),
      };

      if (status == CampaignStatus.sending) {
        updates['started_at'] = Timestamp.fromDate(now);
      } else if (status == CampaignStatus.completed) {
        updates['completed_at'] = Timestamp.fromDate(now);
      }

      await _campaignsCollection.doc(campaignId).update(updates);
    } catch (e) {
      throw CampaignServiceException('Failed to update campaign status: $e');
    }
  }

  /// Update campaign metrics
  Future<void> updateCampaignMetrics(String campaignId) async {
    try {
      final recipients = await getCampaignRecipients(campaignId);

      final sentCount = recipients.where((r) => r.sentAt != null).length;
      final deliveredCount = recipients
          .where((r) => r.deliveredAt != null)
          .length;
      final openedCount = recipients.where((r) => r.openedAt != null).length;
      final clickedCount = recipients.where((r) => r.clickedAt != null).length;
      final repliedCount = recipients.where((r) => r.repliedAt != null).length;
      final bouncedCount = recipients.where((r) => r.bouncedAt != null).length;
      final unsubscribedCount = recipients
          .where((r) => r.unsubscribedAt != null)
          .length;

      await _campaignsCollection.doc(campaignId).update({
        'sent_count': sentCount,
        'delivered_count': deliveredCount,
        'opened_count': openedCount,
        'clicked_count': clickedCount,
        'replied_count': repliedCount,
        'bounced_count': bouncedCount,
        'unsubscribed_count': unsubscribedCount,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw CampaignServiceException('Failed to update campaign metrics: $e');
    }
  }
}
