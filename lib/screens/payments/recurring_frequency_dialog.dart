import 'package:flutter/material.dart';
import '../../models/payment_request.dart';

class RecurringFrequencyDialog extends StatefulWidget {
  const RecurringFrequencyDialog({Key? key}) : super(key: key);

  @override
  State<RecurringFrequencyDialog> createState() => _RecurringFrequencyDialogState();
}

class _RecurringFrequencyDialogState extends State<RecurringFrequencyDialog> {
  final TextEditingController _numberController = TextEditingController();
  RecurringFrequency _selectedFrequency = RecurringFrequency.weekly;
  int _number = 1;

  @override
  void initState() {
    super.initState();
    _numberController.text = '1';
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _updateNumber(String value) {
    final number = int.tryParse(value);
    if (number != null && number > 0) {
      setState(() {
        _number = number;
      });
    }
  }

  String _getFrequencyText() {
    switch (_selectedFrequency) {
      case RecurringFrequency.daily:
        return _number == 1 ? 'day' : 'days';
      case RecurringFrequency.weekly:
        return _number == 1 ? 'week' : 'weeks';
      case RecurringFrequency.monthly:
        return _number == 1 ? 'month' : 'months';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Recurring Frequency'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How often should this request recur?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          
          // Number input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Number',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _updateNumber,
                ),
              ),
              const SizedBox(width: 16),
              
              // Frequency dropdown
              Expanded(
                child: DropdownButtonFormField<RecurringFrequency>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: RecurringFrequency.values.map((frequency) {
                    String label;
                    switch (frequency) {
                      case RecurringFrequency.daily:
                        label = 'Daily';
                        break;
                      case RecurringFrequency.weekly:
                        label = 'Weekly';
                        break;
                      case RecurringFrequency.monthly:
                        label = 'Monthly';
                        break;
                    }
                    return DropdownMenuItem(
                      value: frequency,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFrequency = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withAlpha(77)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.repeat,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This request will recur every $_number ${_getFrequencyText()}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
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
          onPressed: () {
            Navigator.of(context).pop({
              'number': _number,
              'frequency': _selectedFrequency,
            });
          },
          child: const Text('Set Frequency'),
        ),
      ],
    );
  }
} 