import 'package:flutter/material.dart';
import '../models/models.dart';
import 'group_detail_page.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Lista temporal de grupos en memoria
  final List<Group> _groups = [];

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
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              final id = Random().nextInt(1000000).toString();
              final g = Group(id: id, name: name);
              setState(() => _groups.add(g));
              Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Si quieres puedes precargar un grupo de ejemplo
    if (_groups.isEmpty) {
      _groups.add(Group(id: '1', name: 'Calle 1'));
    }
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
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: _groups.isEmpty
            ? Center(
                child: Text(
                  'No hay grupos. Presiona + para crear uno.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : GridView.builder(
                itemCount: _groups.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.15,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, i) {
                  final g = _groups[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailPage(group: g),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.map, size: 36, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 12),
                            Text(g.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text(
                              'Creado: ${g.createdAt.toLocal().toString().split(' ').first}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewGroupDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
