import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../groups/even_split_request_screen.dart';
import '../groups/varied_split_request_screen.dart';
import 'create_payment_request_screen.dart';

class RecurringRequestOptionsScreen extends StatelessWidget {
  final Group? group;
  final List<User>? members;
  final User? currentUser;

  const RecurringRequestOptionsScreen({
    Key? key,
    this.group,
    this.members,
    this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Recurring Request'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how you want to create your recurring request:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            
            // Option 1: Recurring request to split
            Card(
              child: InkWell(
                onTap: () {
                  if (group != null && members != null && currentUser != null) {
                    // Group context - use existing split screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EvenSplitRequestScreen(
                          group: group!,
                          members: members!,
                          currentUser: currentUser,
                          isRecurring: true,
                        ),
                      ),
                    );
                  } else {
                    // Dashboard context - use same algorithm with mock data
                    _showDashboardSplitRequest(context);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.equalizer,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create a recurring request to split',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set up a recurring payment that splits evenly among group members',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Option 2: Recurring request from individuals
            Card(
              child: InkWell(
                onTap: () {
                  if (group != null && members != null && currentUser != null) {
                    // Group context - use existing varied split screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VariedSplitRequestScreen(
                          group: group!,
                          members: members!,
                          currentUser: currentUser,
                          isRecurring: true,
                        ),
                      ),
                    );
                  } else {
                    // Dashboard context - use same algorithm with mock data
                    _showDashboardIndividualRequest(context);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.scatter_plot,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create a recurring request from individuals',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set up a recurring payment with custom amounts from specific members',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDashboardSplitRequest(BuildContext context) {
    // Mock data for dashboard split request
    final mockGroup = Group(
      id: 'dashboard-group',
      name: 'Dashboard Group',
      description: 'Temporary group for dashboard requests',
      memberIds: ['user1', 'user2', 'user3'],
      createdBy: 'current-user',
      createdAt: DateTime.now(),
    );

    final mockMembers = [
      User(
        id: 'user1', 
        name: 'John Doe', 
        email: 'john@example.com',
        createdAt: DateTime.now(),
      ),
      User(
        id: 'user2', 
        name: 'Jane Smith', 
        email: 'jane@example.com',
        createdAt: DateTime.now(),
      ),
      User(
        id: 'user3', 
        name: 'Bob Johnson', 
        email: 'bob@example.com',
        createdAt: DateTime.now(),
      ),
    ];

    final mockCurrentUser = User(
      id: 'current-user',
      name: 'Current User',
      email: 'current@example.com',
      createdAt: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EvenSplitRequestScreen(
          group: mockGroup,
          members: mockMembers,
          currentUser: mockCurrentUser,
          isRecurring: true,
        ),
      ),
    );
  }

  void _showDashboardIndividualRequest(BuildContext context) {
    // Mock data for dashboard individual request
    final mockGroup = Group(
      id: 'dashboard-group',
      name: 'Dashboard Group',
      description: 'Temporary group for dashboard requests',
      memberIds: ['user1', 'user2', 'user3'],
      createdBy: 'current-user',
      createdAt: DateTime.now(),
    );

    final mockMembers = [
      User(
        id: 'user1', 
        name: 'John Doe', 
        email: 'john@example.com',
        createdAt: DateTime.now(),
      ),
      User(
        id: 'user2', 
        name: 'Jane Smith', 
        email: 'jane@example.com',
        createdAt: DateTime.now(),
      ),
      User(
        id: 'user3', 
        name: 'Bob Johnson', 
        email: 'bob@example.com',
        createdAt: DateTime.now(),
      ),
    ];

    final mockCurrentUser = User(
      id: 'current-user',
      name: 'Current User',
      email: 'current@example.com',
      createdAt: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VariedSplitRequestScreen(
          group: mockGroup,
          members: mockMembers,
          currentUser: mockCurrentUser,
          isRecurring: true,
        ),
      ),
    );
  }
} 