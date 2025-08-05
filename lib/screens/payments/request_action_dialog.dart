import 'package:flutter/material.dart';
import '../../models/payment_request.dart';

class RequestActionDialog extends StatefulWidget {
  final String requestId;
  final String requestDescription;
  final String userId;
  final RequestValidityStatus currentStatus;
  final String? currentReason;

  const RequestActionDialog({
    super.key,
    required this.requestId,
    required this.requestDescription,
    required this.userId,
    required this.currentStatus,
    this.currentReason,
  });

  @override
  State<RequestActionDialog> createState() => _RequestActionDialogState();
}

class _RequestActionDialogState extends State<RequestActionDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String _selectedAction = '';

  @override
  void initState() {
    super.initState();
    if (widget.currentReason != null) {
      _reasonController.text = widget.currentReason!;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Action'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request: ${widget.requestDescription}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.currentStatus == RequestValidityStatus.valid) ...[
              const Text(
                'What would you like to do with this request?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildActionOption(
                'Mark as Invalid',
                'I think there has been a mistake with this request',
                Icons.error_outline,
                Colors.orange,
                'invalid',
              ),
              const SizedBox(height: 8),
              _buildActionOption(
                'Report for Fraud',
                'I believe this is a fraudulent request',
                Icons.report_problem,
                Colors.red,
                'report',
              ),
            ] else if (widget.currentStatus == RequestValidityStatus.invalid) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Marked as Invalid',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (widget.currentReason != null) ...[
                Text(
                  'Reason: ${widget.currentReason}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'You can also report this request if you believe it\'s fraudulent.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              _buildActionOption(
                'Report for Fraud',
                'I believe this is a fraudulent request',
                Icons.report_problem,
                Colors.red,
                'report',
              ),
            ] else if (widget.currentStatus == RequestValidityStatus.reported) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.report_problem, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reported for Fraud',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (widget.currentReason != null) ...[
                Text(
                  'Reason: ${widget.currentReason}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
            if (_selectedAction.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: _selectedAction == 'invalid' 
                      ? 'Why do you think this request is invalid?'
                      : 'Why do you think this request is fraudulent?',
                  border: const OutlineInputBorder(),
                  hintText: _selectedAction == 'invalid'
                      ? 'e.g., Wrong amount, incorrect participants, duplicate request...'
                      : 'e.g., Unknown sender, suspicious amount, phishing attempt...',
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedAction.isNotEmpty && _reasonController.text.trim().isNotEmpty) {
              Navigator.of(context).pop({
                'action': _selectedAction,
                'reason': _reasonController.text.trim(),
              });
            } else {
              // Just close with OK if no action selected or no reason provided
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedAction.isNotEmpty && _reasonController.text.trim().isNotEmpty
                ? (_selectedAction == 'invalid' ? Colors.orange : Colors.red)
                : Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: const Text('OK'),
        ),
        if (_selectedAction.isNotEmpty && _reasonController.text.trim().isNotEmpty)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop({
                'action': _selectedAction,
                'reason': _reasonController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedAction == 'invalid' ? Colors.orange : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(_selectedAction == 'invalid' ? 'Mark as Invalid' : 'Report'),
          ),
      ],
    );
  }

  Widget _buildActionOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String action,
  ) {
    final isSelected = _selectedAction == action;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAction = action;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(26) : Colors.grey.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color.withAlpha(77) : Colors.grey.withAlpha(77),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.grey[700],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? color.withAlpha(150) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
} 