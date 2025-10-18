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

  Future<void> _takePhoto() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;
    // copiar a carpeta de la app para persistencia mínima
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'pav_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(file.path).copy('${appDir.path}/$fileName');
    setState(() {
      _photoFile = saved;
    });
  }

  Future<void> _sendToPi() async {
    if (_severity == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona severidad')));
      return;
    }
    setState(() => _sending = true);

    try {
      // Ejemplo: enviar multipart/form-data a la RPi
      // Cambia la URL por la IP/host de tu Raspberry Pi
      final uri = Uri.parse('http://<RASPBERRY_PI_IP>:5000/capture');

      final request = http.MultipartRequest('POST', uri);
      request.fields['group_id'] = widget.pathology['groupId']?.toString() ?? 'unknown';
      request.fields['pathology'] = widget.pathology['name'];
      request.fields['severity'] = _severity!;
      request.fields['notes'] = _notesCtrl.text;

      if (_photoFile != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', _photoFile!.path));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        // guarda o muestra resultado
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Respuesta de Raspberry Pi'),
            content: Text(const JsonEncoder.withIndent('  ').convert(decoded)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
          ),
        );
      } else {
        throw Exception('Status ${resp.statusCode}: ${resp.reasonPhrase}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error enviando a Pi: $e')));
    } finally {
      setState(() => _sending = false);
    }
  }

  void _saveLocal() {
    if (_severity == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona severidad')));
      return;
    }
    // TODO: persistir en DB/Hive. Por ahora mostramos un snackbar y volvemos
    final record = {
      'groupId': widget.pathology['groupId'],
      'pathology': widget.pathology['name'],
      'severity': _severity,
      'notes': _notesCtrl.text,
      'photo': _photoFile?.path,
      'timestamp': DateTime.now().toIso8601String(),
    };
    // imprime en consola (más tarde guardar en Hive/sqflite)
    // ignore: avoid_print
    print('Record saved (temp): $record');

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro guardado localmente')));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Widget _severityChip(String label, Color color) {
    final selected = _severity == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : color)),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (p['image'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(p['image'], fit: BoxFit.cover, height: 200, width: double.infinity),
            ),
          const SizedBox(height: 12),
          Text(p['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(p['desc'] ?? '', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          const Text('Nivel de severidad', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _severityChip('Baja', Colors.green),
            _severityChip('Media', Colors.orange),
            _severityChip('Alta', Colors.red),
          ]),
          const SizedBox(height: 16),
          const Text('Observaciones (opcional)'),
          const SizedBox(height: 8),
          TextField(controller: _notesCtrl, maxLines: 3, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
          const SizedBox(height: 16),
          const Text('Fotografía (tocar para tomar)'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade100),
              child: _photoFile == null
                  ? const Center(child: Icon(Icons.camera_alt, size: 48, color: Colors.black45))
                  : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_photoFile!, fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
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
                label: _sending ? const Text('Enviando...') : const Text('Enviar a Raspberry Pi'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ),
          ])
        ]),
      ),
    );
  }
}
