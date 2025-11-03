import 'dart:io';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/location_service.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(bool?) onCheckboxChanged;
  const TaskCard({super.key, required this.task, required this.onTap, required this.onDelete, required this.onCheckboxChanged});

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _getPriorityIcon() {
    switch (task.priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.trending_up;
      default:
        return Icons.low_priority;
    }
  }

  String _getPriorityLabel() {
    switch (task.priority) {
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Média';
      default:
        return 'Baixa';
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: task.completed,
          onChanged: onCheckboxChanged,
        ),
        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description),
            Row(
              children: [
                Icon(_getPriorityIcon(), color: priorityColor, size: 16),
                const SizedBox(width: 4),
                Text(_getPriorityLabel(), style: TextStyle(color: priorityColor)),
                if (task.hasPhotos)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.photo, color: Colors.green, size: 16),
                  ),
                if (task.hasLocation)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.location_on, color: Colors.blue, size: 16),
                  ),
                if (task.wasCompletedByShake)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.vibration, color: Colors.purple, size: 16),
                  ),
              ],
            ),
            if (task.hasLocation)
              Text('Local: ${task.locationName ?? LocationService.instance.formatCoordinates(task.latitude!, task.longitude!)}', style: const TextStyle(fontSize: 12)),
            if (task.hasPhotos)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: task.photoPaths.length,
                  itemBuilder: (context, index) {
                    final path = task.photoPaths[index];
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: Image.file(File(path)),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.file(File(path), fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
