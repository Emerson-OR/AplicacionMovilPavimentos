// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart'; // Importar el servicio
import 'group_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  late Future<List<Group>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    setState(() {
      _groupsFuture = _apiService.getGroups();
    });
  }

  void _createNewGroupDialog() {
    final TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear nuevo grupo'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Nombre (ej: Calle 1)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              
              try {
                // Llamamos al API para crear el grupo
                await _apiService.createGroup(name);
                Navigator.pop(context);
                _loadGroups(); // Recargamos la lista para ver el nuevo grupo
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al crear el grupo: $e')),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PavementAI - Grupos'),
        actions: [
          IconButton(
            onPressed: _createNewGroupDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Crear grupo',
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadGroups(),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: FutureBuilder<List<Group>>(
            future: _groupsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay grupos. Presiona + para crear uno.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              final groups = snapshot.data!;
              // El GridView no cambia, solo la forma de obtener los 'groups'
              return GridView.builder(
                itemCount: groups.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.15,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, i) {
                  final g = groups[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailPage(group: g),
                        ),
                      );
                    },
                    child: Card(/* ... el diseño de la tarjeta no cambia ... */),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewGroupDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}