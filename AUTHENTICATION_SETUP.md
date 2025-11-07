# SmartAutoMailer - Authentication System Setup Guide

This guide will help you set up and test the authentication system for SmartAutoMailer.

## 📋 What's Been Built

The User Authentication System includes:

### ✅ Core Components
- **User Model** (`lib/models/user_model.dart`)
  - Firebase user data structure
  - Firestore integration
  - User metadata handling

- **Authentication Service** (`lib/services/auth_service.dart`)
  - Email/password authentication
  - Password reset functionality
  - Email verification
  - User profile management
  - Account deletion

- **Authentication Provider** (`lib/providers/auth_provider.dart`)
  - State management with Provider pattern
  - Real-time auth state updates
  - Error handling
  - Loading states

### ✅ UI Components

**Reusable Widgets:**
- `AuthTextField` - Custom text input with validation
- `AuthButton` - Button with loading states
- `SocialLoginButton` - OAuth provider buttons (placeholders)

**Authentication Screens:**
- `LoginScreen` - User login with email/password
- `SignupScreen` - New user registration
- `ForgotPasswordScreen` - Password reset flow
- `EmailVerificationScreen` - Email verification with auto-check
- `ProfileScreen` - User profile management

**Dashboard:**
- `DashboardScreen` - Main app dashboard with stats and quick actions

### ✅ App Configuration
- `main.dart` - App entry point with routing and auth wrapper
- `firebase_options.dart` - Firebase configuration (needs setup)

## 🚀 Setup Instructions

### Step 1: Install Dependencies

Run the following command in the `smartautomailer` directory:

```bash
flutter pub get
```

### Step 2: Configure Firebase

You need to set up a Firebase project and configure it for your app.

#### Option A: Using FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase:
```bash
flutterfire configure
```

This will:
- Create a Firebase project (or select existing one)
- Register your app with Firebase
- Generate `firebase_options.dart` with your credentials
- Download configuration files for each platform

#### Option B: Manual Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Add apps for each platform you want to support:
   - **Web**: Get the Firebase config object
   - **Android**: Download `google-services.json`
   - **iOS**: Download `GoogleService-Info.plist`
   - **Windows/macOS**: Use web config

4. Update `lib/firebase_options.dart` with your Firebase credentials:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',
  appId: 'YOUR_WEB_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);
```

### Step 3: Enable Authentication Methods in Firebase

1. Go to Firebase Console → Authentication → Sign-in method
2. Enable **Email/Password** authentication
3. (Optional) Enable other providers like Google, Microsoft, Apple

### Step 4: Set Up Firestore Database

1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location for your database

### Step 5: Configure Firestore Security Rules

Update your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 🧪 Testing the Authentication System

### Running the App

1. **For Web:**
```bash
flutter run -d chrome
```

2. **For Windows:**
```bash
flutter run -d windows
```

3. **For macOS:**
```bash
flutter run -d macos
```

### Test Scenarios

#### 1. User Registration
1. Launch the app
2. Click "Sign Up" on the login screen
3. Fill in:
   - Full Name
   - Email address
   - Password (min 6 characters)
   - Confirm password
4. Accept terms and conditions
5. Click "Sign Up"
6. You should be redirected to the Email Verification screen

#### 2. Email Verification
1. After signup, check your email inbox
2. Click the verification link in the email
3. Return to the app
4. The app should auto-detect verification and redirect to dashboard
5. Or click "I've Verified My Email" to manually check

#### 3. User Login
1. On the login screen, enter your email and password
2. Click "Sign In"
3. If email is verified, you'll be redirected to the dashboard
4. If not verified, you'll see the verification screen

#### 4. Password Reset
1. On the login screen, click "Forgot Password?"
2. Enter your email address
3. Click "Send Reset Link"
4. Check your email for the reset link
5. Click the link and set a new password
6. Return to the app and login with new password

#### 5. Profile Management
1. Login to the app
2. Click the profile icon in the dashboard
3. Test:
   - Editing your display name
   - Changing your password
   - Viewing account information

#### 6. Sign Out
1. From the dashboard, click the logout icon
2. You should be redirected to the login screen

## 📁 Project Structure

```
lib/
├── models/
│   └── user_model.dart              # User data model
├── services/
│   └── auth_service.dart            # Authentication business logic
├── providers/
│   └── auth_provider.dart           # State management
├── widgets/
│   └── auth/
│       ├── auth_text_field.dart     # Custom text input
│       ├── auth_button.dart         # Custom button
│       └── social_login_button.dart # OAuth buttons
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart        # Login page
│   │   ├── signup_screen.dart       # Registration page
│   │   ├── forgot_password_screen.dart
│   │   ├── email_verification_screen.dart
│   │   └── profile_screen.dart      # User profile
│   └── dashboard/
│       └── dashboard_screen.dart    # Main dashboard
├── firebase_options.dart            # Firebase config
└── main.dart                        # App entry point
```

## 🔧 Troubleshooting

### Firebase Initialization Error
**Problem:** App shows "Firebase initialization error"
**Solution:** 
- Make sure you've configured `firebase_options.dart` with your Firebase credentials
- Run `flutterfire configure` to auto-generate the configuration

### Dependencies Not Found
**Problem:** IDE shows errors for firebase_core, provider, etc.
**Solution:**
```bash
flutter clean
flutter pub get
```

### Email Not Sending
**Problem:** Verification/reset emails not arriving
**Solution:**
- Check spam folder
- Verify email/password authentication is enabled in Firebase Console
- Check Firebase Console → Authentication → Templates for email settings

### Build Errors
**Problem:** App won't compile
**Solution:**
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

## 🎯 Next Steps

After testing the authentication system, you can proceed to:

1. **Phase 2, No. 2**: Build the main dashboard UI
2. **Phase 3**: Implement email finder and verifier
3. **Phase 4**: Create email composer and personalizer
4. **Phase 5**: Build campaign sender and scheduler
5. **Phase 6**: Add analytics and reporting

## 📝 Notes

- The current implementation uses Firebase Authentication and Firestore
- Social login buttons (Google, Microsoft, Apple) are placeholders and need OAuth configuration
- Email verification is required before accessing the full dashboard
- All passwords must be at least 6 characters (Firebase requirement)
- User data is stored in Firestore under `/users/{userId}`

## 🔐 Security Considerations

- Never commit `firebase_options.dart` with real credentials to public repositories
- Use environment variables for sensitive data in production
- Implement proper Firestore security rules before deploying
- Enable App Check in Firebase for additional security
- Consider implementing rate limiting for authentication attempts

## 📚 Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Flutter Provider Package](https://pub.dev/packages/provider)
- [Firebase Authentication Best Practices](https://firebase.google.com/docs/auth/best-practices)

---

**Built with ❤️ for SmartAutoMailer**

