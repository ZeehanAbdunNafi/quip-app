# MVP Quick Start Guide

## Step 1: Firebase Setup (30 minutes)

### 1.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Name it "Quip-MVP"
4. Enable Google Analytics (optional)
5. Click "Create project"

### 1.2 Enable Authentication
1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password"
5. Click "Save"

### 1.3 Set up Firestore Database
1. Go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for MVP)
4. Select a location close to your users
5. Click "Done"

### 1.4 Configure Security Rules
1. Go to "Firestore Database" → "Rules"
2. Replace with this basic rule set:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
3. Click "Publish"

### 1.5 Get Firebase Config
1. Go to Project Settings (gear icon)
2. Scroll to "Your apps"
3. Click "Add app" → "Android"
4. Enter package name: `com.example.quip`
5. Download `google-services.json`
6. Place it in `android/app/`

## Step 2: Flutter Firebase Integration (1 hour)

### 2.1 Install Dependencies
Run this command in your project root:
```bash
flutter pub get
```

### 2.2 Update Android Configuration
1. Open `android/app/build.gradle`
2. Add to the bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

3. Open `android/build.gradle`
4. Add to dependencies:
```gradle
classpath 'com.google.gms:google-services:4.3.15'
```

### 2.3 Create Firebase Service
Create `lib/services/firebase_service.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;
  static FirebaseAuth? _auth;

  static FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  static FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }
}
```

### 2.4 Update Main App
Update `lib/main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  
  // ... rest of your existing code
}
```

## Step 3: Authentication Implementation (2 hours)

### 3.1 Create Auth Service
Create `lib/services/auth_service.dart`:
```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign in
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
```

### 3.2 Update Auth Provider
Update `lib/providers/auth_provider.dart` to use Firebase:
```dart
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    _authService.authStateChanges.listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signUp(email, password);
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
```

## Step 4: Database Integration (3 hours)

### 4.1 Create Database Service
Create `lib/services/database_service.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/payment_request.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Users
  Future<void> createUser(User user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  Future<User?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? User.fromJson(doc.data()!) : null;
  }

  // Groups
  Future<void> createGroup(Group group) async {
    await _firestore.collection('groups').doc(group.id).set(group.toJson());
  }

  Stream<List<Group>> getGroupsForUser(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromJson(doc.data()))
            .toList());
  }

  // Payment Requests
  Future<void> createPaymentRequest(PaymentRequest request) async {
    await _firestore.collection('payment_requests').doc(request.id).set(request.toJson());
  }

  Stream<List<PaymentRequest>> getPaymentRequestsForUser(String userId) {
    return _firestore
        .collection('payment_requests')
        .where('paymentStatus.$userId', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentRequest.fromJson(doc.data()))
            .toList());
  }
}
```

### 4.2 Update Providers
Update your existing providers to use the database service instead of local storage.

## Step 5: Testing (1 hour)

### 5.1 Test Authentication
1. Run the app
2. Try signing up with a new email
3. Try signing in with the created account
4. Test logout functionality

### 5.2 Test Data Sync
1. Create a group
2. Create a payment request
3. Check if data appears in Firebase Console
4. Test real-time updates

## Step 6: Deployment Preparation (30 minutes)

### 6.1 Update App Configuration
1. Update `android/app/build.gradle` version
2. Update app name and description
3. Add app icon
4. Configure signing for release

### 6.2 Environment Setup
1. Create production Firebase project
2. Update security rules for production
3. Set up monitoring and analytics
4. Configure error reporting

## Common Issues & Solutions

### Issue: Firebase not initialized
**Solution**: Make sure you call `Firebase.initializeApp()` before using any Firebase services.

### Issue: Authentication not working
**Solution**: Check that Email/Password is enabled in Firebase Console.

### Issue: Database rules blocking access
**Solution**: Temporarily use test mode rules, then implement proper security rules.

### Issue: App crashes on startup
**Solution**: Check that `google-services.json` is in the correct location.

## Next Steps After Quick Start

1. **Implement proper security rules**
2. **Add offline support**
3. **Implement push notifications**
4. **Add user profile management**
5. **Create onboarding flow**
6. **Add error handling**
7. **Implement analytics**
8. **Prepare for app store submission**

## Estimated Timeline

- **Firebase Setup**: 30 minutes
- **Flutter Integration**: 1 hour
- **Authentication**: 2 hours
- **Database Integration**: 3 hours
- **Testing**: 1 hour
- **Deployment Prep**: 30 minutes

**Total Quick Start Time**: 8 hours

This will give you a working MVP with real authentication and database functionality! 