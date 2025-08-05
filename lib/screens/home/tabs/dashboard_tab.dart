import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../models/payment_draft.dart';
import '../../payments/create_payment_request_screen.dart';
import '../../payments/draft_detail_screen.dart';
import '../../payments/drafts_screen.dart';
import '../../payments/payment_history_screen.dart';
import '../../groups/create_group_screen.dart';
import '../../payments/recurring_request_options_screen.dart';
import '../../payments/send_money_screen.dart';
import '../../../models/payment_request.dart';
import '../../../models/group.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: Consumer3<AuthProvider, PaymentProvider, GroupProvider>(
        builder: (context, authProvider, paymentProvider, groupProvider, child) {
          final user = authProvider.currentUser;
          if (user == null) return const SizedBox.shrink();

          final userGroups = groupProvider.getGroupsForUser(user.id);
          final totalOwed = paymentProvider.getTotalOwedByUser(user.id);
          final totalOwedToUser = paymentProvider.getTotalOwedToUser(user.id);
          final userDrafts = paymentProvider.getDraftsForUser(user.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                _buildBalanceCard(context, user, totalOwed, totalOwedToUser),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // Requested From You Section
                _buildRequestedFromYouSection(context, paymentProvider, user, groupProvider),
                const SizedBox(height: 24),

                // Groups Summary
                _buildGroupsSummary(context, userGroups),
                const SizedBox(height: 24),

                // Drafts Section
                _buildDraftsSection(context, userDrafts),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, user, double totalOwed, double totalOwedToUser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withAlpha(204),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(76),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withAlpha(204),
                ),
              ),
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white.withAlpha(204),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${user.balance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  context,
                  'You Owe',
                  totalOwed,
                  Colors.red[100]!,
                  Colors.red[700]!,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBalanceItem(
                  context,
                  'Owed to You',
                  totalOwedToUser,
                  Colors.green[100]!,
                  Colors.green[700]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(BuildContext context, String label, double amount, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Send Money',
                Icons.send,
                Colors.blue,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SendMoneyScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Request Money',
                Icons.request_page,
                Colors.orange,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreatePaymentRequestScreen(draft: null),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Create Group',
                Icons.group_add,
                Colors.green,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateGroupScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Add Money',
                Icons.add_circle,
                Colors.purple,
                () {
                  // TODO: Navigate to add money screen
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Create Recurring Request',
                Icons.repeat,
                Colors.teal,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RecurringRequestOptionsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'View History',
                Icons.history,
                Colors.indigo,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PaymentHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestedFromYouSection(BuildContext context, PaymentProvider paymentProvider, user, GroupProvider groupProvider) {
    final requests = paymentProvider.paymentRequests
        .where((req) => req.paymentStatus.containsKey(user.id) && req.requestedBy != user.id && req.isActive)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Requested From You',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (requests.length > 3)
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all requests screen
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.request_page,
                  size: 48,
                  color: Colors.orange[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No requests from others yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When someone requests money from you, it will show up here.',
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
            itemCount: requests.length > 3 ? 3 : requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final groupName = req.groupId == 'personal'
                  ? 'Personal'
                  : groupProvider.groups.firstWhere(
                      (g) => g.id == req.groupId,
                      orElse: () => Group(
                        id: 'unknown',
                        name: 'Unknown Group',
                        description: '',
                        memberIds: [],
                        createdBy: '',
                        createdAt: DateTime.now(),
                      ),
                    ).name;
              final status = req.paymentStatus[user.id];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withAlpha(26),
                    child: Icon(
                      Icons.request_page,
                      color: Colors.orange[700],
                    ),
                  ),
                  title: Text(
                    req.description,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From: ${req.requestedBy}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Group: $groupName',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Amount: \$${req.getAmountForUser(user.id, req.paymentStatus.keys.toList()).toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == PaymentStatus.pending
                          ? Colors.orange.withAlpha(26)
                          : Colors.green.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status == PaymentStatus.pending ? 'Pending' : 'Paid',
                      style: TextStyle(
                        color: status == PaymentStatus.pending
                            ? Colors.orange[700]
                            : Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  onTap: () {
                    // TODO: Navigate to payment request detail screen
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildGroupsSummary(BuildContext context, List userGroups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Groups',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to groups screen
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (userGroups.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No groups yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a group to start splitting expenses',
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
            itemCount: userGroups.length > 3 ? 3 : userGroups.length,
            itemBuilder: (context, index) {
              final group = userGroups[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                    child: Icon(
                      Icons.group,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    group.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${group.memberIds.length} members',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDraftsSection(BuildContext context, List<PaymentDraft> drafts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Drafts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (drafts.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DraftsScreen(),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (drafts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No drafts yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start creating a payment request to save drafts',
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
            itemCount: drafts.length > 3 ? 3 : drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return Dismissible(
                key: Key(draft.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete Draft'),
                        content: const Text(
                          'Are you sure you want to delete this draft? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) async {
                  try {
                    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
                    await paymentProvider.deleteDraft(draft.id);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Draft deleted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting draft: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.withAlpha(26),
                      child: Icon(
                        Icons.edit_outlined,
                        color: Colors.amber[700],
                      ),
                    ),
                    title: Text(
                      draft.displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.displaySubtitle,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Updated: ${DateFormat('MMM dd').format(draft.updatedAt)}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!draft.isComplete)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Incomplete',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navigate to edit draft screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DraftDetailScreen(draft: draft),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
} 