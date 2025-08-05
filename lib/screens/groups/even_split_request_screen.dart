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

class EvenSplitRequestScreen extends StatefulWidget {
  final Group group;
  final List<User> members;
  final User? currentUser;
  final bool isRecurring;
  final PaymentDraft? draft;
  const EvenSplitRequestScreen({
    Key? key,
    required this.group,
    required this.members,
    required this.currentUser,
    this.isRecurring = false,
    this.draft,
  }) : super(key: key);

  @override
  State<EvenSplitRequestScreen> createState() => _EvenSplitRequestScreenState();
}

class _EvenSplitRequestScreenState extends State<EvenSplitRequestScreen> {
  late List<User> _allMembers;
  late List<bool> _selected;
  late List<TextEditingController> _percentageControllers;
  bool _selectAll = true;
  bool _includeSelf = true;
  bool _useEvenSplit = true;
  final TextEditingController _amountController = TextEditingController();
  bool _proceeding = false;
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
    _percentageControllers = List.generate(
      _allMembers.length,
      (index) => TextEditingController(),
    );
    // If editing a draft, pre-fill all fields
    if (widget.draft != null) {
      final draft = widget.draft!;
      // Set amount
      if (draft.totalAmount != null) {
        _amountController.text = draft.totalAmount!.toStringAsFixed(2);
      }
      // Set even/custom split
      _useEvenSplit = draft.customAmounts.isEmpty;
      // Set includeSelf
      _includeSelf = draft.includeSelf;
      // Set selected members
      for (int i = 0; i < _allMembers.length; i++) {
        final user = _allMembers[i];
        _selected[i] = draft.selectedUserIds.contains(user.id) || (user.id == 'self' && draft.includeSelf);
      }
      _selectAll = _selected.every((v) => v);
      // Set custom percentages if not even split
      if (!_useEvenSplit && draft.customAmounts.isNotEmpty && draft.totalAmount != null && draft.totalAmount! > 0) {
        for (int i = 0; i < _allMembers.length; i++) {
          final user = _allMembers[i];
          if (draft.customAmounts.containsKey(user.id)) {
            final percent = (draft.customAmounts[user.id]! / draft.totalAmount!) * 100.0;
            _percentageControllers[i].text = percent.toStringAsFixed(2);
          } else {
            _percentageControllers[i].clear();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    for (var controller in _percentageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EvenSplitRequestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the members list changes, update _allMembers and controllers
    final oldIds = oldWidget.members.map((u) => u.id).toList();
    final newIds = widget.members.map((u) => u.id).toList();
    final oldCurrentUserId = oldWidget.currentUser?.id;
    final newCurrentUserId = widget.currentUser?.id;
    bool membersChanged = false;
    if (oldIds.length != newIds.length ||
        !oldIds.every((id) => newIds.contains(id)) ||
        oldCurrentUserId != newCurrentUserId) {
      membersChanged = true;
    }
    if (membersChanged) {
      // Dispose old controllers
      for (var controller in _percentageControllers) {
        controller.dispose();
      }
      // Rebuild _allMembers
      _allMembers = List<User>.from(widget.members);
      if (widget.currentUser != null && !_allMembers.any((u) => u.id == widget.currentUser!.id)) {
        _allMembers.add(widget.currentUser!);
      }
      // Rebuild _selected
      _selected = List.filled(_allMembers.length, true);
      // Rebuild controllers
      _percentageControllers = List.generate(
        _allMembers.length,
        (index) => TextEditingController(),
      );
      // Reset select all and include self
      _selectAll = true;
      _includeSelf = true;
      setState(() {});
    }
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

  void _toggleEvenSplit(bool? value) {
    setState(() {
      _useEvenSplit = value ?? true;
      if (_useEvenSplit) {
        // Clear percentage fields when switching to even split
        for (var controller in _percentageControllers) {
          controller.clear();
        }
      }
    });
  }

  double _calculateTotalPercentage() {
    double total = 0.0;
    for (int i = 0; i < _allMembers.length; i++) {
      if (_selected[i]) {
        final percentage = double.tryParse(_percentageControllers[i].text) ?? 0.0;
        total += percentage;
      }
    }
    return total;
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
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (selectedMembers.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select members and enter a valid amount.')),
      );
      return;
    }

    Map<User, double> splits = {};
    String summary = '';

    if (_useEvenSplit) {
      // Regular even split
      final splitAmount = amount / selectedMembers.length;
      for (var member in selectedMembers) {
        splits[member] = splitAmount;
      }
      summary = selectedMembers.map((u) => '${u.name}: \$${splitAmount.toStringAsFixed(2)}').join('\n');
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

      for (int i = 0; i < _allMembers.length; i++) {
        if (_selected[i]) {
          final percentage = double.tryParse(_percentageControllers[i].text) ?? 0.0;
          final memberAmount = (amount * percentage) / 100.0;
          splits[_allMembers[i]] = memberAmount;
        }
      }
      summary = splits.entries.map((e) => '${e.key.name}: \$${e.value.toStringAsFixed(2)} (${((e.value / amount) * 100).toStringAsFixed(1)}%)').join('\n');
    }

    // Create draft
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      final selectedUserIds = selectedMembers.map((u) => u.id).toList();
      
      // Convert splits to custom amounts format
      final customAmounts = <String, double>{};
      for (var entry in splits.entries) {
        customAmounts[entry.key.id] = entry.value;
      }

      final description = widget.isRecurring 
          ? (_useEvenSplit ? 'Recurring Even Split' : 'Recurring Custom Percentage Split')
          : (_useEvenSplit ? 'Even Split' : 'Custom Percentage Split');

      _currentDraft = await paymentProvider.createDraft(
        userId: authProvider.currentUser!.id,
        type: DraftType.evenSplit,
        groupId: widget.group.id,
        totalAmount: amount,
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
      _showSummaryDialog(splits, amount, interval, frequency);
    } else {
      // Show regular summary dialog for non-recurring requests
      _showSummaryDialog(splits, amount, null, null);
    }
  }

  void _showSummaryDialog(Map<User, double> splits, double amount, int? interval, RecurringFrequency? frequency) {
    final titlePrefix = widget.isRecurring ? 'Recurring ' : '';
    final frequencyText = widget.isRecurring && interval != null && frequency != null
        ? '\n\nFrequency: Every $interval ${_getFrequencyText(frequency)}'
        : '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${titlePrefix}${_useEvenSplit ? 'Even Split Summary' : 'Custom Split Summary'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...splits.entries.map((entry) => Text('${entry.key.name}: \$${entry.value.toStringAsFixed(2)}')),
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
                // Convert draft to payment request and delete the draft
                final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final currentUser = authProvider.currentUser;
                final groupMemberIds = splits.keys.map((u) => u.id).toList();
                
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
              child: Text(widget.isRecurring ? 'Create Recurring Request' : 'Request Payment'),
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
        title: Text(widget.isRecurring ? 'Recurring Even Split Request' : 'Even Split Request'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select members to split with:', style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(
              value: _selectAll,
              onChanged: _toggleSelectAll,
              title: const Text('Select All'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            // Even Split Checkbox
            CheckboxListTile(
              title: const Text('Even split'),
              subtitle: const Text('Split equally among all selected members'),
              value: _useEvenSplit,
              onChanged: _toggleEvenSplit,
            ),
            
            Expanded(
              child: ListView.builder(
                itemCount: _allMembers.length,
                itemBuilder: (context, i) {
                  final user = _allMembers[i];
                  final isSelf = widget.currentUser != null && user.id == widget.currentUser!.id;
                  return CheckboxListTile(
                    value: _selected[i],
                    onChanged: (v) => _toggleMember(i, v),
                    title: Row(
                      children: [
                        Text(user.name + (isSelf ? ' (You)' : '')),
                        const SizedBox(width: 8),
                        if (!_useEvenSplit && _selected[i])
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _percentageControllers[i],
                              decoration: const InputDecoration(
                                labelText: '%',
                                border: OutlineInputBorder(),
                                hintText: '0',
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(user.email),
                    controlAffinity: ListTileControlAffinity.leading,
                    secondary: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selected[i] = false;
                          _percentageControllers[i].clear();
                          _selectAll = _selected.every((v) => v);
                          if (isSelf) {
                            _includeSelf = false;
                          }
                        });
                      },
                      tooltip: 'Remove ' + (isSelf ? 'You' : user.name),
                    ),
                  );
                },
              ),
            ),
            
            // Percentage Input Fields (when even split is unchecked)
            if (!_useEvenSplit) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Percentage for Each Selected Member',
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
                      ...List.generate(_allMembers.length, (i) {
                        final user = _allMembers[i];
                        final isSelected = _selected[i];
                        final isSelf = widget.currentUser != null && user.id == widget.currentUser!.id;
                        
                        if (!isSelected) return const SizedBox.shrink();
                        
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
                                  isSelf ? 'Y' : user.name[0],
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
                                      isSelf ? 'You' : user.name,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      user.email,
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
                                    controller: _percentageControllers[i],
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
                                    _selected[i] = false;
                                    _percentageControllers[i].clear();
                                    // Update select all checkbox
                                    _selectAll = _selected.every((v) => v);
                                    // Update include self if this was the current user
                                    if (isSelf) {
                                      _includeSelf = false;
                                    }
                                  });
                                },
                                tooltip: 'Remove ${isSelf ? 'You' : user.name}',
                              ),
                            ],
                          ),
                        );
                      }),
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
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Total amount to split'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceed,
                child: const Text('Proceed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 