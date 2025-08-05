import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/payment_request.dart';
import 'payment_detail_screen.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  Widget _buildValidityStatusBadge(BuildContext context, RequestValidityStatus status) {
    switch (status) {
      case RequestValidityStatus.invalid:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withAlpha(77)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.orange[700], size: 12),
              const SizedBox(width: 2),
              Text(
                'Invalid',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case RequestValidityStatus.reported:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withAlpha(77)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.report_problem, color: Colors.red[700], size: 12),
              const SizedBox(width: 2),
              Text(
                'Reported',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case RequestValidityStatus.valid:
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment History'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'Transactions'),
            ],
          ),
          actions: [
            Consumer<PaymentProvider>(
              builder: (context, paymentProvider, child) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete_all') {
                      _showDeleteAllConfirmation(context, paymentProvider);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete All Requests'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer3<PaymentProvider, AuthProvider, GroupProvider>(
          builder: (context, paymentProvider, authProvider, groupProvider, child) {
            final user = authProvider.currentUser;
            if (user == null) return const SizedBox.shrink();

            final allRequests = paymentProvider.getAllPaymentRequestsForUser(user.id);
            final transactions = paymentProvider.getTransactionsForUser(user.id);

            return TabBarView(
              children: [
                _buildRequestsTab(context, allRequests, paymentProvider),
                _buildTransactionsTab(context, transactions, groupProvider, paymentProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestsTab(BuildContext context, List<PaymentRequest> allRequests, PaymentProvider paymentProvider) {
    if (allRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No payment requests yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment request history will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort requests by creation date (newest first)
    allRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allRequests.length,
      itemBuilder: (context, index) {
        final request = allRequests[index];
        return _buildRequestCard(context, request, paymentProvider);
      },
    );
  }

  Widget _buildTransactionsTab(BuildContext context, List transactions, GroupProvider groupProvider, PaymentProvider paymentProvider) {
    // Add demo transactions if empty
    if (transactions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        paymentProvider.createDemoTransactions();
      });
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Transactions...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Setting up demo data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort transactions by timestamp (newest first)
    transactions.sort((a, b) => 
        DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final fromUser = groupProvider.getUserById(transaction['fromUserId']);
        final toUser = groupProvider.getUserById(transaction['toUserId']);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        final isOutgoing = transaction['fromUserId'] == (currentUser?.id ?? 'user_1');
        final otherUser = isOutgoing ? toUser : fromUser;
        final transactionType = transaction['type'] ?? 'group_payment';
        final description = transaction['description'] ?? 'Money transfer';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: isOutgoing 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              child: Icon(
                isOutgoing ? Icons.arrow_upward : Icons.arrow_downward,
                color: isOutgoing ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            title: Text(
              isOutgoing 
                  ? 'Sent to ${otherUser?.name ?? 'Unknown'}'
                  : 'Received from ${otherUser?.name ?? 'Unknown'}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      transactionType == 'direct_transfer' ? Icons.send : Icons.group,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      transactionType == 'direct_transfer' ? 'Direct Transfer' : 'Group Payment',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(
                    DateTime.parse(transaction['timestamp']),
                  ),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Text(
              '\$${transaction['amount'].toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isOutgoing ? Colors.red : Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, PaymentRequest request, PaymentProvider paymentProvider) {
    final isActive = request.isActive;
    final isRecurring = request.isRecurring;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PaymentDetailScreen(paymentRequest: request),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                request.description.isNotEmpty ? request.description : 'Payment Request',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Inactive',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Add validity status badges for current user
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            final currentUser = authProvider.currentUser;
                            if (currentUser == null) return const SizedBox.shrink();
                            
                            final validityStatus = paymentProvider.getRequestValidityStatus(request.id, currentUser.id);
                            if (validityStatus == RequestValidityStatus.valid) return const SizedBox.shrink();
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _buildValidityStatusBadge(context, validityStatus),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '\$${request.totalAmount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Show status for current user
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                final currentUser = authProvider.currentUser;
                                if (currentUser == null) return const SizedBox.shrink();
                                
                                final validityStatus = paymentProvider.getRequestValidityStatus(request.id, currentUser.id);
                                if (validityStatus == RequestValidityStatus.valid) return const SizedBox.shrink();
                                
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: validityStatus == RequestValidityStatus.invalid 
                                        ? Colors.orange.withAlpha(26)
                                        : Colors.red.withAlpha(26),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: validityStatus == RequestValidityStatus.invalid 
                                          ? Colors.orange.withAlpha(77)
                                          : Colors.red.withAlpha(77),
                                    ),
                                  ),
                                  child: Text(
                                    validityStatus == RequestValidityStatus.invalid ? 'INVALID' : 'FRAUDULENT',
                                    style: TextStyle(
                                      color: validityStatus == RequestValidityStatus.invalid 
                                          ? Colors.orange[700]
                                          : Colors.red[700],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(request.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            if (isRecurring) ...[
                              const SizedBox(width: 16),
                              Icon(
                                Icons.repeat,
                                size: 16,
                                color: Colors.orange[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Recurring',
                                style: TextStyle(
                                  color: Colors.orange[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(context, request, paymentProvider),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete Request',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PaymentRequest request, PaymentProvider paymentProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: Text('Are you sure you want to delete "${request.description.isNotEmpty ? request.description : 'Payment Request'}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              paymentProvider.killPaymentRequest(request.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request "${request.description.isNotEmpty ? request.description : 'Payment Request'}" has been deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation(BuildContext context, PaymentProvider paymentProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Requests'),
        content: const Text('Are you sure you want to delete ALL payment requests? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              paymentProvider.killAllPaymentRequests();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All payment requests have been deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 