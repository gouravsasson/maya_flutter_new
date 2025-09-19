import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Maya/utils/constants.dart';

class EditToDoDialog extends StatefulWidget {
  final Map<String, dynamic> todo;
  final Function(int, String, String, String, bool, String?) onUpdate;
  final Function(int) onDelete;

  const EditToDoDialog({
    super.key,
    required this.todo,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  _EditToDoDialogState createState() => _EditToDoDialogState();
}

class _EditToDoDialogState extends State<EditToDoDialog> {
  late String title;
  late String description;
  late String status;
  late DateTime? selectedDateTime;
  String? dateTimeError;

  @override
  void initState() {
    super.initState();
    title = widget.todo['title'];
    description = widget.todo['description'] ?? '';
    status = widget.todo['status'] ?? 'pending';
    selectedDateTime = widget.todo['reminder_time'] != null
        ? DateTime.tryParse(widget.todo['reminder_time'])
        : null;
  }

  @override
  Widget build(BuildContext context) {
    bool isValidDateTime =
        selectedDateTime == null || !selectedDateTime!.isBefore(DateTime.now());
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Edit To-Do', style: kTitleStyle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: kInputBackground,
              ),
              controller: TextEditingController(text: title),
              onChanged: (val) => title = val,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: kInputBackground,
              ),
              controller: TextEditingController(text: description),
              onChanged: (val) => description = val,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: kInputBackground,
              ),
              value: status,
              items: ['Todo', 'in-progress', 'completed', '']
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => status = val!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Reminder Time',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: kInputBackground,
                      hintText: selectedDateTime == null
                          ? 'Select date & time'
                          : DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).format(selectedDateTime!),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final now = DateTime.now();
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime ?? now,
                        firstDate: now,
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedDateTime != null
                              ? TimeOfDay.fromDateTime(selectedDateTime!)
                              : TimeOfDay.fromDateTime(now),
                        );
                        if (pickedTime != null) {
                          final selected = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                          setState(() {
                            if (selected.isBefore(now)) {
                              dateTimeError = 'Cannot select a past date/time';
                              selectedDateTime = null;
                            } else {
                              dateTimeError = null;
                              selectedDateTime = selected;
                            }
                          });
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.calendar_today, color: kPrimaryColor),
                  onPressed: () async {
                    final now = DateTime.now();
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime ?? now,
                      firstDate: now,
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedDateTime != null
                            ? TimeOfDay.fromDateTime(selectedDateTime!)
                            : TimeOfDay.fromDateTime(now),
                      );
                      if (pickedTime != null) {
                        final selected = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        setState(() {
                          if (selected.isBefore(now)) {
                            dateTimeError = 'Cannot select a past date/time';
                            selectedDateTime = null;
                          } else {
                            dateTimeError = null;
                            selectedDateTime = selected;
                          }
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            if (dateTimeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  dateTimeError!,
                  style: kBodyStyle.copyWith(color: kErrorColor, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: kButtonStyle.copyWith(color: kTextHint)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: isValidDateTime
              ? () {
                  final reminderTimeStr = selectedDateTime != null
                      ? DateFormat(
                          "yyyy-MM-dd'T'HH:mm:ssZ",
                        ).format(selectedDateTime!.toUtc())
                      : null;
                  widget.onUpdate(
                    widget.todo['ID'],
                    title,
                    description,
                    status,
                    reminderTimeStr != null,
                    reminderTimeStr,
                  );
                  Navigator.pop(context);
                }
              : null,
          child: Text(
            'Update',
            style: kButtonStyle.copyWith(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: () {
            widget.onDelete(widget.todo['ID']);
            Navigator.pop(context);
          },
          child: Text(
            'Delete',
            style: kButtonStyle.copyWith(color: kErrorColor),
          ),
        ),
      ],
    );
  }
}
