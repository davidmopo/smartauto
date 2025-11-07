import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartautomailer/models/email_template.dart';
import 'package:smartautomailer/models/template_version.dart';
import 'package:smartautomailer/services/template_service.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
])
void main() {
  late TemplateService templateService;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockTemplatesCollection;
  late MockCollectionReference mockVersionsCollection;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockTemplatesCollection = MockCollectionReference();
    mockVersionsCollection = MockCollectionReference();

    when(
      mockFirestore.collection('email_templates'),
    ).thenReturn(mockTemplatesCollection);
    when(
      mockFirestore.collection('template_versions'),
    ).thenReturn(mockVersionsCollection);

    templateService = TemplateService();
  });

  group('Template CRUD Operations', () {
    test('createTemplate should create a new template', () async {
      final template = EmailTemplate(
        id: '',
        userId: 'user123',
        name: 'Test Template',
        subject: 'Test Subject',
        htmlBody: 'Test Body',
        plainTextBody: 'Test Body',
        variables: ['firstName', 'lastName'],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockDocRef = MockDocumentReference();
      final mockDoc = MockDocumentSnapshot();

      when(
        mockTemplatesCollection.add(any),
      ).thenAnswer((_) => Future.value(mockDocRef));
      when(mockDocRef.get()).thenAnswer((_) => Future.value(mockDoc));
      when(mockDoc.data()).thenReturn(template.toFirestore());
      when(mockDoc.id).thenReturn('template123');

      final result = await templateService.createTemplate(template);

      expect(result.id, 'template123');
      expect(result.name, template.name);
      verify(mockTemplatesCollection.add(any)).called(1);
    });

    test('getTemplate should return null for non-existent template', () async {
      final mockDocRef = MockDocumentReference();
      final mockDoc = MockDocumentSnapshot();

      when(mockTemplatesCollection.doc('nonexistent')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) => Future.value(mockDoc));
      when(mockDoc.exists).thenReturn(false);

      final result = await templateService.getTemplate('nonexistent');

      expect(result, isNull);
      verify(mockTemplatesCollection.doc('nonexistent')).called(1);
    });

    test('updateTemplate should update existing template', () async {
      final template = EmailTemplate(
        id: 'template123',
        userId: 'user123',
        name: 'Updated Template',
        subject: 'Updated Subject',
        htmlBody: 'Updated Body',
        plainTextBody: 'Updated Body',
        variables: ['firstName', 'lastName'],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockDocRef = MockDocumentReference();

      when(mockTemplatesCollection.doc('template123')).thenReturn(mockDocRef);
      when(mockDocRef.update(any)).thenAnswer((_) => Future.value());

      await templateService.updateTemplate(template);

      verify(mockTemplatesCollection.doc('template123')).called(1);
      verify(mockDocRef.update(any)).called(1);
    });

    test('deleteTemplate should delete template and its versions', () async {
      final mockDocRef = MockDocumentReference();
      final mockVersionsQuery = MockQuerySnapshot();
      final mockVersionDocs = <MockDocumentSnapshot>[];

      when(mockTemplatesCollection.doc('template123')).thenReturn(mockDocRef);
      when(
        mockVersionsCollection
            .where('templateId', isEqualTo: 'template123')
            .get(),
      ).thenAnswer((_) => Future.value(mockVersionsQuery));
      when(mockVersionsQuery.docs).thenReturn(mockVersionDocs);
      when(mockDocRef.delete()).thenAnswer((_) => Future.value());

      await templateService.deleteTemplate('template123');

      verify(mockTemplatesCollection.doc('template123')).called(1);
      verify(mockDocRef.delete()).called(1);
    });
  });

  group('Version Control Operations', () {
    test('createVersion should create new template version', () async {
      final template = EmailTemplate(
        id: 'template123',
        userId: 'user123',
        name: 'Test Template',
        subject: 'Test Subject',
        htmlBody: 'Test Body',
        plainTextBody: 'Test Body',
        variables: ['firstName', 'lastName'],
        category: TemplateCategory.general,
        tags: ['test'],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockQuery = MockQuerySnapshot();
      final mockDocRef = MockDocumentReference();
      final mockDoc = MockDocumentSnapshot();

      when(
        mockVersionsCollection
            .where('templateId', isEqualTo: 'template123')
            .orderBy('versionNumber', descending: true)
            .limit(1)
            .get(),
      ).thenAnswer((_) => Future.value(mockQuery));
      when(mockQuery.docs).thenReturn([]);
      when(
        mockVersionsCollection.add(any),
      ).thenAnswer((_) => Future.value(mockDocRef));
      when(mockDocRef.get()).thenAnswer((_) => Future.value(mockDoc));

      final result = await templateService.createVersion(
        'template123',
        template,
        'Initial version',
      );

      expect(result.versionNumber, 1);
      verify(mockVersionsCollection.add(any)).called(1);
    });

    test('getTemplateVersions should return all versions', () async {
      final mockQuery = MockQuerySnapshot();
      final mockDoc = MockDocumentSnapshot();
      final mockData = {
        'templateId': 'template123',
        'userId': 'user123',
        'versionNumber': 1,
        'name': 'Test Template',
        'subject': 'Test Subject',
        'htmlBody': 'Test Body',
        'variables': ['firstName', 'lastName'],
        'tags': ['test'],
        'changeDescription': 'Initial version',
        'createdAt': Timestamp.now(),
      };

      when(
        mockVersionsCollection
            .where('templateId', isEqualTo: 'template123')
            .orderBy('versionNumber', descending: true)
            .get(),
      ).thenAnswer((_) => Future.value(mockQuery));
      when(mockQuery.docs).thenReturn([mockDoc]);
      when(mockDoc.data()).thenReturn(mockData);
      when(mockDoc.id).thenReturn('version123');

      final versions = await templateService.getTemplateVersions('template123');

      expect(versions.length, 1);
      expect(versions.first.templateId, 'template123');
      verify(
        mockVersionsCollection
            .where('templateId', isEqualTo: 'template123')
            .orderBy('versionNumber', descending: true)
            .get(),
      ).called(1);
    });
  });
}
