import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Maya/utils/constants.dart';

class AddToDoDialog extends StatefulWidget {
  final Function(String, String, String?) onAdd;

  const AddToDoDialog({super.key, required this.onAdd});

  @override
  _AddToDoDialogState createState() => _AddToDoDialogState();
}

class _AddToDoDialogState extends State<AddToDoDialog> {
  String title = '';
  String description = '';
  DateTime? selectedDateTime;
  String? dateTimeError;

  @override
  Widget build(BuildContext context) {
    bool isValidDateTime =
        selectedDateTime == null || !selectedDateTime!.isBefore(DateTime.now());
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Add New To-Do', style: kTitleStyle),
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
              onChanged: (val) => description = val,
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
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(now),
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
                      initialDate: now,
                      firstDate: now,
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(now),
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
                  widget.onAdd(title, description, reminderTimeStr);
                  Navigator.pop(context);
                }
              : null,
          child: Text('Add', style: kButtonStyle.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}
