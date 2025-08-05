# Backend Infrastructure Plan for Quip MVP

## 1. Technology Stack Recommendation

### Option A: Firebase (Recommended for MVP)
- **Authentication**: Firebase Auth
- **Database**: Firestore
- **Storage**: Firebase Storage (for profile images)
- **Notifications**: Firebase Cloud Messaging
- **Hosting**: Firebase Hosting (for web version)

### Option B: Custom Backend
- **Backend**: Node.js + Express or Python + FastAPI
- **Database**: PostgreSQL or MongoDB
- **Authentication**: JWT tokens
- **File Storage**: AWS S3 or Cloudinary
- **Hosting**: Heroku, Railway, or AWS

## 2. Database Schema

### Users Collection
```json
{
  "id": "user_123",
  "name": "John Doe",
  "email": "john@example.com",
  "phoneNumber": "+1234567890",
  "profileImage": "https://...",
  "balance": 500.0,
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### Groups Collection
```json
{
  "id": "group_456",
  "name": "Roommates",
  "description": "Apartment expenses",
  "memberIds": ["user_123", "user_456"],
  "createdBy": "user_123",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### Payment Requests Collection
```json
{
  "id": "req_789",
  "groupId": "group_456",
  "requestedBy": "user_123",
  "totalAmount": 100.0,
  "description": "Rent payment",
  "includeRequester": true,
  "exemptedMembers": [],
  "customAmounts": {"user_123": 50.0, "user_456": 50.0},
  "paymentStatus": {"user_123": "paid", "user_456": "pending"},
  "createdAt": "2024-01-01T00:00:00Z",
  "completedAt": null,
  "isRecurring": false,
  "isActive": true
}
```

### Transactions Collection
```json
{
  "id": "txn_101",
  "fromUserId": "user_123",
  "toUserId": "user_456",
  "amount": 25.0,
  "description": "Lunch payment",
  "type": "direct_transfer",
  "paymentRequestId": null,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## 3. API Endpoints

### Authentication
- `POST /auth/signup` - User registration
- `POST /auth/login` - User login
- `POST /auth/logout` - User logout
- `GET /auth/profile` - Get user profile
- `PUT /auth/profile` - Update user profile

### Groups
- `GET /groups` - Get user's groups
- `POST /groups` - Create new group
- `GET /groups/:id` - Get group details
- `PUT /groups/:id` - Update group
- `DELETE /groups/:id` - Delete group
- `POST /groups/:id/members` - Add member to group
- `DELETE /groups/:id/members/:userId` - Remove member from group

### Payment Requests
- `GET /payment-requests` - Get user's payment requests
- `POST /payment-requests` - Create payment request
- `GET /payment-requests/:id` - Get payment request details
- `PUT /payment-requests/:id/status` - Update payment status
- `DELETE /payment-requests/:id` - Cancel payment request

### Transactions
- `GET /transactions` - Get user's transactions
- `POST /transactions` - Create transaction
- `GET /transactions/:id` - Get transaction details

## 4. Implementation Steps

### Phase 1: Firebase Setup
1. Create Firebase project
2. Enable Authentication (Email/Password)
3. Set up Firestore database
4. Configure security rules
5. Set up Firebase Storage

### Phase 2: API Integration
1. Add Firebase dependencies to Flutter
2. Replace local storage with Firebase calls
3. Implement real-time data synchronization
4. Add offline support

### Phase 3: Authentication
1. Replace demo authentication with Firebase Auth
2. Add email verification
3. Implement password reset
4. Add social login (Google, Apple)

### Phase 4: Data Migration
1. Create data migration scripts
2. Test with real data
3. Implement backup strategies

## 5. Security Considerations

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Groups - members can read, creator can write
    match /groups/{groupId} {
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.memberIds;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.createdBy;
    }
    
    // Payment requests - group members can access
    match /paymentRequests/{requestId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in get(/databases/$(database)/documents/groups/$(resource.data.groupId)).data.memberIds;
    }
  }
}
```

## 6. Cost Estimation (Firebase)

### Free Tier Limits
- Authentication: 10,000 users/month
- Firestore: 1GB storage, 50,000 reads/day, 20,000 writes/day
- Storage: 5GB storage, 1GB downloads/day
- Hosting: 10GB storage, 360MB/day transfer

### Paid Tier (if needed)
- Authentication: $0.01 per user/month after 10,000
- Firestore: $0.18 per 100,000 reads, $0.18 per 100,000 writes
- Storage: $0.026 per GB/month
- Hosting: $0.026 per GB/month

## 7. Testing Strategy

### Unit Tests
- API endpoint testing
- Data validation
- Security rules testing

### Integration Tests
- End-to-end user flows
- Payment processing
- Group management

### Performance Tests
- Database query optimization
- Real-time synchronization
- Offline functionality

## 8. Deployment Checklist

- [ ] Firebase project created
- [ ] Authentication enabled
- [ ] Firestore database configured
- [ ] Security rules implemented
- [ ] Flutter app updated with Firebase
- [ ] Data migration completed
- [ ] Testing completed
- [ ] Production environment configured
- [ ] Monitoring and analytics set up
- [ ] Backup strategy implemented 