import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PartialPaymentDialog extends StatefulWidget {
  final String userName;
  final double totalAmount;
  final double currentPartialAmount;
  final double remainingAmount;

  const PartialPaymentDialog({
    super.key,
    required this.userName,
    required this.totalAmount,
    required this.currentPartialAmount,
    required this.remainingAmount,
  });

  @override
  State<PartialPaymentDialog> createState() => _PartialPaymentDialogState();
}

class _PartialPaymentDialogState extends State<PartialPaymentDialog> {
  late TextEditingController _amountController;
  late double _enteredAmount;

  @override
  void initState() {
    super.initState();
    _enteredAmount = widget.currentPartialAmount;
    _amountController = TextEditingController(
      text: _enteredAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateAmount(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    setState(() {
      _enteredAmount = amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.payment, color: Colors.blue[700]),
          const SizedBox(width: 8),
          const Text('Partial Payment'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter partial payment amount for ${widget.userName}:',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          // Current payment status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Summary',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:'),
                    Text(
                      '\$${widget.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Already Paid:'),
                    Text(
                      '\$${widget.currentPartialAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remaining:'),
                    Text(
                      '\$${widget.remainingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Amount input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Payment Amount',
              prefixText: '\$',
              border: const OutlineInputBorder(),
              helperText: 'Enter the amount you want to pay',
            ),
            onChanged: _updateAmount,
          ),
          const SizedBox(height: 8),
          // Validation message
          if (_enteredAmount > widget.totalAmount)
            Text(
              'Amount cannot exceed total amount',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          if (_enteredAmount < 0)
            Text(
              'Amount cannot be negative',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
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
          onPressed: _enteredAmount >= 0 && _enteredAmount <= widget.totalAmount
              ? () => Navigator.of(context).pop(_enteredAmount)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm Payment'),
        ),
      ],
    );
  }
} 