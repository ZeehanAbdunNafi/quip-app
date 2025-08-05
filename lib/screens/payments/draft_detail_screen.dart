import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/payment_draft.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/user.dart';
import '../../models/group.dart';
import 'create_payment_request_screen.dart';
import '../groups/even_split_request_screen.dart';
import '../groups/varied_split_request_screen.dart';

class DraftDetailScreen extends StatelessWidget {
  final PaymentDraft draft;
  
  const DraftDetailScreen({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Enhanced: Navigate to the correct edit screen based on draft type and group
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final currentUser = authProvider.currentUser;
              if ((draft.groupId == null || draft.groupId == 'personal')) {
                // Personal request
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => CreatePaymentRequestScreen(draft: draft),
                  ),
                );
              } else {
                // Group request
                final group = groupProvider.groups.firstWhere(
                  (g) => g.id == draft.groupId,
                  orElse: () => Group(
                    id: draft.groupId!,
                    name: 'Unknown Group',
                    description: '',
                    memberIds: draft.selectedUserIds,
                    createdBy: '',
                    createdAt: DateTime.now(),
                  ),
                );
                final members = groupProvider.getGroupMembers(draft.groupId!);
                if (draft.type == DraftType.evenSplit) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => EvenSplitRequestScreen(
                        group: group,
                        members: members,
                        currentUser: currentUser,
                        draft: draft,
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => VariedSplitRequestScreen(
                        group: group,
                        members: members,
                        currentUser: currentUser,
                        draft: draft,
                      ),
                    ),
                  );
                }
              }
            },
            tooltip: 'Edit Draft',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
            tooltip: 'Delete Draft',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            _buildSplitDetailsCard(context),
            const SizedBox(height: 16),
            _buildParticipantsCard(context),
            const SizedBox(height: 16),
            _buildTimelineCard(context),
            const SizedBox(height: 32),
            // Add Make The Request button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Make The Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final currentUser = authProvider.currentUser;
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You must be logged in to make a request.'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  try {
                    await paymentProvider.convertDraftToRequest(
                      draftId: draft.id,
                      groupId: draft.groupId ?? 'personal',
                      requestedBy: currentUser.id,
                      groupMembers: draft.selectedUserIds,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request created successfully!'), backgroundColor: Colors.green),
                      );
                      Navigator.of(context).pop(); // Go back after making request
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            // Add Delete Draft button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Delete Draft', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showDeleteConfirmation(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Draft'),
          content: const Text(
            'Are you sure you want to delete this draft? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteDraft(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDraft(BuildContext context) async {
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
        Navigator.of(context).pop(); // Go back to previous screen
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
  }

  Widget _buildHeaderCard(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    String groupName = 'Personal';
    
    if (draft.groupId != null && draft.groupId != 'personal') {
      try {
        final group = groupProvider.groups.firstWhere((g) => g.id == draft.groupId);
        groupName = group.name;
      } catch (e) {
        groupName = 'Unknown Group';
      }
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.amber.withAlpha(26),
                  child: Icon(
                    Icons.edit_outlined,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Split Request',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Draft',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Group',
                    groupName,
                    Icons.group,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Total Amount',
                    '\$${draft.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Participants',
                    '${draft.selectedUserIds.length + (draft.includeSelf ? 1 : 0)}',
                    Icons.people,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(), // Empty container for spacing
                ),
              ],
            ),
            if (draft.description != null && draft.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                draft.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitDetailsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Split Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (draft.customAmounts.isNotEmpty) ...[
              ...draft.customAmounts.entries.map((entry) {
                final userId = entry.key;
                final amount = entry.value;
                final isSelf = userId == 'self';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelf 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        child: Text(
                          isSelf ? 'Y' : userId[0].toUpperCase(),
                          style: TextStyle(
                            color: isSelf ? Colors.green[700] : Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSelf ? 'You' : 'User $userId',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (draft.totalAmount != null && draft.totalAmount! > 0) ...[
                              Text(
                                '${((amount / draft.totalAmount!) * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else if (draft.totalAmount != null && draft.totalAmount! > 0) ...[
              Text(
                'Even split among ${draft.selectedUserIds.length + (draft.includeSelf ? 1 : 0)} participants',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Each person owes: \$${(draft.totalAmount! / (draft.selectedUserIds.length + (draft.includeSelf ? 1 : 0))).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...draft.selectedUserIds.map((userId) {
              final isSelf = userId == 'self';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isSelf 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      child: Text(
                        isSelf ? 'Y' : userId[0].toUpperCase(),
                        style: TextStyle(
                          color: isSelf ? Colors.green[700] : Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isSelf ? 'You' : 'User $userId',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (isSelf)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            if (draft.includeSelf && !draft.selectedUserIds.contains('self')) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: Text(
                        'Y',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'You',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'You',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              context,
              'Draft Created',
              draft.createdAt,
              Icons.edit_outlined,
              Colors.amber,
            ),
            _buildTimelineItem(
              context,
              'Last Updated',
              draft.updatedAt,
              Icons.update,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    DateTime date,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 