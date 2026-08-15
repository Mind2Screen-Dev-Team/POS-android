import 'package:flutter/material.dart';

/// Bottomsheet untuk memilih rentang tanggal backup/restore.
/// Mengikuti pola bottomsheet existing yang dipakai di form kategori.
class DateRangeBottomSheet extends StatefulWidget {
  const DateRangeBottomSheet({
    super.key,
    required this.onConfirm,
  });

  final void Function(DateTime start, DateTime end) onConfirm;

  @override
  State<DateRangeBottomSheet> createState() => _DateRangeBottomSheetState();
}

class _DateRangeBottomSheetState extends State<DateRangeBottomSheet> {
  DateTime? _startDate;
  DateTime? _endDate;

  void _selectStartDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2000),
      lastDate: _endDate ?? now,
    );
    if (selectedDate != null) {
      setState(() => _startDate = selectedDate);
    }
  }

  void _selectEndDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: _startDate ?? DateTime(2000),
      lastDate: now,
    );
    if (selectedDate != null) {
      setState(() => _endDate = selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  'Tanggal Mulai',
                  _startDate,
                  _selectStartDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  'Tanggal Selesai',
                  _endDate,
                  _selectEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (_startDate != null && _endDate != null) {
                Navigator.of(context).pop();
                widget.onConfirm(_startDate!, _endDate!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pilih tanggal mulai dan selesai'),
                  ),
                );
              }
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(
    String label,
    DateTime? date,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 8),
          Text(
            date == null
                ? label
                : '${date.day}/${date.month}/${date.year}',
            style: TextStyle(
              color: date == null ? Colors.grey : null,
            ),
          ),
        ],
      ),
    );
  }
}