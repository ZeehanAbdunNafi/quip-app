import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/payment_draft.dart';
import '../../models/payment_request.dart';
import 'recurring_request_options_screen.dart';
import 'recurring_frequency_dialog.dart';

// Mock user model for demo
class DemoUser {
  final String id;
  final String name;
  final String number;
  bool hasPaid;
  DemoUser({required this.id, required this.name, required this.number, this.hasPaid = false});
}

// Activity log entry
class DemoRequestLog {
  final String type;
  final DateTime createdAt;
  final double totalAmount;
  final Map<DemoUser, double> requests;
  DemoRequestLog({required this.type, required this.createdAt, required this.totalAmount, required this.requests});
}

class CreatePaymentRequestScreen extends StatefulWidget {
  final PaymentDraft? draft;
  const CreatePaymentRequestScreen({super.key, this.draft});

  @override
  State<CreatePaymentRequestScreen> createState() => _CreatePaymentRequestScreenState();
}

class _CreatePaymentRequestScreenState extends State<CreatePaymentRequestScreen> {
  int _step = 0; // 0: choose, 1: even, 2: varied
  final List<DemoUser> _selectedUsers = [];
  final List<TextEditingController> _amountControllers = [];
  final List<TextEditingController> _percentageControllers = [];
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _lookupController = TextEditingController();
  final TextEditingController _selfPercentageController = TextEditingController();
  bool _includeSelf = false;
  bool _useEvenSplit = true;
  String _summary = '';
  double _evenSplitAmount = 0.0;
  Map<DemoUser, double> _variedSplits = {};
  List<DemoRequestLog> _activityLog = [];
  
  // Draft state
  bool _calculationShown = false;
  PaymentDraft? _currentDraft;

  // Single amount request state
  bool _useSingleAmount = false;
  final TextEditingController _singleAmountController = TextEditingController();

  // Demo/mock users
  final List<DemoUser> _demoUsers = [
    DemoUser(id: '1', name: 'John Doe', number: '+1-555-0123'),
    DemoUser(id: '2', name: 'Sarah Wilson', number: '+1-555-0456'),
    DemoUser(id: '3', name: 'Mike Johnson', number: '+1-555-0789'),
    DemoUser(id: '4', name: 'Emily Davis', number: '+1-555-0124'),
    DemoUser(id: '5', name: 'David Brown', number: '+1-555-0567'),
    DemoUser(id: '6', name: 'Lisa Anderson', number: '+1-555-0890'),
    DemoUser(id: '7', name: 'Alex Chen', number: '+1-555-0234'),
    DemoUser(id: '8', name: 'Rachel Green', number: '+1-555-0678'),
  ];
  final DemoUser _self = DemoUser(id: 'self', name: 'You', number: '000');

  @override
  void initState() {
    super.initState();
    if (widget.draft != null) {
      _loadDraftData(widget.draft!);
    }
  }

  void _loadDraftData(PaymentDraft draft) {
    setState(() {
      _currentDraft = draft;
      _useEvenSplit = draft.type == DraftType.evenSplit;
      _includeSelf = draft.includeSelf;
      
      if (draft.totalAmount != null) {
        _totalAmountController.text = draft.totalAmount!.toString();
      }
      
      if (draft.description != null) {
        // Note: This screen doesn't have a description field, but we could add one
      }
      
      // Load selected users based on draft data
      // This would require mapping user IDs back to DemoUser objects
      // For now, we'll just set the draft
    });
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    _lookupController.dispose();
    _singleAmountController.dispose();
    _selfPercentageController.dispose();
    for (var c in _amountControllers) {
      c.dispose();
    }
    for (var c in _percentageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() {
    setState(() {
      _step = 0;
      _selectedUsers.clear();
      _amountControllers.clear();
      _percentageControllers.clear();
      _totalAmountController.clear();
      _lookupController.clear();
      _singleAmountController.clear();
      _selfPercentageController.clear();
      _includeSelf = false;
      _useEvenSplit = true;
      _useSingleAmount = false;
      _summary = '';
      _evenSplitAmount = 0.0;
      _variedSplits.clear();
      _calculationShown = false;
      _currentDraft = null;
    });
  }

  void _makeRecurringRequest() async {
    if (_currentDraft == null) return;
    
    // Show frequency dialog first
    final frequencyResult = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const RecurringFrequencyDialog(),
    );
    
    if (frequencyResult == null) return; // User cancelled
    
    final interval = frequencyResult['number'] as int;
    final frequency = frequencyResult['frequency'] as RecurringFrequency;
    
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      // Create actual recurring payment request from draft
      await paymentProvider.createPaymentRequest(
        groupId: 'personal', // Use 'personal' for dashboard-created requests
        requestedBy: authProvider.currentUser!.id,
        totalAmount: _currentDraft!.totalAmount ?? 0.0,
        description: _currentDraft!.description ?? 'Recurring payment request',
        includeRequester: _currentDraft!.includeSelf,
        exemptedMembers: [],
        customAmounts: _currentDraft!.customAmounts,
        groupMembers: _currentDraft!.selectedUserIds,
        isRecurring: true,
        recurringInterval: interval,
        recurringFrequency: frequency,
      );
      
      // Delete the draft after creating the request
      await paymentProvider.deleteDraft(_currentDraft!.id);
      
      setState(() {
        _calculationShown = false;
        _currentDraft = null;
        _summary = '';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recurring payment request created successfully! Will recur every $interval ${_getFrequencyText(frequency)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _getFrequencyText(RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'day(s)';
      case RecurringFrequency.weekly:
        return 'week(s)';
      case RecurringFrequency.monthly:
        return 'month(s)';
      default:
        return 'day(s)';
    }
  }

  void _makeRequest() async {
    if (_currentDraft == null) return;
    
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      try {
        // Convert draft to payment request and delete the draft
        await paymentProvider.convertDraftToRequest(
          draftId: _currentDraft!.id,
          groupId: 'personal', // Use 'personal' for dashboard-created requests
          requestedBy: authProvider.currentUser!.id,
          groupMembers: _currentDraft!.selectedUserIds,
        );
        
        setState(() {
          _calculationShown = false;
          _currentDraft = null;
          _summary = '';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment request created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating payment request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addUser(DemoUser user) {
    if (!_selectedUsers.contains(user)) {
      setState(() {
        _selectedUsers.add(user);
        _amountControllers.add(TextEditingController());
        _percentageControllers.add(TextEditingController());
      });
    }
  }

  void _removeUser(int index) {
    setState(() {
      _selectedUsers.removeAt(index);
      _amountControllers.removeAt(index);
      _percentageControllers.removeAt(index);
    });
  }

  void _toggleEvenSplit(bool? value) {
    setState(() {
      _useEvenSplit = value ?? true;
      if (_useEvenSplit) {
        // Clear percentage fields when switching to even split
        for (var controller in _percentageControllers) {
          controller.clear();
        }
        _selfPercentageController.clear();
      }
    });
  }

  void _toggleSingleAmount(bool? value) {
    setState(() {
      _useSingleAmount = value ?? false;
      if (_useSingleAmount) {
        // Clear all amount fields when switching to single amount mode
        for (var controller in _amountControllers) {
          controller.clear();
        }
      }
    });
  }

  void _applySingleAmount() {
    if (!_useSingleAmount) return;
    
    final amount = _singleAmountController.text;
    if (amount.isNotEmpty) {
      final doubleValue = double.tryParse(amount);
      if (doubleValue != null && doubleValue > 0) {
        setState(() {
          for (int i = 0; i < _selectedUsers.length; i++) {
            _amountControllers[i].text = doubleValue.toStringAsFixed(2);
          }
        });
      }
    }
  }

  double _calculateTotalPercentage() {
    double total = 0.0;
    for (var controller in _percentageControllers) {
      final percentage = double.tryParse(controller.text) ?? 0.0;
      total += percentage;
    }
    if (_includeSelf) {
      final selfPercentage = double.tryParse(_selfPercentageController.text) ?? 0.0;
      total += selfPercentage;
    }
    return total;
  }

  void _calculateEvenSplit() async {
    final total = double.tryParse(_totalAmountController.text) ?? 0.0;
    int count = _selectedUsers.length + (_includeSelf ? 1 : 0);
    if (total <= 0 || count == 0) return;
    
    Map<DemoUser, double> splits = {};
    
    if (_useEvenSplit) {
      // Regular even split
      final split = (total / count);
      for (var user in _selectedUsers) {
        splits[user] = split;
      }
      if (_includeSelf) {
        splits[_self] = split;
      }
      setState(() {
        _evenSplitAmount = split;
        _calculationShown = true;
        _summary = 'Each person owes: \$${split.toStringAsFixed(2)}';
      });
    } else {
      // Custom percentage split
      final totalPercentage = _calculateTotalPercentage();
      if (totalPercentage != 100.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Total percentage must equal 100%. Current: ${totalPercentage.toStringAsFixed(1)}%'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      for (int i = 0; i < _selectedUsers.length; i++) {
        final percentage = double.tryParse(_percentageControllers[i].text) ?? 0.0;
        splits[_selectedUsers[i]] = (total * percentage) / 100.0;
      }
      if (_includeSelf) {
        final selfPercentage = double.tryParse(_selfPercentageController.text) ?? 0.0;
        splits[_self] = (total * selfPercentage) / 100.0;
      }
      
      setState(() {
        _calculationShown = true;
        _summary = splits.entries.map((e) => '${e.key.name}: \$${e.value.toStringAsFixed(2)} (${((e.value / total) * 100).toStringAsFixed(1)}%)').join('\n');
      });
    }

    // Create draft
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      final selectedUserIds = _selectedUsers.map((u) => u.id).toList();
      if (_includeSelf) selectedUserIds.add('self');
      
      final customAmounts = <String, double>{};
      for (var entry in splits.entries) {
        customAmounts[entry.key.id] = entry.value;
      }

      _currentDraft = await paymentProvider.createDraft(
        userId: authProvider.currentUser!.id,
        type: DraftType.evenSplit,
        totalAmount: total,
        description: _useEvenSplit ? 'Even split request' : 'Custom percentage split',
        selectedUserIds: selectedUserIds,
        customAmounts: customAmounts,
        includeSelf: _includeSelf,
      );
    }
  }

  void _calculateRecurringSplit() async {
    double total = 0.0;
    final splits = <DemoUser, double>{};
    
    for (int i = 0; i < _selectedUsers.length; i++) {
      final amt = double.tryParse(_amountControllers[i].text) ?? 0.0;
      if (amt > 0) {
        splits[_selectedUsers[i]] = amt;
        total += amt;
      }
    }
    
    if (splits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid amounts for selected users.')),
      );
      return;
    }
    
    setState(() {
      _variedSplits = splits;
      _calculationShown = true;
      _summary = splits.entries.map((e) => '${e.key.name}: \$${e.value.toStringAsFixed(2)}').join('\n');
    });

    // Create draft for recurring request
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      final selectedUserIds = _selectedUsers.map((u) => u.id).toList();
      final customAmounts = <String, double>{};
      for (var entry in splits.entries) {
        customAmounts[entry.key.id] = entry.value;
      }

      _currentDraft = await paymentProvider.createDraft(
        userId: authProvider.currentUser!.id,
        type: DraftType.variedSplit,
        totalAmount: total,
        description: 'Recurring Request from Individual(s)',
        selectedUserIds: selectedUserIds,
        customAmounts: customAmounts,
        includeSelf: false,
      );
    }
  }

  void _calculateVariedSplit() async {
    double total = 0.0;
    final splits = <DemoUser, double>{};
    
    if (_useSingleAmount) {
      final singleAmount = double.tryParse(_singleAmountController.text) ?? 0.0;
      if (singleAmount > 0) {
        for (var user in _selectedUsers) {
          splits[user] = singleAmount;
          total += singleAmount;
        }
      }
    } else {
    for (int i = 0; i < _selectedUsers.length; i++) {
      final amt = double.tryParse(_amountControllers[i].text) ?? 0.0;
      if (amt > 0) {
        splits[_selectedUsers[i]] = amt;
        total += amt;
      }
    }
    }
    
    if (splits.isEmpty) return;
    
    setState(() {
      _variedSplits = splits;
      _calculationShown = true;
      _summary = splits.entries.map((e) => '${e.key.name}: \$${e.value.toStringAsFixed(2)}').join('\n');
    });

    // Create draft
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      final selectedUserIds = _selectedUsers.map((u) => u.id).toList();
      final customAmounts = <String, double>{};
      for (var entry in splits.entries) {
        customAmounts[entry.key.id] = entry.value;
      }

      _currentDraft = await paymentProvider.createDraft(
        userId: authProvider.currentUser!.id,
        type: DraftType.variedSplit,
        totalAmount: total,
        description: 'Request from Individual(s)',
        selectedUserIds: selectedUserIds,
        customAmounts: customAmounts,
        includeSelf: false,
      );
    }
  }



  Widget _buildOptionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Request a split'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => setState(() => _step = 2),
          child: const Text('Request from individuals'),
        ),
      ],
    );
  }

  Widget _buildEvenSplit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Add people by name or phone number:'),
        Wrap(
          spacing: 8,
          children: _demoUsers.map((u) => FilterChip(
            label: Text('${u.name} (${u.number})'),
            selected: _selectedUsers.contains(u),
            onSelected: (sel) {
              if (sel) {
                _addUser(u);
              } else {
                final idx = _selectedUsers.indexOf(u);
                if (idx != -1) _removeUser(idx);
              }
            },
          )).toList(),
        ),
        
        // Selected Users Queue
        if (_selectedUsers.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected People (${_selectedUsers.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._selectedUsers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final user = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: Text(
                              user.name[0],
                              style: TextStyle(
                                color: Colors.blue[700],
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
                                  user.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  user.number,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_useEvenSplit) ...[
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _percentageControllers[index],
                                decoration: const InputDecoration(
                                  labelText: '%',
                                  border: OutlineInputBorder(),
                                  hintText: '0',
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                onChanged: (value) {
                                  setState(() {
                                    // Trigger rebuild to update total percentage
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeUser(index),
                            tooltip: 'Remove ${user.name}',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (_includeSelf) ...[
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Current user',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_useEvenSplit) ...[
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _selfPercentageController,
                                decoration: const InputDecoration(
                                  labelText: '%',
                                  border: OutlineInputBorder(),
                                  hintText: '0',
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                onChanged: (value) {
                                  setState(() {
                                    // Trigger rebuild to update total percentage
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _includeSelf = false;
                              });
                            },
                            tooltip: 'Remove You',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        
        CheckboxListTile(
          title: const Text('Include myself'),
          value: _includeSelf,
          onChanged: (v) => setState(() => _includeSelf = v ?? false),
        ),
        
        // Even Split Checkbox
        CheckboxListTile(
          title: const Text('Even split'),
          subtitle: const Text('Split equally among all selected people'),
          value: _useEvenSplit,
          onChanged: _toggleEvenSplit,
        ),
        
        const SizedBox(height: 16),
        TextField(
          controller: _totalAmountController,
          decoration: const InputDecoration(labelText: 'Total amount to split'),
          keyboardType: TextInputType.number,
        ),
        
        // Percentage Input Fields (when even split is unchecked)
        if (!_useEvenSplit && (_selectedUsers.isNotEmpty || _includeSelf)) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Percentage for Each Person',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total must equal 100%',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._selectedUsers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final user = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: Text(
                              user.name[0],
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _percentageControllers[index],
                              decoration: const InputDecoration(
                                labelText: '%',
                                border: OutlineInputBorder(),
                                hintText: '0',
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (_includeSelf) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                          Expanded(
                            child: Text(
                              'You',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _selfPercentageController,
                              decoration: const InputDecoration(
                                labelText: '%',
                                border: OutlineInputBorder(),
                                hintText: '0',
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${_calculateTotalPercentage().toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _calculateTotalPercentage() == 100.0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        if (!_calculationShown) ...[
          ElevatedButton(
            onPressed: _calculateEvenSplit,
            child: const Text('Calculate Split'),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Split Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_summary),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _makeRequest,
                          child: const Text('Create Request'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _calculationShown = false;
                              _currentDraft = null;
                              _summary = '';
                            });
                          },
                          child: const Text('Edit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecurringRequest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Create a recurring request from individuals:'),
        const SizedBox(height: 16),
        const Text('Add people by name or phone number:'),
        Wrap(
          spacing: 8,
          children: _demoUsers.map((u) => FilterChip(
            label: Text('${u.name} (${u.number})'),
            selected: _selectedUsers.contains(u),
            onSelected: (sel) {
              if (sel) {
                _addUser(u);
              } else {
                final idx = _selectedUsers.indexOf(u);
                if (idx != -1) _removeUser(idx);
              }
            },
          )).toList(),
        ),
        const SizedBox(height: 16),
        
        // Amount inputs for selected users
        if (_selectedUsers.isNotEmpty) ...[
          const Text('Enter amounts for each person:'),
          const SizedBox(height: 8),
          ..._selectedUsers.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('${user.name}:'),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _amountControllers[index],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          const SizedBox(height: 16),
          
          // Calculate button
          ElevatedButton(
            onPressed: _calculateRecurringSplit,
            child: const Text('Calculate Recurring Request'),
          ),
          
          if (_calculationShown) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recurring Request Summary:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_summary),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _makeRecurringRequest,
                        child: const Text('Create Recurring Request'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildVariedSplit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Add people by name or phone number:'),
        Wrap(
          spacing: 8,
          children: _demoUsers.map((u) => FilterChip(
            label: Text('${u.name} (${u.number})'),
            selected: _selectedUsers.contains(u),
            onSelected: (sel) {
              if (sel) {
                _addUser(u);
              } else {
                final idx = _selectedUsers.indexOf(u);
                if (idx != -1) _removeUser(idx);
              }
            },
          )).toList(),
        ),
        const SizedBox(height: 16),

        // Single amount request option
        if (_selectedUsers.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    title: const Text('Request one amount from the people selected'),
                    value: _useSingleAmount,
                    onChanged: _toggleSingleAmount,
                  ),
                  if (_useSingleAmount) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _singleAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Amount for all selected people',
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                              hintText: 'Enter amount',
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) => _applySingleAmount(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _applySingleAmount,
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Individual amount inputs
        if (!_useSingleAmount) ...[
        ...List.generate(_selectedUsers.length, (i) => Row(
          children: [
            Expanded(child: Text(_selectedUsers[i].name)),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _amountControllers[i],
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeUser(i),
            ),
          ],
        )),
        const SizedBox(height: 16),
        ] else ...[
          // Show selected users with auto-filled amounts
          ...List.generate(_selectedUsers.length, (i) => Row(
            children: [
              Expanded(child: Text(_selectedUsers[i].name)),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _amountControllers[i],
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Auto-filled',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => _removeUser(i),
              ),
            ],
          )),
          const SizedBox(height: 16),
        ],
        if (!_calculationShown) ...[
          ElevatedButton(
            onPressed: _calculateVariedSplit,
            child: const Text('Calculate Split'),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withAlpha(77)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Calculation Result',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_summary, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _makeRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Make Request'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _calculationShown = false;
                            _currentDraft = null;
                            _summary = '';
                          });
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextButton(onPressed: _reset, child: const Text('Back')),
      ],
    );
  }



  Widget _buildActivityLog() {
    if (_activityLog.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No recent activity.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold)),
        ..._activityLog.map((log) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text('${log.type} - \$${log.totalAmount.toStringAsFixed(2)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Created: ${DateFormat('yyyy-MM-dd HH:mm').format(log.createdAt)}'),
                ...log.requests.entries.map((e) => Row(
                  children: [
                    Text('${e.key.name}: \$${e.value.toStringAsFixed(2)}'),
                    const SizedBox(width: 8),
                    if (e.key.name != 'You')
                      e.key.hasPaid
                        ? Text(
                            'paid',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Row(
                            children: [
                              Text(
                                'pending',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(40, 24),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setState(() {
                                    e.key.hasPaid = true;
                                  });
                                },
                                child: const Text(
                                  'Mark as Paid',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                    if (e.key.hasPaid && e.key.name != 'You')
                      const SizedBox(width: 4),
                    if (e.key.hasPaid && e.key.name != 'You')
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ],
                )),
              ],
            ),
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Money')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_step == 0) _buildOptionSelector(),
            if (_step == 1) _buildEvenSplit(),
            if (_step == 2) _buildVariedSplit(),

            const SizedBox(height: 32),
            _buildActivityLog(),
          ],
        ),
      ),
    );
  }
} 