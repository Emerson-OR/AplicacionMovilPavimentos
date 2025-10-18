class Group {
  final String id;
  final String name;
  final DateTime createdAt;

  Group({required this.id, required this.name, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
}

class Record {
  final String id;
  final String groupId;
  final String pathology; // e.g., 'Piel de cocodrilo'
  final String severity; // 'Baja'|'Media'|'Alta'
  final String? notes;
  final String? photoPath;
  final DateTime timestamp;
  final Map<String, dynamic>? piResponse;

  Record({
    required this.id,
    required this.groupId,
    required this.pathology,
    required this.severity,
    this.notes,
    this.photoPath,
    DateTime? timestamp,
    this.piResponse,
  }) : timestamp = timestamp ?? DateTime.now();
}
