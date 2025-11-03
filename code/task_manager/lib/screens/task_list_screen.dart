import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/sensor_service.dart';
import '../services/location_service.dart';
import 'task_form_screen.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  String _filter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _setupShakeDetection();
  }

  @override
  void dispose() {
    SensorService.instance.stop();
    super.dispose();
  }

  void _setupShakeDetection() {
    SensorService.instance.startShakeDetection(() {
      _showShakeDialog();
    });
  }

  void _showShakeDialog() {
    final pendingTasks = _tasks.where((t) => !t.completed).toList();
    if (pendingTasks.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Completar tarefa por shake'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: pendingTasks.map((task) => ListTile(
            title: Text(task.title),
            trailing: ElevatedButton(
              child: const Text('Completar'),
              onPressed: () async {
                await _completeTaskByShake(task);
                Navigator.of(context).pop();
              },
            ),
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _completeTaskByShake(Task task) async {
    try {
      final updated = task.copyWith(
        completed: true,
        completedAt: DateTime.now(),
        completedBy: 'shake',
      );
      await DatabaseService.instance.update(updated);
      await _loadTasks();
    } catch (e) {
      print('Erro ao completar por shake: $e');
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await DatabaseService.instance.readAll();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  List<Task> get _filteredTasks {
    switch (_filter) {
      case 'completed':
        return _tasks.where((t) => t.completed).toList();
      case 'pending':
        return _tasks.where((t) => !t.completed).toList();
      default:
        return _tasks;
    }
  }

  Map<String, int> get _statistics {
    final total = _tasks.length;
    final completed = _tasks.where((t) => t.completed).length;
    final shake = _tasks.where((t) => t.wasCompletedByShake).length;
  final withPhoto = _tasks.where((t) => t.hasPhotos).length;
    final withLocation = _tasks.where((t) => t.hasLocation).length;
    return {
      'total': total,
      'completed': completed,
      'shake': shake,
      'photo': withPhoto,
      'location': withLocation,
    };
  }

  Future<void> _filterByNearby() async {
    final position = await LocationService.instance.getCurrentLocation();
    if (position == null) return;
    final nearbyTasks = await DatabaseService.instance.getTasksNearLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusInMeters: 1000,
    );
    setState(() {
      _tasks = nearbyTasks;
      _filter = 'nearby';
    });
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir tarefa'),
        content: Text('Deseja realmente excluir "${task.title}"?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: const Text('Excluir'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.instance.delete(task.id!);
      await _loadTasks();
    }
  }

  Future<void> _toggleComplete(Task task) async {
    try {
      final updated = task.copyWith(completed: !task.completed);
      await DatabaseService.instance.update(updated);
      await _loadTasks();
    } catch (e) {
      print('Erro ao atualizar tarefa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statistics;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TaskFormScreen()),
              );
              if (result == true) await _loadTasks();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTasks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _filteredTasks.length,
                  itemBuilder: (_, i) {
                    final task = _filteredTasks[i];
                    return TaskCard(
                      task: task,
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
                        );
                        if (result == true) await _loadTasks();
                      },
                      onDelete: () => _deleteTask(task),
                      onCheckboxChanged: (v) => _toggleComplete(task),
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: ['all', 'completed', 'pending', 'nearby'].indexOf(_filter),
        onTap: (i) {
          setState(() {
            switch (i) {
              case 1:
                _filter = 'completed';
                break;
              case 2:
                _filter = 'pending';
                break;
              case 3:
                _filterByNearby();
                break;
              default:
                _filter = 'all';
                _loadTasks();
            }
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Todas'),
          BottomNavigationBarItem(icon: Icon(Icons.check), label: 'Concluídas'),
          BottomNavigationBarItem(icon: Icon(Icons.pending), label: 'Pendentes'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Próximas'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    switch (_filter) {
      case 'completed':
        message = 'Nenhuma tarefa concluída.';
        break;
      case 'pending':
        message = 'Nenhuma tarefa pendente.';
        break;
      case 'nearby':
        message = 'Nenhuma tarefa próxima.';
        break;
      default:
        message = 'Nenhuma tarefa cadastrada.';
    }
    return Center(child: Text(message));
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
