# Quip - Send Money Demo

This demo showcases the "Send Money" functionality with comprehensive transaction history and payment logs.

## Demo Features

### 1. Send Money Screen
- **Location**: Dashboard → "Send Money" button
- **Features**:
  - Search and select recipients from demo users
  - Enter amount and optional description
  - Real-time form validation
  - Success notifications
  - Recent transactions display

### 2. Transaction History
- **Location**: Payments tab → "History" tab
- **Features**:
  - Demo transaction data with realistic scenarios
  - Color-coded transactions (red for outgoing, green for incoming)
  - Transaction types (Direct Transfer vs Group Payment)
  - Timestamps and descriptions
  - User avatars and names

### 3. Payment History Screen
- **Location**: Dashboard → "View History" button
- **Features**:
  - Two tabs: "Requests" and "Transactions"
  - Comprehensive transaction logs
  - Demo data auto-loading
  - Detailed transaction information

## Demo Data

### Demo Users
- **John Doe** (user_1) - Current user
- **Jane Smith** (user_2)
- **Mike Johnson** (user_3)
- **Sarah Wilson** (user_4)
- **David Brown** (user_5)
- **Emily Davis** (user_6)
- **Alex Chen** (user_7)
- **Lisa Anderson** (user_8)

### Demo Transactions
1. **Lunch payment** - $25.50 (John → Jane)
2. **Coffee payment** - $15.75 (Mike → John)
3. **Dinner split** - $45.00 (John → Sarah)
4. **Movie tickets** - $12.30 (Jane → John)
5. **Snack payment** - $8.50 (John → Mike)
6. **Coffee and pastry** - $18.75 (Emily → John)
7. **Lunch meeting** - $32.00 (John → Alex)
8. **Dinner split** - $25.50 (Lisa → John)

### Demo Payment Requests (Requested from John)
1. **Lunch at Italian restaurant** - $35.50 (Jane → John)
2. **Weekend trip expenses** - $60.00 (Sarah → John)
3. **Coffee and snacks for team meeting** - $45.75 (Emily → John)
4. **Movie tickets and dinner** - $42.50 (Lisa → John)
5. **Uber ride to airport** - $28.00 (Mike → John)

## How to Test

1. **Launch the app** - Demo user (John Doe) will be automatically logged in
2. **Navigate to Send Money**:
   - Go to Dashboard
   - Tap "Send Money" button
   - Select a recipient from the list
   - Enter amount and description
   - Tap "Send Money"
3. **View Payment Requests**:
   - Go to Payments tab
   - Switch to "Requests" tab
   - See demo payment requests where others have requested money from you
   - **Pay Button**: Click the green "Pay" button to pay back requests
   - **Confirmation Dialog**: Confirm payment amount before processing
4. **View Transaction History**:
   - Go to Payments tab
   - Switch to "History" tab
   - See demo transactions with realistic data
5. **View Payment History**:
   - Go to Dashboard
   - Tap "View History"
   - Browse both "Requests" and "Transactions" tabs

## Technical Implementation

### Key Files
- `lib/screens/payments/send_money_screen.dart` - Send Money UI
- `lib/providers/payment_provider.dart` - Transaction management
- `lib/screens/home/tabs/payments_tab.dart` - Payments history
- `lib/screens/payments/payment_history_screen.dart` - Detailed history

### Demo Data Creation
- Demo transactions are created in `PaymentProvider.createDemoTransactions()`
- Demo users are created in `GroupProvider._loadUsers()`
- Demo user is set in `AuthProvider.initialize()`

### Transaction Structure
```json
{
  "id": "demo-1",
  "fromUserId": "user_1",
  "toUserId": "user_2", 
  "amount": 25.50,
  "type": "direct_transfer",
  "description": "Lunch payment",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## Features Demonstrated

✅ **Send Money Functionality**
- User selection with search
- Amount validation
- Real-time feedback
- Transaction recording

✅ **Transaction History**
- Comprehensive logs
- Color-coded transactions
- Detailed information
- Timestamp tracking

✅ **Payment History**
- Tabbed interface
- Request vs Transaction views
- Demo data integration
- User-friendly display
- **Pay Button**: Direct payment functionality for pending requests
- **Confirmation Dialog**: Safe payment confirmation

✅ **Demo Data Management**
- Automatic demo user creation
- Sample transaction generation
- Realistic scenarios
- Persistent storage

The demo provides a complete "Send Money" experience with realistic transaction logs and comprehensive history tracking. 