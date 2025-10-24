import 'package:flutter/material.dart';

// --- NUEVO: Modelo para el Registro de Patología ---
// Representa un único registro guardado en tu base de datos Django.
class PathologyRecord {
  final String id;
  final String pathologyName;
  final String severity;
  final String notes;
  final DateTime timestamp;

  PathologyRecord({
    required this.id,
    required this.pathologyName,
    required this.severity,
    required this.notes,
    required this.timestamp,
  });

  factory PathologyRecord.fromJson(Map<String, dynamic> json) {
    return PathologyRecord(
      id: json['id'],
      pathologyName: json['pathology_name'],
      severity: json['severity'],
      notes: json['notes'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// --- ACTUALIZACIÓN: Modelo para el Grupo ---
class Group {
  final String id;
  final String name;
  final DateTime createdAt;
  // Un grupo ahora puede contener una lista de sus registros.
  final List<PathologyRecord> records;

  Group({
    required this.id,
    required this.name,
    required this.createdAt,
    this.records = const [], // Valor por defecto es una lista vacía
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    // Parsea la lista anidada de registros que viene del API de Django
    var recordsList = json['records'] as List? ?? [];
    List<PathologyRecord> parsedRecords =
        recordsList.map((r) => PathologyRecord.fromJson(r)).toList();

    return Group(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      records: parsedRecords,
    );
  }
}

// --- Enum para la Severidad ---
enum Severity { baja, media, alta }

// --- Extensión para el Enum ---
extension SeverityExtension on Severity {
  String get label {
    switch (this) {
      case Severity.baja:
        return 'Baja';
      case Severity.media:
        return 'Media';
      case Severity.alta:
        return 'Alta';
    }
  }

  Color get color {
    switch (this) {
      case Severity.baja:
        return Colors.green;
      case Severity.media:
        return Colors.orange;
      case Severity.alta:
        return Colors.red;
    }
  }
}

// --- Modelo para los Tipos de Patología ---
class PathologyType {
  final String name;
  final String imageAsset;
  final String description;

  const PathologyType({
    required this.name,
    required this.imageAsset,
    required this.description,
  });
}