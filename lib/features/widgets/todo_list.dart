import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_app/core/network/api_client.dart';
import 'package:my_flutter_app/features/widgets/add_todo_dialog.dart';
import 'package:my_flutter_app/features/widgets/edit_todo_dialog.dart';
import 'package:my_flutter_app/utils/constants.dart';

class ToDoList extends StatelessWidget {
  final List<Map<String, dynamic>> todos;
  final bool isLoading;
  final VoidCallback onAdd;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const ToDoList({
    super.key,
    required this.todos,
    required this.isLoading,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  Color getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return kSuccessColor;
      case 'in-progress':
        return kWarningColor;
      default:
        return kTextHint;
    }
  }

  Icon getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icon(FeatherIcons.checkCircle, size: 16, color: kSuccessColor);
      case 'in-progress':
        return Icon(FeatherIcons.clock, size: 16, color: kWarningColor);
      default:
        return Icon(FeatherIcons.alertCircle, size: 16, color: kTextHint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = getIt<ApiClient>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'To-Do List',
              style: kTitleStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddToDoDialog(
                    onAdd: (title, description, reminderTime) async {
                      final payload = apiClient.prepareCreateToDoPayload(
                        title,
                        description,
                        reminderTime,
                      );
                      final response = await apiClient.createToDo(payload);
                      if (response['statusCode'] == 200) {
                        onAdd();
                      }
                    },
                  ),
                );
              },
              child: Text('Add To-Do', style: kButtonStyle),
            ),
          ],
        ),
        const SizedBox(height: 12),
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : todos.isEmpty
                ? Center(
                    child: Text(
                      'No to-dos yet. Add one to get started!',
                      style: kBodyStyle.copyWith(color: kTextHint),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => EditToDoDialog(
                                  todo: todo,
                                  onUpdate: (
                                    id,
                                    title,
                                    description,
                                    status,
                                    reminder,
                                    reminderTime,
                                  ) async {
                                    final payload =
                                        apiClient.prepareUpdateToDoPayload(
                                      id,
                                      title: title,
                                      description: description,
                                      status: status,
                                      reminder: reminderTime != null &&
                                          reminderTime.isNotEmpty,
                                      reminder_time: reminderTime,
                                    );
                                    final response =
                                        await apiClient.updateToDo(payload);
                                    if (response['statusCode'] == 200) {
                                      onUpdate();
                                    }
                                  },
                                  onDelete: (id) async {
                                    final response =
                                        await apiClient.deleteToDo(id);
                                    if (response['statusCode'] == 200) {
                                      onDelete();
                                    }
                                  },
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          todo['title'],
                                          style: kTitleStyle.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      getStatusIcon(todo['status'] ?? 'pending'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    todo['description'] ?? '',
                                    style: kBodyStyle.copyWith(
                                      color: kTextSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        todo['reminder'] == true
                                            ? FeatherIcons.bell
                                            : FeatherIcons.bellOff,
                                        size: 16,
                                        color: todo['reminder'] == true
                                            ? kPrimaryColor
                                            : kTextHint,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        todo['reminder_time'] != null &&
                                                todo['reminder_time']
                                                    .isNotEmpty
                                            ? () {
                                                try {
                                                  final date = DateFormat(
                                                    'yyyy-MM-dd HH:mm',
                                                  ).parse(
                                                    todo['reminder_time'],
                                                  );
                                                  return DateFormat(
                                                    'yyyy-MM-dd HH:mm',
                                                  ).format(date.toLocal());
                                                } catch (e) {
                                                  try {
                                                    final date =
                                                        DateTime.parse(
                                                      todo['reminder_time'],
                                                    ).toLocal();
                                                    return DateFormat(
                                                      'yyyy-MM-dd HH:mm',
                                                    ).format(date);
                                                  } catch (e) {
                                                    return 'Invalid reminder time';
                                                  }
                                                }
                                              }()
                                            : 'No reminder',
                                        style: kBodyStyle.copyWith(
                                          color: kTextHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created: ${() {
                                      try {
                                        final date = DateTime.parse(
                                          todo['CreatedAt'],
                                        ).toLocal();
                                        return DateFormat(
                                          'yyyy-MM-dd HH:mm',
                                        ).format(date);
                                      } catch (e) {
                                        return 'Unknown';
                                      }
                                    }()}',
                                    style:
                                        kBodyStyle.copyWith(color: kTextHint),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ],
    );
  }
}
