import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // --- ¡MUY IMPORTANTE! ---
  // Reemplaza esta IP con la dirección IP de la computadora donde corre tu servidor Django.
  static const String _baseUrl = 'http://10.194.151.65:8000/api';

  /// Obtiene la lista de todos los grupos desde el API.
  Future<List<Group>> getGroups() async {
    final response = await http.get(Uri.parse('$_baseUrl/groups/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Group.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los grupos: ${response.statusCode}');
    }
  }
  
  // --- NUEVA FUNCIÓN ---
  /// Obtiene los detalles de un solo grupo, incluyendo sus registros.
  Future<Group> getGroupDetails(String groupId) async {
    final response = await http.get(Uri.parse('$_baseUrl/groups/$groupId/'));

    if (response.statusCode == 200) {
      return Group.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al cargar los detalles del grupo');
    }
  }

  /// Crea un nuevo grupo enviando su nombre al API.
  Future<Group> createGroup(String name) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/groups/'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 201) {
      return Group.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al crear el grupo: ${response.body}');
    }
  }

  /// Crea un nuevo registro de patología (sin foto).
  Future<void> createPathologyRecord({
    required String groupId,
    required String pathologyName,
    required String severity,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/records/'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'group': groupId,
        'pathology_name': pathologyName,
        'severity': severity,
        'notes': notes ?? '',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
          'Error al guardar el registro: ${response.statusCode} - ${response.body}');
    }
  }
}