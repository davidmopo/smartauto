import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:smartautomailer/models/user_model.dart';
import 'package:smartautomailer/providers/auth_provider.dart';
import 'package:smartautomailer/services/template_service.dart';

// Service mocks
class MockTemplateService extends Mock implements TemplateService {}

// Provider mocks
class MockAuthProvider extends Mock implements AuthProvider {
  @override
  UserModel? get user => UserModel(
    uid: 'test-user-id',
    email: 'test@example.com',
    emailVerified: true,
    createdAt: DateTime.now(),
  );
}
