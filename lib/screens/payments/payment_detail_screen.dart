import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment_request.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/group.dart';
import 'request_action_dialog.dart';
import 'partial_payment_dialog.dart';

class PaymentDetailScreen extends StatefulWidget {
  final PaymentRequest paymentRequest;

  const PaymentDetailScreen({super.key, required this.paymentRequest});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {

  String _getFrequencyText(RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'day(s)';
      case RecurringFrequency.weekly:
        return 'week(s)';
      case RecurringFrequency.monthly:
        return 'month(s)';
    }
  }

  void _showDeleteDialog(BuildContext context, PaymentProvider paymentProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: Text(
          'Are you sure you want to delete "${widget.paymentRequest.description.isNotEmpty ? widget.paymentRequest.description : 'Payment Request'}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              paymentProvider.killPaymentRequest(widget.paymentRequest.id);
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request "${widget.paymentRequest.description.isNotEmpty ? widget.paymentRequest.description : 'Payment Request'}" has been deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRequestActionDialog(BuildContext context, PaymentProvider paymentProvider, String userId) async {
    final currentStatus = paymentProvider.getRequestValidityStatus(widget.paymentRequest.id, userId);
    String? currentReason;
    
    if (currentStatus == RequestValidityStatus.invalid) {
      currentReason = paymentProvider.getInvalidationReason(widget.paymentRequest.id, userId);
    } else if (currentStatus == RequestValidityStatus.reported) {
      currentReason = paymentProvider.getReportReason(widget.paymentRequest.id, userId);
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => RequestActionDialog(
        requestId: widget.paymentRequest.id,
        requestDescription: widget.paymentRequest.description.isNotEmpty 
            ? widget.paymentRequest.description 
            : 'Payment Request',
        userId: userId,
        currentStatus: currentStatus,
        currentReason: currentReason,
      ),
    );

    if (result != null && context.mounted) {
      final action = result['action']!;
      final reason = result['reason']!;

      try {
        if (action == 'invalid') {
          await paymentProvider.markRequestAsInvalid(widget.paymentRequest.id, userId, reason);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request marked as invalid - Amount deducted from total owed'),
                backgroundColor: Colors.orange,
              ),
            );
            // Force rebuild of the screen
            setState(() {});
          }
        } else if (action == 'report') {
          await paymentProvider.reportRequest(widget.paymentRequest.id, userId, reason);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request reported for fraud - Amount deducted from total owed'),
                backgroundColor: Colors.red,
              ),
            );
            // Force rebuild of the screen
            setState(() {});
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showPartialPaymentDialog(BuildContext context, PaymentProvider paymentProvider, String userId, String userName) async {
    final currentPartialAmount = widget.paymentRequest.getPartialPaymentAmount(userId);
    final totalAmount = widget.paymentRequest.getAmountForUser(userId, widget.paymentRequest.paymentStatus.keys.toList());
    final remainingAmount = widget.paymentRequest.getRemainingAmount(userId, widget.paymentRequest.paymentStatus.keys.toList());

    final result = await showDialog<double>(
      context: context,
      builder: (context) => PartialPaymentDialog(
        userName: userName,
        totalAmount: totalAmount,
        currentPartialAmount: currentPartialAmount,
        remainingAmount: remainingAmount,
      ),
    );

    if (result != null && context.mounted) {
      try {
        await paymentProvider.updatePartialPayment(widget.paymentRequest.id, userId, result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Partial payment of \$${result.toStringAsFixed(2)} recorded for $userName'),
              backgroundColor: Colors.green,
            ),
          );
          // Force rebuild of the screen
          setState(() {});
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildValidityStatusBadge(BuildContext context, RequestValidityStatus status) {
    switch (status) {
      case RequestValidityStatus.invalid:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withAlpha(77)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.orange[700], size: 16),
              const SizedBox(width: 4),
              Text(
                'Invalid',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case RequestValidityStatus.reported:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withAlpha(77)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.report_problem, color: Colors.red[700], size: 16),
              const SizedBox(width: 4),
              Text(
                'Reported',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Consumer3<PaymentProvider, GroupProvider, AuthProvider>(
          builder: (context, paymentProvider, groupProvider, authProvider, child) {
            final currentUser = authProvider.currentUser!;
            Group group;
            try {
              group = groupProvider.groups.firstWhere(
                (g) => g.id == widget.paymentRequest.groupId,
                orElse: () => Group(
                  id: 'personal',
                  name: 'Personal',
                  description: '',
                  memberIds: [],
                  createdBy: '',
                  createdAt: DateTime.now(),
                ),
              );
            } catch (e) {
              // Fallback for any other errors
              group = Group(
                id: 'personal',
                name: 'Personal',
                description: '',
                memberIds: [],
                createdBy: '',
                createdAt: DateTime.now(),
              );
            }
            final requester = groupProvider.getUserById(widget.paymentRequest.requestedBy);
            List<User> members;
            try {
              members = groupProvider.getGroupMembers(widget.paymentRequest.groupId);
            } catch (e) {
              // Fallback for any errors in getGroupMembers
              members = [];
            }
            final allPayeeIds = widget.paymentRequest.paymentStatus.keys.toList();

            // Determine request type
            String requestType = widget.paymentRequest.description.isNotEmpty
              ? widget.paymentRequest.description
              : 'Payment Request';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row: Request type and total
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            requestType,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '- ',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '\$${widget.paymentRequest.totalAmount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.paymentRequest.isActive)
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
                const SizedBox(height: 4),
                // Group name
                Text(
                  'Group: ${group.id == 'personal' ? 'Personal' : group.name}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 4),
                // Requested by
                Text(
                  'Requested by: ${requester?.id == currentUser?.id ? 'You' : requester?.name ?? 'Unknown'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                // Recurring information
                if (widget.paymentRequest.isRecurring) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withAlpha(77)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.repeat,
                          color: Colors.blue[700],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Recurring: Every ${widget.paymentRequest.recurringInterval} ${_getFrequencyText(widget.paymentRequest.recurringFrequency!)}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showDeleteDialog(context, paymentProvider),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Payee list
                ...allPayeeIds.map((userId) {
                  final user = groupProvider.getUserById(userId);
                  final name = user?.name ?? 'Unknown';
                  final amount = widget.paymentRequest.getAmountForUser(userId, allPayeeIds);
                  final status = widget.paymentRequest.paymentStatus[userId] ?? PaymentStatus.pending;
                  final isPending = status == PaymentStatus.pending;
                  final isPaid = status == PaymentStatus.paid;
                  final isPartial = status == PaymentStatus.partial;
                  final isRequester = userId == widget.paymentRequest.requestedBy;
                  final validityStatus = paymentProvider.getRequestValidityStatus(widget.paymentRequest.id, userId);
                  final isCurrentUser = userId == currentUser.id;
                  final partialAmount = widget.paymentRequest.getPartialPaymentAmount(userId);
                  final remainingAmount = widget.paymentRequest.getRemainingAmount(userId, allPayeeIds);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('$name: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text(' ${amount.toStringAsFixed(2)}'),
                            const SizedBox(width: 8),
                            Text(
                              validityStatus == RequestValidityStatus.invalid ? 'invalid' :
                              validityStatus == RequestValidityStatus.reported ? 'fraudulent' :
                              isPartial ? 'partial' :
                              isPending ? 'pending' : 'paid',
                              style: TextStyle(
                                color: validityStatus == RequestValidityStatus.invalid ? Colors.orange :
                                       validityStatus == RequestValidityStatus.reported ? Colors.red :
                                       isPartial ? Colors.orange :
                                       isPending ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildValidityStatusBadge(context, validityStatus),
                            if (isPending && !isRequester) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  await paymentProvider.updatePaymentStatus(
                                    widget.paymentRequest.id,
                                    userId,
                                    PaymentStatus.paid,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Marked as paid for $name')),
                                    );
                                  }
                                },
                                child: Text(
                                  'Mark as Paid',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Show partial payment information
                        if (isPartial || partialAmount > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(26),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.withAlpha(77)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.payment, size: 16, color: Colors.orange[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Paid: \$${partialAmount.toStringAsFixed(2)} | Remaining: \$${remainingAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Show action buttons for current user if they are a payee and not the requester
                        if (isCurrentUser && (isPending || isPartial) && userId != widget.paymentRequest.requestedBy) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (isPending)
                                OutlinedButton.icon(
                                  onPressed: () => _showRequestActionDialog(context, paymentProvider, userId),
                                  icon: const Icon(Icons.more_vert, size: 16),
                                  label: const Text('Actions'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              if (isPending) const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _showPartialPaymentDialog(context, paymentProvider, userId, name),
                                icon: const Icon(Icons.payment, size: 16),
                                label: const Text('Partial Pay'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (validityStatus == RequestValidityStatus.valid && userId != widget.paymentRequest.requestedBy)
                                Text(
                                  isPending ? 'Tap "Actions" to mark as invalid or report' : 'Tap "Partial Pay" to make a payment',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        // Show prominent status for invalid/reported requests
                        if (isCurrentUser && validityStatus != RequestValidityStatus.valid) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      validityStatus == RequestValidityStatus.invalid 
                                          ? Icons.error_outline 
                                          : Icons.report_problem,
                                      size: 18,
                                      color: validityStatus == RequestValidityStatus.invalid 
                                          ? Colors.orange[700]
                                          : Colors.red[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      validityStatus == RequestValidityStatus.invalid 
                                          ? 'Marked as Invalid'
                                          : 'Reported for Fraud',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: validityStatus == RequestValidityStatus.invalid 
                                            ? Colors.orange[700]
                                            : Colors.red[700],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Amount deducted from total owed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: validityStatus == RequestValidityStatus.invalid 
                                            ? Colors.orange[600]
                                            : Colors.red[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  validityStatus == RequestValidityStatus.invalid
                                      ? paymentProvider.getInvalidationReason(widget.paymentRequest.id, userId) ?? 'No reason provided'
                                      : paymentProvider.getReportReason(widget.paymentRequest.id, userId) ?? 'No reason provided',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: validityStatus == RequestValidityStatus.invalid 
                                        ? Colors.orange[700]
                                        : Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }
} 