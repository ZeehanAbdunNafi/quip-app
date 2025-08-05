import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/group.dart';
import '../payments/create_payment_request_screen.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import 'even_split_request_screen.dart';
import 'varied_split_request_screen.dart';
import '../../models/payment_request.dart';
import '../payments/recurring_request_options_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer3<GroupProvider, PaymentProvider, AuthProvider>(
        builder: (context, groupProvider, paymentProvider, authProvider, child) {
          final members = groupProvider.getGroupMembers(group.id);
          final paymentRequests = paymentProvider.getPaymentRequestsForGroup(group.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Info Card
                _buildGroupInfoCard(context),
                const SizedBox(height: 24),

                // Members Section
                _buildMembersSection(context, members, groupProvider),
                const SizedBox(height: 24),

                // Payment Requests Section
                _buildPaymentRequestsSection(context, paymentRequests, groupProvider, authProvider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.equalizer),
                    title: const Text('Request a split'),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToEvenSplitScreen(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.scatter_plot),
                    title: const Text('Request from individuals'),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToVariedSplitScreen(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.repeat),
                    title: const Text('Create a recurring request'),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToRecurringRequestScreen(context);
                    },
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Request Payment',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGroupInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
                  child: Icon(
                    Icons.group,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created ${_formatDate(group.createdAt)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                group.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, List members, GroupProvider groupProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Members (${members.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // TODO: Navigate to add members screen
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isCreator = member.id == group.createdBy;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (isCreator) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(member.email),
                trailing: isCreator
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          _showMemberOptions(context, member, groupProvider);
                        },
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRequestsSection(BuildContext context, List paymentRequests, GroupProvider groupProvider, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Payment Requests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all payment requests screen
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (paymentRequests.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No payment requests yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create the first payment request for this group',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paymentRequests.length > 3 ? 3 : paymentRequests.length,
            itemBuilder: (context, index) {
              final payment = paymentRequests[index];
              final requester = groupProvider.getUserById(payment.requestedBy);
              final involvedUserIds = payment.paymentStatus.keys.toList();
              final isEvenSplit = payment.customAmounts.isEmpty;
              final type = isEvenSplit ? 'Even Split' : 'Request from Individual(s)';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$type - \$${payment.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDate(payment.createdAt),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested by: ${requester?.id == authProvider.currentUser?.id ? 'You' : requester?.name ?? 'Unknown'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ...involvedUserIds.map((userId) {
                        final user = groupProvider.getUserById(userId);
                        final status = payment.paymentStatus[userId];
                        final amount = payment.getAmountForUser(userId, involvedUserIds);
                        return Row(
                          children: [
                            Text(
                              '${user?.name ?? 'Unknown'}: \$${amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            if (status == PaymentStatus.paid)
                              Row(
                                children: const [
                                  Text('paid', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 4),
                                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  const Text('pending', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  if (payment.requestedBy != authProvider.currentUser?.id) ...[
                                    const SizedBox(width: 4),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(40, 24),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
                                        paymentProvider.updatePaymentStatus(payment.id, userId, PaymentStatus.paid);
                                      },
                                      child: const Text('Mark as Paid', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showMemberOptions(BuildContext context, member, GroupProvider groupProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
              title: const Text('Remove from Group'),
              onTap: () {
                Navigator.of(context).pop();
                _removeMember(context, member, groupProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeMember(BuildContext context, member, GroupProvider groupProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.name} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await groupProvider.removeMemberFromGroup(group.id, member.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.name} removed from group'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing member: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
    if (payment.isCompleted) return 'Completed';
    if (payment.pendingPaymentsCount > 0) return 'Pending';
    return 'Cancelled';
  }

  void _navigateToEvenSplitScreen(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final members = List<User>.from(groupProvider.getGroupMembers(group.id));
    final currentUser = authProvider.currentUser;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EvenSplitRequestScreen(
          group: group,
          members: members,
          currentUser: currentUser,
        ),
      ),
    );
  }

  void _navigateToVariedSplitScreen(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final members = List<User>.from(groupProvider.getGroupMembers(group.id));
    final currentUser = authProvider.currentUser;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VariedSplitRequestScreen(
          group: group,
          members: members,
          currentUser: currentUser,
        ),
      ),
    );
  }

  void _navigateToRecurringRequestScreen(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final members = List<User>.from(groupProvider.getGroupMembers(group.id));
    final currentUser = authProvider.currentUser;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecurringRequestOptionsScreen(
          group: group,
          members: members,
          currentUser: currentUser,
        ),
      ),
    );
  }
} 