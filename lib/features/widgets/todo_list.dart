import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:Maya/core/network/api_client.dart';
import 'package:Maya/features/widgets/add_todo_dialog.dart';
import 'package:Maya/features/widgets/edit_todo_dialog.dart';
import 'package:Maya/utils/constants.dart';

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
        return const Color(0xFFBBF7D0); // green-200
      case 'in-progress':
        return const Color(0xFFFFDDB3); // amber-200
      default:
        return kTextHint; // grey-500
    }
  }

  Icon getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return const Icon(
          FeatherIcons.checkCircle,
          size: 16,
          color: Color(0xFF15803D),
        ); // green-700
      case 'in-progress':
        return const Icon(
          FeatherIcons.clock,
          size: 16,
          color: Color(0xFFB45309),
        ); // amber-700
      default:
        return const Icon(
          FeatherIcons.alertCircle,
          size: 16,
          color: Color(0xFF6B7280),
        ); // grey-500
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = getIt<ApiClient>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFBBF7D0,
                            ).withOpacity(0.6), // green-200/60
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF86EFAC).withOpacity(0.4),
                            ), // green-300/40
                          ),
                          child: const Icon(
                            FeatherIcons.checkSquare,
                            size: 20,
                            color: Color(0xFF15803D), // green-700
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'To-Do',
                          style: kTitleStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937), // gray-800
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddToDoDialog(
                            onAdd: (title, description, reminderTime) async {
                              final payload = apiClient
                                  .prepareCreateToDoPayload(
                                    title,
                                    description,
                                    reminderTime,
                                  );
                              final response = await apiClient.createToDo(
                                payload,
                              );
                              if (response['statusCode'] == 200) {
                                onAdd();
                              }
                            },
                          ),
                        );
                      },
                      child: Text(
                        'Add Todo',
                        style: TextStyle(
                          color: const Color(0xFF15803D), // green-700
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                          style: kBodyStyle.copyWith(
                            color: const Color(0xFF6B7280),
                          ), // grey-500
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: todos.length,
                        itemBuilder: (context, index) {
                          final todo = todos[index];
                          final isCompleted = todo['status'] == 'completed';
                          final isHighPriority =
                              todo['priority'] == 'high' && !isCompleted;

                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => EditToDoDialog(
                                    todo: todo,
                                    onUpdate:
                                        (
                                          id,
                                          title,
                                          description,
                                          status,
                                          reminder,
                                          reminderTime,
                                        ) async {
                                          final payload = apiClient
                                              .prepareUpdateToDoPayload(
                                                id,
                                                title: title,
                                                description: description,
                                                status: status,
                                                reminder:
                                                    reminderTime != null &&
                                                    reminderTime.isNotEmpty,
                                                reminder_time: reminderTime,
                                              );
                                          final response = await apiClient
                                              .updateToDo(payload);
                                          if (response['statusCode'] == 200) {
                                            onUpdate();
                                          }
                                        },
                                    onDelete: (id) async {
                                      final response = await apiClient
                                          .deleteToDo(id);
                                      if (response['statusCode'] == 200) {
                                        onDelete();
                                      }
                                    },
                                  ),
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              final newStatus = isCompleted
                                                  ? 'in-progress'
                                                  : 'completed';
                                              final payload = apiClient
                                                  .prepareUpdateToDoPayload(
                                                    todo['ID'],
                                                    status: newStatus, title: '', description: '', reminder: false,
                                                  );
                                              final response = await apiClient
                                                  .updateToDo(payload);
                                              if (response['statusCode'] ==
                                                  200) {
                                                onUpdate(); // Refresh the list
                                              }
                                            },
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: isCompleted
                                                      ? const Color(
                                                          0xFF86EFAC,
                                                        ) // green-300
                                                      : const Color(
                                                          0xFF9CA3AF,
                                                        ), // gray-400
                                                  width: 2,
                                                ),
                                                color: isCompleted
                                                    ? const Color(
                                                        0xFFBBF7D0,
                                                      ).withOpacity(
                                                        0.6,
                                                      ) // green-200/60
                                                    : Colors.transparent,
                                              ),
                                              child: isCompleted
                                                  ? const Icon(
                                                      FeatherIcons.checkCircle,
                                                      size: 14,
                                                      color: Color(
                                                        0xFF15803D,
                                                      ), // green-700
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              todo['title'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isCompleted
                                                    ? const Color(
                                                        0xFF6B7280,
                                                      ) // gray-500
                                                    : const Color(
                                                        0xFF1F2937,
                                                      ), // gray-800
                                                decoration: isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isHighPriority)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFE4E6)
                                                    .withOpacity(
                                                      0.6,
                                                    ), // rose-100/60
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(0xFFFECDD3)
                                                      .withOpacity(
                                                        0.6,
                                                      ), // rose-200/60
                                                ),
                                              ),
                                              child: const Text(
                                                'High',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(
                                                    0xFFBE123C,
                                                  ), // rose-700
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
