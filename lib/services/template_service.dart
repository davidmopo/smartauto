import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/email_template.dart';
import '../models/template_variant.dart';

/// Service for managing email templates
class TemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _templatesCollection =>
      _firestore.collection('email_templates');

  CollectionReference get _variantsCollection =>
      _firestore.collection('template_variants');

  CollectionReference get _versionsCollection =>
      _firestore.collection('template_versions');

  /// Create a new template
  Future<EmailTemplate> createTemplate(EmailTemplate template) async {
    try {
      final docRef = await _templatesCollection.add(template.toFirestore());
      final doc = await docRef.get();
      return EmailTemplate.fromFirestore(doc);
    } catch (e) {
      throw TemplateServiceException('Failed to create template: $e');
    }
  }

  /// Get a template by ID
  Future<EmailTemplate?> getTemplate(String templateId) async {
    try {
      final doc = await _templatesCollection.doc(templateId).get();
      if (!doc.exists) return null;
      return EmailTemplate.fromFirestore(doc);
    } catch (e) {
      throw TemplateServiceException('Failed to get template: $e');
    }
  }

  /// Get all templates for a user
  Future<List<EmailTemplate>> getTemplates(
    String userId, {
    TemplateCategory? category,
    bool? isActive,
    String? searchQuery,
    int? limit,
  }) async {
    try {
      Query query = _templatesCollection.where('user_id', isEqualTo: userId);

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      if (isActive != null) {
        query = query.where('is_active', isEqualTo: isActive);
      }

      query = query.orderBy('updated_at', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      List<EmailTemplate> templates = snapshot.docs
          .map((doc) => EmailTemplate.fromFirestore(doc))
          .toList();

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        templates = templates.where((template) {
          return template.name.toLowerCase().contains(lowerQuery) ||
              template.subject.toLowerCase().contains(lowerQuery) ||
              template.description?.toLowerCase().contains(lowerQuery) == true;
        }).toList();
      }

      return templates;
    } catch (e) {
      throw TemplateServiceException('Failed to get templates: $e');
    }
  }

  /// Update a template
  Future<void> updateTemplate(EmailTemplate template) async {
    try {
      await _templatesCollection
          .doc(template.id)
          .update(template.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      throw TemplateServiceException('Failed to update template: $e');
    }
  }

  /// Delete a template
  Future<void> deleteTemplate(String templateId) async {
    try {
      // Delete all variants first
      final variants = await getVariants(templateId);
      for (final variant in variants) {
        await deleteVariant(variant.id);
      }

      // Delete the template
      await _templatesCollection.doc(templateId).delete();
    } catch (e) {
      throw TemplateServiceException('Failed to delete template: $e');
    }
  }

  /// Duplicate a template
  Future<EmailTemplate> duplicateTemplate(
    String templateId,
    String userId,
  ) async {
    try {
      final original = await getTemplate(templateId);
      if (original == null) {
        throw TemplateServiceException('Template not found');
      }

      final now = DateTime.now();
      final duplicate = EmailTemplate(
        id: '',
        userId: userId,
        name: '${original.name} (Copy)',
        subject: original.subject,
        htmlBody: original.htmlBody,
        plainTextBody: original.plainTextBody,
        description: original.description,
        variables: original.variables,
        category: original.category,
        tags: original.tags,
        isDefault: false,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      return await createTemplate(duplicate);
    } catch (e) {
      throw TemplateServiceException('Failed to duplicate template: $e');
    }
  }

  /// Increment template usage count
  Future<void> incrementUsageCount(String templateId) async {
    try {
      await _templatesCollection.doc(templateId).update({
        'usage_count': FieldValue.increment(1),
      });
    } catch (e) {
      throw TemplateServiceException('Failed to increment usage count: $e');
    }
  }

  /// Update template performance metrics
  Future<void> updatePerformanceMetrics(
    String templateId, {
    double? averageOpenRate,
    double? averageClickRate,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (averageOpenRate != null) {
        updates['average_open_rate'] = averageOpenRate;
      }
      if (averageClickRate != null) {
        updates['average_click_rate'] = averageClickRate;
      }
      if (updates.isNotEmpty) {
        updates['updated_at'] = Timestamp.fromDate(DateTime.now());
        await _templatesCollection.doc(templateId).update(updates);
      }
    } catch (e) {
      throw TemplateServiceException(
        'Failed to update performance metrics: $e',
      );
    }
  }

  // ==================== Variant Methods ====================

  /// Create a new variant
  Future<TemplateVariant> createVariant(TemplateVariant variant) async {
    try {
      final docRef = await _variantsCollection.add(variant.toFirestore());
      final doc = await docRef.get();

      // Update template with variant ID
      final template = await getTemplate(variant.templateId);
      if (template != null) {
        final variantIds = List<String>.from(template.variantIds ?? []);
        variantIds.add(docRef.id);
        await updateTemplate(template.copyWith(variantIds: variantIds));
      }

      return TemplateVariant.fromFirestore(doc);
    } catch (e) {
      throw TemplateServiceException('Failed to create variant: $e');
    }
  }

  /// Get a variant by ID
  Future<TemplateVariant?> getVariant(String variantId) async {
    try {
      final doc = await _variantsCollection.doc(variantId).get();
      if (!doc.exists) return null;
      return TemplateVariant.fromFirestore(doc);
    } catch (e) {
      throw TemplateServiceException('Failed to get variant: $e');
    }
  }

  /// Get all variants for a template
  Future<List<TemplateVariant>> getVariants(String templateId) async {
    try {
      final snapshot = await _variantsCollection
          .where('template_id', isEqualTo: templateId)
          .orderBy('created_at')
          .get();

      return snapshot.docs
          .map((doc) => TemplateVariant.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw TemplateServiceException('Failed to get variants: $e');
    }
  }

  /// Update a variant
  Future<void> updateVariant(TemplateVariant variant) async {
    try {
      await _variantsCollection
          .doc(variant.id)
          .update(variant.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      throw TemplateServiceException('Failed to update variant: $e');
    }
  }

  /// Delete a variant
  Future<void> deleteVariant(String variantId) async {
    try {
      final variant = await getVariant(variantId);
      if (variant != null) {
        // Remove variant ID from template
        final template = await getTemplate(variant.templateId);
        if (template != null && template.variantIds != null) {
          final variantIds = List<String>.from(template.variantIds!);
          variantIds.remove(variantId);
          await updateTemplate(template.copyWith(variantIds: variantIds));
        }
      }

      await _variantsCollection.doc(variantId).delete();
    } catch (e) {
      throw TemplateServiceException('Failed to delete variant: $e');
    }
  }

  /// Update variant performance metrics
  Future<void> updateVariantMetrics(
    String variantId, {
    int? sentCount,
    int? openCount,
    int? clickCount,
    int? replyCount,
  }) async {
    try {
      final variant = await getVariant(variantId);
      if (variant == null) return;

      final newSentCount = sentCount ?? variant.sentCount;
      final newOpenCount = openCount ?? variant.openCount;
      final newClickCount = clickCount ?? variant.clickCount;
      final newReplyCount = replyCount ?? variant.replyCount;

      final openRate = newSentCount > 0
          ? (newOpenCount / newSentCount) * 100
          : 0.0;
      final clickRate = newSentCount > 0
          ? (newClickCount / newSentCount) * 100
          : 0.0;
      final replyRate = newSentCount > 0
          ? (newReplyCount / newSentCount) * 100
          : 0.0;

      await _variantsCollection.doc(variantId).update({
        if (sentCount != null) 'sent_count': sentCount,
        if (openCount != null) 'open_count': openCount,
        if (clickCount != null) 'click_count': clickCount,
        if (replyCount != null) 'reply_count': replyCount,
        'open_rate': openRate,
        'click_rate': clickRate,
        'reply_rate': replyRate,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw TemplateServiceException('Failed to update variant metrics: $e');
    }
  }

  /// Get winning variant for a template
  Future<TemplateVariant?> getWinningVariant(String templateId) async {
    try {
      final variants = await getVariants(templateId);
      if (variants.isEmpty) return null;

      // Filter variants with significant data
      final significantVariants = variants
          .where((v) => v.hasSignificantData)
          .toList();
      if (significantVariants.isEmpty) return null;

      // Sort by performance score
      significantVariants.sort(
        (a, b) => b.performanceScore.compareTo(a.performanceScore),
      );

      return significantVariants.first;
    } catch (e) {
      throw TemplateServiceException('Failed to get winning variant: $e');
    }
  }

  // ==================== Version Control Methods ====================

  /// Create a new version of a template
  Future<TemplateVersion> createVersion(
    String templateId,
    EmailTemplate template,
    String changeDescription,
  ) async {
    try {
      // Get the latest version number
      final versionsQuery = await _versionsCollection
          .where('templateId', isEqualTo: templateId)
          .orderBy('versionNumber', descending: true)
          .limit(1)
          .get();

      final nextVersionNumber = versionsQuery.docs.isEmpty
          ? 1
          : versionsQuery.docs.first['versionNumber'] + 1;

      final version = TemplateVersion(
        id: '',
        templateId: templateId,
        userId: template.userId,
        versionNumber: nextVersionNumber,
        name: template.name,
        subject: template.subject,
        htmlBody: template.htmlBody,
        plainTextBody: template.plainTextBody,
        description: template.description,
        variables: template.variables,
        tags: template.tags,
        changeDescription: changeDescription,
        createdAt: DateTime.now(),
      );

      final docRef = await _versionsCollection.add(version.toFirestore());
      return version.copyWith(id: docRef.id);
    } catch (e) {
      throw TemplateServiceException('Error creating template version: $e');
    }
  }

  /// Get all versions of a template
  Future<List<TemplateVersion>> getTemplateVersions(String templateId) async {
    try {
      final snapshot = await _versionsCollection
          .where('templateId', isEqualTo: templateId)
          .orderBy('versionNumber', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TemplateVersion.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw TemplateServiceException('Error fetching template versions: $e');
    }
  }

  /// Get a specific version of a template
  Future<TemplateVersion> getVersion(String versionId) async {
    try {
      final doc = await _versionsCollection.doc(versionId).get();
      if (!doc.exists) {
        throw TemplateServiceException('Version not found');
      }
      return TemplateVersion.fromFirestore(doc);
    } catch (e) {
      throw TemplateServiceException('Error fetching template version: $e');
    }
  }

  /// Restore a previous version of a template
  Future<void> restoreVersion(String templateId, String versionId) async {
    try {
      // Get the version to restore
      final version = await getVersion(versionId);

      // Update the template with the version's content
      await _templatesCollection.doc(templateId).update({
        'name': version.name,
        'subject': version.subject,
        'htmlBody': version.htmlBody,
        'plainTextBody': version.plainTextBody,
        'description': version.description,
        'variables': version.variables,
        'tags': version.tags,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create a new version to track the restoration
      await createVersion(
        templateId,
        EmailTemplate(
          id: templateId,
          userId: version.userId,
          name: version.name,
          subject: version.subject,
          htmlBody: version.htmlBody,
          plainTextBody: version.plainTextBody,
          description: version.description,
          variables: version.variables,
          tags: version.tags,
          category: TemplateCategory.general, // Default category
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        'Restored from version ${version.versionNumber}',
      );
    } catch (e) {
      throw TemplateServiceException('Error restoring template version: $e');
    }
  }

  /// Compare two versions of a template
  Future<Map<String, dynamic>> compareVersions(
    String version1Id,
    String version2Id,
  ) async {
    try {
      final v1 = await getVersion(version1Id);
      final v2 = await getVersion(version2Id);

      return {
        'nameChanged': v1.name != v2.name,
        'subjectChanged': v1.subject != v2.subject,
        'bodyChanged': v1.htmlBody != v2.htmlBody,
        'descriptionChanged': v1.description != v2.description,
        'variablesChanged': !_listsEqual(v1.variables, v2.variables),
        'tagsChanged': !_listsEqual(v1.tags, v2.tags),
      };
    } catch (e) {
      throw TemplateServiceException('Error comparing template versions: $e');
    }
  }

  bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (var i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}

/// Custom exception for template service errors
class TemplateServiceException implements Exception {
  final String message;
  TemplateServiceException(this.message);

  @override
  String toString() => message;
}
