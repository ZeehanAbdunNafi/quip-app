import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/group_provider.dart';
import '../../payments/create_payment_request_screen.dart';
import '../../payments/payment_detail_screen.dart';
import '../../../models/group.dart';
import '../../../models/payment_request.dart';

class PaymentsTab extends StatelessWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payments'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: Consumer3<PaymentProvider, AuthProvider, GroupProvider>(
          builder: (context, paymentProvider, authProvider, groupProvider, child) {
            final user = authProvider.currentUser;
            if (user == null) return const SizedBox.shrink();

            final userPayments = paymentProvider.getPaymentRequestsForUser(user.id);
            final transactions = paymentProvider.getTransactionsForUser(user.id);

            return TabBarView(
              children: [
                _buildPaymentRequests(context, userPayments, groupProvider),
                _buildTransactionHistory(context, transactions, groupProvider),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreatePaymentRequestScreen(draft: null)),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPaymentRequests(BuildContext context, List payments, GroupProvider groupProvider) {
    // Add demo payment requests if empty
    if (payments.isEmpty) {
      return Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          // Create demo payment requests if they don't exist
          WidgetsBinding.instance.addPostFrameCallback((_) {
            paymentProvider.createDemoPaymentRequests();
          });
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading Payment Requests...',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Setting up demo data',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        Group group;
        try {
          group = groupProvider.groups.firstWhere(
            (g) => g.id == payment.groupId,
            orElse: () => Group(
              id: 'personal',
              name: 'Personal',
              description: '',
              createdAt: DateTime.now(),
              createdBy: '',
              memberIds: const [],
            ),
          );
        } catch (e) {
          // Fallback for any other errors
          group = Group(
            id: 'personal',
            name: 'Personal',
            description: '',
            createdAt: DateTime.now(),
            createdBy: '',
            memberIds: const [],
          );
        }
        final requester = groupProvider.getUserById(payment.requestedBy);

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        final isPending = payment.paymentStatus[currentUser?.id] == PaymentStatus.pending;
        final amountOwed = payment.getAmountForUser(currentUser?.id ?? '', payment.paymentStatus.keys.toList());

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: _getPaymentStatusColor(payment).withOpacity(0.1),
                      child: Icon(
                        _getPaymentStatusIcon(payment),
                        color: _getPaymentStatusColor(payment),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.description,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Group: ${group.name}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Requested by: ${requester?.id == currentUser?.id ? 'You' : requester?.name ?? 'Unknown'}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(payment.createdAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Consumer<PaymentProvider>(
                          builder: (context, paymentProvider, child) {
                            // Check validity status first
                            final validityStatus = paymentProvider.getRequestValidityStatus(payment.id, currentUser?.id ?? '');
                            String statusText;
                            Color statusColor;
                            
                            if (validityStatus == RequestValidityStatus.invalid) {
                              statusText = 'Invalid';
                              statusColor = Colors.orange;
                            } else if (validityStatus == RequestValidityStatus.reported) {
                              statusText = 'Fraudulent';
                              statusColor = Colors.red;
                            } else {
                              // Fall back to payment status
                              statusText = _getPaymentStatusText(payment);
                              statusColor = _getPaymentStatusColor(payment);
                            }
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        if (currentUser?.id != payment.requestedBy)
                          Text(
                            '\$${amountOwed.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            'Requested',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (isPending && currentUser?.id != payment.requestedBy) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.payment, size: 18),
                          label: Text('Pay \$${amountOwed.toStringAsFixed(2)}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _payRequest(context, payment, amountOwed),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Details'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PaymentDetailScreen(paymentRequest: payment),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('View Details'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PaymentDetailScreen(paymentRequest: payment),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionHistory(BuildContext context, List transactions, GroupProvider groupProvider) {
    // Add demo transactions if empty
    if (transactions.isEmpty) {
      return Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          // Create demo transactions if they don't exist
          WidgetsBinding.instance.addPostFrameCallback((_) {
            paymentProvider.createDemoTransactions();
          });
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading Transactions...',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Setting up demo data',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }

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

  Future<void> _payRequest(BuildContext context, payment, double amount) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to make a payment.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Payment'),
          content: Text(
            'Are you sure you want to pay \$${amount.toStringAsFixed(2)} for "${payment.description}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pay'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Process the payment
        await paymentProvider.payAmount(
          payment.id,
          currentUser.id,
          payment.requestedBy,
          amount,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully paid \$${amount.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getPaymentStatusColor(payment) {
    if (payment.isCompleted) return Colors.green;
    if (payment.pendingPaymentsCount > 0) return Colors.orange;
    return Colors.grey;
  }

  IconData _getPaymentStatusIcon(payment) {
    if (payment.isCompleted) return Icons.check_circle;
    if (payment.pendingPaymentsCount > 0) return Icons.pending;
    return Icons.payment;
  }

  String _getPaymentStatusText(payment) {
    // For now, just return the basic status
    // The validity status will be handled in the UI layer
    if (payment.isCompleted) return 'Completed';
    if (payment.pendingPaymentsCount > 0) return 'Pending';
    return 'Cancelled';
  }
} 