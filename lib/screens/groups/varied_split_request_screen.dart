import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/payment_draft.dart';
import '../payments/recurring_frequency_dialog.dart';
import '../../models/payment_request.dart';
import '../../providers/group_provider.dart';

class VariedSplitRequestScreen extends StatefulWidget {
  final Group group;
  final List<User> members;
  final User? currentUser;
  final bool isRecurring;
  final PaymentDraft? draft;
  
  const VariedSplitRequestScreen({
    Key? key,
    required this.group,
    required this.members,
    required this.currentUser,
    this.isRecurring = false,
    this.draft,
  }) : super(key: key);

  @override
  State<VariedSplitRequestScreen> createState() => _VariedSplitRequestScreenState();
}

class _VariedSplitRequestScreenState extends State<VariedSplitRequestScreen> {
  late List<User> _allMembers;
  late List<bool> _selected;
  late List<TextEditingController> _amountControllers;
  bool _selectAll = true;
  bool _includeSelf = true;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _singleAmountController = TextEditingController();
  bool _proceeding = false;
  bool _useSingleAmount = false;
  PaymentDraft? _currentDraft;

  @override
  void initState() {
    super.initState();
    _allMembers = List<User>.from(widget.members);
    if (widget.currentUser != null && !_allMembers.any((u) => u.id == widget.currentUser!.id)) {
      _allMembers.add(widget.currentUser!);
    }
    // If editing a draft, ensure all draft.selectedUserIds are present in _allMembers
    if (widget.draft != null) {
      final draft = widget.draft!;
      final contextGroupProvider = context.mounted ? Provider.of<GroupProvider>(context, listen: false) : null;
      for (final userId in draft.selectedUserIds) {
        if (!_allMembers.any((u) => u.id == userId)) {
          // Try to get user from provider, else add a placeholder
          User? user;
          if (contextGroupProvider != null) {
            user = contextGroupProvider.getUserById(userId);
          }
          user ??= User(
            id: userId,
            name: 'User $userId',
            email: '',
            phoneNumber: '',
            createdAt: DateTime.now(),
            balance: 0.0,
          );
          _allMembers.add(user);
        }
      }
    }
    _selected = List.filled(_allMembers.length, true);
    _amountControllers = List.generate(
      _allMembers.length,
      (index) => TextEditingController(),
    );
    // If editing a draft, pre-fill all fields
    if (widget.draft != null) {
      final draft = widget.draft!;
      // Set description
      if (draft.description != null) {
        _descriptionController.text = draft.description!;
      }
      // Set includeSelf
      _includeSelf = draft.includeSelf;
      // Set selected members
      for (int i = 0; i < _allMembers.length; i++) {
        final user = _allMembers[i];
        _selected[i] = draft.selectedUserIds.contains(user.id) || (user.id == 'self' && draft.includeSelf);
      }
      _selectAll = _selected.every((v) => v);
      // Set amounts
      if (draft.customAmounts.isNotEmpty) {
        // If all selected members have the same amount, use single amount mode
        final selectedIds = draft.selectedUserIds.toSet();
        final amounts = selectedIds.map((id) => draft.customAmounts[id] ?? 0.0).toSet();
        if (amounts.length == 1 && amounts.first > 0) {
          _useSingleAmount = true;
          _singleAmountController.text = amounts.first.toStringAsFixed(2);
          for (int i = 0; i < _allMembers.length; i++) {
            if (_selected[i]) {
              _amountControllers[i].text = amounts.first.toStringAsFixed(2);
            }
          }
        } else {
          _useSingleAmount = false;
          for (int i = 0; i < _allMembers.length; i++) {
            final user = _allMembers[i];
            if (draft.customAmounts.containsKey(user.id)) {
              _amountControllers[i].text = draft.customAmounts[user.id]!.toStringAsFixed(2);
            } else {
              _amountControllers[i].clear();
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _singleAmountController.dispose();
    for (var controller in _amountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      for (int i = 0; i < _selected.length; i++) {
        _selected[i] = _selectAll;
      }
      if (widget.currentUser != null) {
        _includeSelf = _selectAll;
      }
    });
  }

  void _toggleMember(int index, bool? value) {
    setState(() {
      _selected[index] = value ?? false;
      _selectAll = _selected.every((v) => v);
      if (widget.currentUser != null && index == _allMembers.length - 1) {
        _includeSelf = _selected[index];
      }
    });
  }

  void _toggleIncludeSelf(bool? value) {
    if (widget.currentUser == null) return;
    setState(() {
      _includeSelf = value ?? false;
      _selected[_allMembers.length - 1] = _includeSelf;
      _selectAll = _selected.every((v) => v);
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
          for (int i = 0; i < _allMembers.length; i++) {
            if (_selected[i]) {
              _amountControllers[i].text = doubleValue.toStringAsFixed(2);
            }
          }
        });
      }
    }
  }

  double _calculateTotal() {
    double total = 0.0;
    
    if (_useSingleAmount) {
      final singleAmount = double.tryParse(_singleAmountController.text) ?? 0.0;
      final selectedCount = _selected.where((selected) => selected).length;
      total = singleAmount * selectedCount;
    } else {
    for (int i = 0; i < _allMembers.length; i++) {
      if (_selected[i]) {
        final amount = double.tryParse(_amountControllers[i].text) ?? 0.0;
        total += amount;
      }
    }
    }
    
    return total;
  }

  Map<String, double> _getCustomAmounts() {
    final customAmounts = <String, double>{};
    
    if (_useSingleAmount) {
      final singleAmount = double.tryParse(_singleAmountController.text) ?? 0.0;
      if (singleAmount > 0) {
        for (int i = 0; i < _allMembers.length; i++) {
          if (_selected[i]) {
            customAmounts[_allMembers[i].id] = singleAmount;
          }
        }
      }
    } else {
    for (int i = 0; i < _allMembers.length; i++) {
      if (_selected[i]) {
        final amount = double.tryParse(_amountControllers[i].text) ?? 0.0;
        if (amount > 0) {
          customAmounts[_allMembers[i].id] = amount;
        }
      }
    }
    }
    
    return customAmounts;
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

  void _proceed() async {
    final selectedMembers = <User>[];
    for (int i = 0; i < _allMembers.length; i++) {
      if (_selected[i]) selectedMembers.add(_allMembers[i]);
    }
    
    final customAmounts = _getCustomAmounts();
    final total = _calculateTotal();
    
    if (selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member.')),
      );
      return;
    }
    
    if (_useSingleAmount) {
      final singleAmount = double.tryParse(_singleAmountController.text);
      if (singleAmount == null || singleAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount for all selected members.')),
        );
        return;
      }
    } else if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid amounts for selected members.')),
      );
      return;
    }

    // Create draft
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      final selectedUserIds = selectedMembers.map((u) => u.id).toList();
      
      final description = widget.isRecurring
          ? (_descriptionController.text.isNotEmpty 
              ? 'Recurring ${_descriptionController.text}' 
              : 'Recurring Request from Individual(s)')
          : (_descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : 'Request from Individual(s)');

      _currentDraft = await paymentProvider.createDraft(
        userId: authProvider.currentUser!.id,
        type: DraftType.variedSplit,
        groupId: widget.group.id,
        totalAmount: total,
        description: description,
        selectedUserIds: selectedUserIds,
        customAmounts: customAmounts,
        includeSelf: _includeSelf,
      );
    }

    if (widget.isRecurring) {
      // Show frequency dialog for recurring requests
      final frequencyResult = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const RecurringFrequencyDialog(),
      );
      
      if (frequencyResult == null) return; // User cancelled
      
      final interval = frequencyResult['number'] as int;
      final frequency = frequencyResult['frequency'] as RecurringFrequency;
      
      // Show summary dialog with frequency info
      _showSummaryDialog(customAmounts, total, interval, frequency);
    } else {
      // Show regular summary dialog for non-recurring requests
      _showSummaryDialog(customAmounts, total, null, null);
    }
  }

  void _showSummaryDialog(Map<String, double> customAmounts, double total, int? interval, RecurringFrequency? frequency) {
    final titlePrefix = widget.isRecurring ? 'Recurring ' : '';
    final frequencyText = widget.isRecurring && interval != null && frequency != null
        ? '\n\nFrequency: Every $interval ${_getFrequencyText(frequency)}'
        : '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${titlePrefix}Request from Individual(s) Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Group: ${widget.group.id == 'personal' ? 'Personal' : widget.group.name}'),
              const SizedBox(height: 8),
              Text('Total Amount: \$${total.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              ...customAmounts.entries.map((entry) {
                final member = _allMembers.firstWhere((m) => m.id == entry.key);
                return Text('${member.name}: \$${entry.value.toStringAsFixed(2)}');
              }),
              if (frequencyText.isNotEmpty)
                Text(
                  frequencyText,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() => _proceeding = true);
                
                // Convert draft to payment request and delete the draft
                final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final currentUser = authProvider.currentUser;
                final groupMemberIds = customAmounts.keys.toList();
                
                if (currentUser != null && _currentDraft != null) {
                  try {
                    await paymentProvider.convertDraftToRequest(
                      draftId: _currentDraft!.id,
                      groupId: widget.group.id,
                      requestedBy: currentUser.id,
                      groupMembers: groupMemberIds,
                      exemptedMembers: _allMembers.where((u) => !_selected[_allMembers.indexOf(u)]).map((u) => u.id).toList(),
                      isRecurring: widget.isRecurring,
                      recurringInterval: interval,
                      recurringFrequency: frequency,
                    );
                    
                    if (mounted) {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Go back to group detail
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating payment request: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Request Payment'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRecurring ? 'Recurring Request from Individual(s)' : 'Request from Individual(s)'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g., Dinner, Rent, Utilities',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Select all checkbox
            CheckboxListTile(
              title: const Text('Select All Members'),
              value: _selectAll,
              onChanged: _toggleSelectAll,
            ),
            const SizedBox(height: 16),

            // Single amount request option
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
                                labelText: 'Amount for all selected members',
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

            // Members list with amount inputs
            Text(
              'Set amounts for each member:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...List.generate(_allMembers.length, (index) {
              final member = _allMembers[index];
              final isCurrentUser = widget.currentUser != null && member.id == widget.currentUser!.id;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selected[index],
                        onChanged: (value) => _toggleMember(index, value),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'You',
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
                            Text(
                              member.email,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _amountControllers[index],
                          enabled: _selected[index] && !_useSingleAmount,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixText: '\$',
                            border: const OutlineInputBorder(),
                            hintText: _useSingleAmount ? 'Auto-filled' : null,
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Total amount display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${_calculateTotal().toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Proceed button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceeding ? null : _proceed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _proceeding
                    ? const CircularProgressIndicator()
                    : Text(widget.isRecurring ? 'Create Recurring Request' : 'Create Request from Individual(s)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 