class GameTodo {
  final String id;
  final String userId;
  final String gameId;
  final String key;
  final String label;
  final bool done;
  final DateTime createdAt;

  const GameTodo({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.key,
    required this.label,
    required this.done,
    required this.createdAt,
  });

  factory GameTodo.fromMap(Map<String, dynamic> map) {
    return GameTodo(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      gameId: map['game_id'] as String,
      key: map['key'] as String,
      label: map['label'] as String,
      done: map['done'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
