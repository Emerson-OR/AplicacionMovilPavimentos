import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/pathology_card.dart';
import 'pathology_form.dart';

class GroupDetailPage extends StatelessWidget {
  final Group group;
  const GroupDetailPage({super.key, required this.group});

  static const List<Map<String, String>> _patologias = [
    {
      "name": "Piel de cocodrilo",
      "image": "assets/images/piel_cocodrilo.jpeg",
      "desc": "Fisuras entrelazadas"
    },
    {
      "name": "Bache",
      "image": "assets/images/bache.jpeg",
      "desc": "Depresión o hueco"
    },
    {
      "name": "Grieta transversal",
      "image": "assets/images/grieta_transversal.jpeg",
      "desc": "Fisura perpendicular"
    },
    {
      "name": "Grieta longitudinal",
      "image": "assets/images/grieta_longitudinal.jpeg",
      "desc": "Fisura paralela"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: GridView.builder(
          itemCount: _patologias.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, i) {
            final p = _patologias[i];
            return PathologyCard(
              title: p["name"]!,
              subtitle: p["desc"]!,
              imageAsset: p["image"]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PathologyForm(
                      pathology: {
                        "name": p["name"]!,
                        "image": p["image"]!,
                        "desc": p["desc"]!,
                        "groupId": group.id,
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
