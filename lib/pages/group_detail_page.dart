import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/pathology_card.dart';
import 'pathology_form.dart'; // <-- ¡ESTA ES LA LÍNEA QUE FALTABA!

class GroupDetailPage extends StatefulWidget {
  final Group group;
  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final ApiService _apiService = ApiService();
  late Future<Group> _groupDetailsFuture;

  static const List<PathologyType> _pathologyTypes = [
    PathologyType(
      name: "Piel de cocodrilo",
      imageAsset: "assets/images/piel_cocodrilo.jpeg",
      description: "Fisuras entrelazadas",
    ),
    PathologyType(
      name: "Bache",
      imageAsset: "assets/images/bache.jpeg",
      description: "Depresión o hueco",
    ),
    PathologyType(
      name: "Grieta transversal",
      imageAsset: "assets/images/grieta_transversal.jpeg",
      description: "Fisura perpendicular",
    ),
    PathologyType(
      name: "Grieta longitudinal",
      imageAsset: "assets/images/grieta_longitudinal.jpeg",
      description: "Fisura paralela",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  void _loadGroupDetails() {
    setState(() {
      _groupDetailsFuture = _apiService.getGroupDetails(widget.group.id);
    });
  }

  /// Navega al formulario y refresca los datos al volver
  Future<void> _navigateAndRefresh(BuildContext context, PathologyType pType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        // Ahora el compilador sabe qué es 'PathologyForm' gracias al import
        builder: (_) => PathologyForm(
          group: widget.group,
          pathologyType: pType,
        ),
      ),
    );
    _loadGroupDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroupDetails,
            tooltip: 'Refrescar',
          )
        ],
      ),
      body: FutureBuilder<Group>(
        future: _groupDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child:
                    Text('Error al cargar los registros: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No se encontraron datos.'));
          }

          final groupWithDetails = snapshot.data!;
          final records = groupWithDetails.records;

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Text(
                'Registros Existentes (${records.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                      child: Text('Aún no hay registros en este grupo.')),
                )
              else
                ...records.map((record) => _buildRecordCard(record)).toList(),

              const SizedBox(height: 24),
              const Divider(thickness: 1),
              const SizedBox(height: 16),

              Text(
                'Añadir Nuevo Registro',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pathologyTypes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, i) {
                  final pType = _pathologyTypes[i];
                  return PathologyCard(
                    title: pType.name,
                    subtitle: pType.description,
                    imageAsset: pType.imageAsset,
                    onTap: () => _navigateAndRefresh(context, pType),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(PathologyRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Icon(_getIconForPathology(record.pathologyName), size: 36, color: _getSeverityColor(record.severity)),
        title: Text(record.pathologyName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            'Registrado: ${DateFormat.yMd().add_jm().format(record.timestamp.toLocal())}'),
        trailing: Chip(
          label: Text(
            record.severity,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: _getSeverityColor(record.severity),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(record.pathologyName),
              content: SingleChildScrollView(child: Text(record.notes)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'ALTA':
        return Colors.red.shade600;
      case 'MEDIA':
        return Colors.orange.shade700;
      case 'BAJA':
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForPathology(String pathologyName) {
    final name = pathologyName.toLowerCase();
    if (name.contains('bache')) return Icons.healing_outlined;
    if (name.contains('cocodrilo')) return Icons.grid_on_outlined;
    if (name.contains('grieta')) return Icons.show_chart_outlined;
    return Icons.warning_amber_rounded;
  }
}