import 'package:flutter/material.dart';

import '../models/todo.dart';

class TodoChecklist extends StatelessWidget {
  final List<GameTodo> todos;
  final void Function(GameTodo todo) onToggle;

  const TodoChecklist({super.key, required this.todos, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Keine offenen To-Dos.'),
      );
    }
    final erledigt = todos.where((t) => t.done).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: erledigt / todos.length),
        const SizedBox(height: 8),
        Text('$erledigt von ${todos.length} erledigt',
            style: Theme.of(context).textTheme.labelMedium),
        ...todos.map(
          (t) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: t.done,
            title: Text(
              t.label,
              style: t.done
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            onChanged: (_) => onToggle(t),
          ),
        ),
      ],
    );
  }
}
