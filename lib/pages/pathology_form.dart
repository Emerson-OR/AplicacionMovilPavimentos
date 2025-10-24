import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../services/api_service.dart';

// ESTA ES LA DEFINICIÓN DEL WIDGET 'PathologyForm' QUE FALTABA
class PathologyForm extends StatefulWidget {
  final Group group;
  final PathologyType pathologyType;

  const PathologyForm({
    super.key,
    required this.group,
    required this.pathologyType,
  });

  @override
  State<PathologyForm> createState() => _PathologyFormState();
}

class _PathologyFormState extends State<PathologyForm> {
  final ApiService _apiService = ApiService();
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isProcessing = false;

  /// Orquesta el flujo completo: llama a Kinect y luego guarda en Django.
  Future<void> _evaluateAndSaveRecord() async {
    setState(() => _isProcessing = true);

    try {
      // 1. Obtiene la predicción de la Raspberry Pi.
      final dynamic kinectData = await _getKinectPrediction();

      // VERIFICACIÓN DE SEGURIDAD: Si el widget ya no existe, detenemos el proceso.
      if (!mounted) return;

      // 2. Extrae la severidad del texto de forma segura.
      final String predictedSeverityString = _parseSeverityFromResponse(kinectData);
      
      // 3. Convierte la respuesta a nuestro formato interno.
      final Severity predictedSeverity =
          _mapSeverityFromString(predictedSeverityString);

      // 4. Obtiene la respuesta completa para guardarla en las notas.
      final String fullKinectResponse = _getRawResponseForNotes(kinectData);
      final combinedNotes = """
${_notesCtrl.text}

--- Datos de Kinect ---
$fullKinectResponse
""";

      // 5. Guarda el registro en el backend de Django.
      await _apiService.createPathologyRecord(
        groupId: widget.group.id,
        pathologyName: widget.pathologyType.name,
        severity: predictedSeverity.label,
        notes: combinedNotes,
      );

      // VERIFICACIÓN DE SEGURIDAD: Antes de usar el context para mostrar el SnackBar.
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Evaluación guardada con éxito!')),
      );
      Navigator.pop(context);

    } catch (e) {
      // VERIFICACIÓN DE SEGURIDAD: También al manejar errores.
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en el proceso: $e')),
      );
    } finally {
      // VERIFICACIÓN DE SEGURIDAD: Antes de actualizar el estado final.
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Parsea la respuesta de la Kinect para encontrar la severidad de forma segura.
  String _parseSeverityFromResponse(dynamic kinectData) {
    if (kinectData is Map<String, dynamic>) {
      final dynamic responseValue = kinectData['respuesta_modelo'];
      if (responseValue is String) {
        final RegExp regex = RegExp(r'(ALTA|MEDIA|BAJA)', caseSensitive: false);
        final Match? match = regex.firstMatch(responseValue);
        if (match != null) {
          return match.group(0)!.toUpperCase();
        }
      }
    }
    return 'Baja'; // Valor por defecto si algo falla
  }

  /// Obtiene el texto de la respuesta para guardarlo en las notas, manejando cualquier tipo de dato.
  String _getRawResponseForNotes(dynamic kinectData) {
    if (kinectData is Map<String, dynamic> && kinectData.containsKey('respuesta_modelo')) {
        return kinectData['respuesta_modelo'].toString();
    }
    return kinectData.toString();
  }

  /// Realiza la petición GET y devuelve 'dynamic' para ser flexible a la respuesta.
  Future<dynamic> _getKinectPrediction() async {
    final pathologyName =
        widget.pathologyType.name.toLowerCase().replaceAll(' ', '_');
    final uri = Uri.parse(
        'http://10.194.151.75:8000/api/kinect/evaluar/?patologia=$pathologyName');

    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al conectar con Kinect: ${response.statusCode}');
    }
  }

  /// Convierte un String a nuestro Enum `Severity`.
  Severity _mapSeverityFromString(String severityString) {
    switch (severityString.toUpperCase()) {
      case 'ALTA':
        return Severity.alta;
      case 'MEDIA':
        return Severity.media;
      case 'BAJA':
      default:
        return Severity.baja;
    }
  }
  
  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pType = widget.pathologyType;
    return Scaffold(
      appBar: AppBar(title: Text(pType.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pType.imageAsset.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  pType.imageAsset,
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              pType.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(pType.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 24),
            const Text('Observaciones (opcional)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Añadir notas sobre el hallazgo...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _evaluateAndSaveRecord,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: _isProcessing
                    ? const Text('Procesando...')
                    : const Text('Evaluar con Kinect y Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    inherit: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}