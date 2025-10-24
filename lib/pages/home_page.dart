import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // <-- IMPORTANTE: para formatear la fecha

import '../models/models.dart';
import '../services/api_service.dart';
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
                await _apiService.createGroup(name);
                if (!mounted) return;
                Navigator.pop(context);
                _loadGroups();
              } catch (e) {
                if (!mounted) return;
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
                    'No hay grupos.\nPresiona + para crear uno.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              final groups = snapshot.data!;
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
                    // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
                    // Hemos añadido el contenido dentro de la Card.
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 40,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              g.name, // <-- Mostramos el nombre del grupo
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(), // Empuja la fecha hacia abajo
                            Text(
                              'Creado: ${DateFormat.yMd().format(g.createdAt.toLocal())}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
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