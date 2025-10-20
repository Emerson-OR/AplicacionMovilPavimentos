import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PathologyForm extends StatefulWidget {
  final Map<String, dynamic> pathology;

  const PathologyForm({super.key, required this.pathology});

  @override
  State<PathologyForm> createState() => _PathologyFormState();
}

class _PathologyFormState extends State<PathologyForm> {
  String? _severity;
  File? _photoFile;
  final TextEditingController _notesCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _sending = false;

  // --- Tomar foto con cámara ---
  Future<void> _takePhoto() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'pav_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(file.path).copy('${appDir.path}/$fileName');

    setState(() {
      _photoFile = saved;
    });
  }

  // --- Enviar solicitud a Raspberry Pi ---
  Future<void> _sendToPi() async {
    if (_severity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona severidad')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      // Usa el nombre de la patología para construir la URL
      final pathologyName =
          widget.pathology['name']?.toLowerCase() ?? 'baches';
      final uri = Uri.parse(
          'http://10.194.151.75:8000/api/kinect/evaluar/?patologia=$pathologyName');

      // Realiza la solicitud GET al endpoint de la Raspberry
      final response =
          await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Respuesta de Raspberry Pi'),
            content: Text(const JsonEncoder.withIndent('  ').convert(decoded)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enviando solicitud: $e')),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  // --- Guardar registro localmente (simulado) ---
  void _saveLocal() {
    if (_severity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona severidad')),
      );
      return;
    }

    final record = {
      'groupId': widget.pathology['groupId'],
      'pathology': widget.pathology['name'],
      'severity': _severity,
      'notes': _notesCtrl.text,
      'photo': _photoFile?.path,
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('Registro local temporal: $record');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro guardado localmente')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // --- Widget para seleccionar severidad ---
  Widget _severityChip(String label, Color color) {
    final selected = _severity == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(color: selected ? Colors.white : color),
      ),
      selected: selected,
      selectedColor: color,
      backgroundColor: Colors.grey.shade100,
      onSelected: (v) => setState(() => _severity = v ? label : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pathology;
    return Scaffold(
      appBar: AppBar(title: Text(p['name'] ?? 'Patología')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p['image'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  p['image'],
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              p['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(p['desc'] ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            const Text('Nivel de severidad',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _severityChip('Baja', Colors.green),
                _severityChip('Media', Colors.orange),
                _severityChip('Alta', Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Observaciones (opcional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Fotografía (tocar para tomar)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: _photoFile == null
                    ? const Center(
                        child: Icon(Icons.camera_alt,
                            size: 48, color: Colors.black45),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_photoFile!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveLocal,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar local'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _sendToPi,
                    icon: const Icon(Icons.send),
                    label: _sending
                        ? const Text('Enviando...')
                        : const Text('Enviar a Raspberry Pi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
