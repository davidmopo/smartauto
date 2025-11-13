import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Collection names
  static const String _usersCollection = 'users';
  static const String _campaignsCollection = 'campaigns';
  static const String _templatesCollection = 'templates';

  // Rate limiting
  DateTime? _lastVerificationEmailSent;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // User changes stream (includes token refresh)
  Stream<User?> get userChanges => _auth.userChanges();

  // ID token changes stream (for automatic token refresh)
  Stream<User?> get idTokenChanges => _auth.idTokenChanges();

  // Check network connectivity
  Future<bool> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Validate email
  void _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw Exception('Invalid email format');
    }
  }

  // Validate password
  void _validatePassword(String password) {
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    // Add more password strength checks if needed
    // if (!password.contains(RegExp(r'[A-Z]'))) {
    //   throw Exception('Password must contain at least one uppercase letter');
    // }
  }

  // Log auth events
  void _logAuthEvent(String event, {Map<String, dynamic>? parameters}) {
    debugPrint('Auth Event: $event ${parameters ?? ""}');
    // TODO: Add Firebase Analytics
    // FirebaseAnalytics.instance.logEvent(name: event, parameters: parameters);
  }

  // Sign up with email and password
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _logAuthEvent('sign_up_attempt', parameters: {'email': email});

      // Validate inputs
      _validateEmail(email);
      _validatePassword(password);

      // Check network
      if (!await _checkNetworkConnectivity()) {
        throw Exception('No internet connection. Please check your network.');
      }

      // Create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Update display name if provided
        if (displayName != null && displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
          await user.reload();
          await Future.delayed(const Duration(milliseconds: 100));
          user = _auth.currentUser;
        }

        // Send email verification
        await user?.sendEmailVerification();
        _lastVerificationEmailSent = DateTime.now();

        // Create user document in Firestore
        UserModel userModel = UserModel.fromFirebaseUser(user!);
        await _firestore
            .collection(_usersCollection)
            .doc(user.uid)
            .set(userModel.toMap());

        _logAuthEvent('sign_up_success');
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _logAuthEvent('sign_up_failure', parameters: {'error': e.code});
      throw _handleAuthException(e);
    } catch (e) {
      _logAuthEvent('sign_up_failure', parameters: {'error': e.toString()});
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _logAuthEvent('sign_in_attempt', parameters: {'email': email});

      // Validate inputs
      _validateEmail(email);

      // Check network
      if (!await _checkNetworkConnectivity()) {
        throw Exception('No internet connection. Please check your network.');
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Update last login time in Firestore
        try {
          await _firestore.collection(_usersCollection).doc(user.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          // If offline, this will fail but user can still sign in
          debugPrint('Failed to update last login time: $e');
        }

        _logAuthEvent('sign_in_success');
        return UserModel.fromFirebaseUser(user);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _logAuthEvent('sign_in_failure', parameters: {'error': e.code});
      throw _handleAuthException(e);
    } catch (e) {
      _logAuthEvent('sign_in_failure', parameters: {'error': e.toString()});
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      _logAuthEvent('google_sign_in_attempt');

      // Check network
      if (!await _checkNetworkConnectivity()) {
        throw Exception('No internet connection. Please check your network.');
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        _logAuthEvent('google_sign_in_cancelled');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      User? user = userCredential.user;
      if (user != null) {
        // Check if user document exists
        DocumentSnapshot userDoc =
            await _firestore.collection(_usersCollection).doc(user.uid).get();

        UserModel userModel;
        if (!userDoc.exists) {
          // Create new user document for first-time Google sign-in
          userModel = UserModel.fromFirebaseUser(user);
          await _firestore
              .collection(_usersCollection)
              .doc(user.uid)
              .set(userModel.toMap());
          _logAuthEvent('google_sign_up_success');
        } else {
          // Update existing user's last login time
          await _firestore.collection(_usersCollection).doc(user.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
          userModel = UserModel.fromFirebaseUser(user);
          _logAuthEvent('google_sign_in_success');
        }

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _logAuthEvent('google_sign_in_failure', parameters: {'error': e.code});
      throw _handleAuthException(e);
    } catch (e) {
      _logAuthEvent('google_sign_in_failure',
          parameters: {'error': e.toString()});
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Sign out (including Google)
  Future<void> signOut() async {
    try {
      _logAuthEvent('sign_out_attempt');

      // Sign out from Google if user is signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      await _auth.signOut();
      _logAuthEvent('sign_out_success');
    } catch (e) {
      _logAuthEvent('sign_out_failure', parameters: {'error': e.toString()});
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reauthenticate user (required for sensitive operations)
  Future<void> reauthenticateUser(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reauthenticate with Google
  Future<void> reauthenticateWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.currentUser?.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _validateEmail(email);

      if (!await _checkNetworkConnectivity()) {
        throw Exception('No internet connection. Please check your network.');
      }

      await _auth.sendPasswordResetEmail(email: email);
      _logAuthEvent('password_reset_email_sent', parameters: {'email': email});
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Send email verification with rate limiting
  Future<void> sendEmailVerification() async {
    try {
      // Check rate limiting (max 1 email per minute)
      if (_lastVerificationEmailSent != null) {
        final difference =
            DateTime.now().difference(_lastVerificationEmailSent!);
        if (difference.inSeconds < 60) {
          throw Exception(
              'Please wait ${60 - difference.inSeconds} seconds before requesting another verification email.');
        }
      }

      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _lastVerificationEmailSent = DateTime.now();
        _logAuthEvent('verification_email_sent');
      }
    } catch (e) {
      throw Exception('Failed to send email verification: $e');
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Wait for email verification with timeout
  Future<bool> waitForEmailVerification({
    Duration timeout = const Duration(minutes: 5),
    Duration checkInterval = const Duration(seconds: 3),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await reloadUser();
      if (_auth.currentUser?.emailVerified ?? false) {
        return true;
      }
      await Future.delayed(checkInterval);
    }
    return false;
  }

  // Reload user to get updated email verification status and refresh token
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      debugPrint('Failed to reload user: $e');
      // Don't throw - this might fail offline
    }
  }

  // Get fresh ID token (forces token refresh)
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      return await _auth.currentUser?.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('Failed to get ID token: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        await user.reload();

        // Update Firestore
        Map<String, dynamic> updates = {};
        if (displayName != null) updates['displayName'] = displayName;
        if (photoURL != null) updates['photoURL'] = photoURL;

        if (updates.isNotEmpty) {
          try {
            await _firestore
                .collection(_usersCollection)
                .doc(user.uid)
                .update(updates);
          } catch (e) {
            // Offline - will sync when back online
            debugPrint('Failed to update Firestore profile: $e');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update password
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      _validatePassword(newPassword);

      // Reauthenticate first
      await reauthenticateUser(currentPassword);

      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        _logAuthEvent('password_updated');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  // Delete user account
  Future<void> deleteAccount(String? password) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      // Reauthenticate based on sign-in method
      final providerData = user.providerData;
      final isGoogleUser = providerData.any(
        (info) => info.providerId == 'google.com',
      );

      if (isGoogleUser) {
        await reauthenticateWithGoogle();
      } else if (password != null) {
        await reauthenticateUser(password);
      } else {
        throw Exception('Password required for account deletion');
      }

      // Delete all user-related data in batches
      try {
        // Delete user document
        await _firestore.collection(_usersCollection).doc(user.uid).delete();

        // Delete user's campaigns
        QuerySnapshot campaigns = await _firestore
            .collection(_campaignsCollection)
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var doc in campaigns.docs) {
          await doc.reference.delete();
        }

        // Delete user's templates
        QuerySnapshot templates = await _firestore
            .collection(_templatesCollection)
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var doc in templates.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete user data from Firestore: $e');
        // Continue with auth deletion even if Firestore fails
      }

      // Sign out from Google if applicable
      if (isGoogleUser && await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Finally, delete the user from Firebase Auth
      await user.delete();
      _logAuthEvent('account_deleted');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Get user data from Firestore with offline support
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get user data: $e');
      // Return data from Firebase Auth if Firestore fails (offline)
      if (_auth.currentUser?.uid == uid) {
        return UserModel.fromFirebaseUser(_auth.currentUser!);
      }
      return null;
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password should be at least 6 characters long.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Try logging in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support for assistance.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again in a few minutes.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Contact support.';
      case 'requires-recent-login':
        return 'For security, please log in again to perform this action.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email but different sign-in method.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Sign-in was cancelled.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}
