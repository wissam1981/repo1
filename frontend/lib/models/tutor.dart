/// A single message in a tutor conversation.
class TutorMessage {
  final String role; // "user" or "assistant"
  final String content;

  TutorMessage({required this.role, required this.content});

  factory TutorMessage.fromJson(Map<String, dynamic> json) {
    return TutorMessage(
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
    );
  }
}

/// A tutor session, mirroring the backend TutorMessageOut schema.
class TutorSession {
  final int id;
  final int userId;
  final int contractId;
  final List<TutorMessage> messages;
  final int difficulty;
  final String? createdAt;

  TutorSession({
    required this.id,
    required this.userId,
    required this.contractId,
    required this.messages,
    required this.difficulty,
    this.createdAt,
  });

  factory TutorSession.fromJson(Map<String, dynamic> json) {
    return TutorSession(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      contractId: json['contract_id'] as int? ?? 0,
      messages: (json['messages'] as List?)
              ?.map((m) => TutorMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
      difficulty: json['difficulty'] as int? ?? 1,
      createdAt: json['created_at'] as String?,
    );
  }
}
