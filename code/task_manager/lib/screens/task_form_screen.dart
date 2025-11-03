import 'dart:io';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../widgets/location_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  const TaskFormScreen({super.key, this.task});
  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  bool _completed = false;
  bool _isLoading = false;
  List<String> _photoPaths = [];
  double? _latitude;
  double? _longitude;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _priority = widget.task!.priority;
      _completed = widget.task!.completed;
      _photoPaths = List<String>.from(widget.task!.photoPaths);
      _latitude = widget.task!.latitude;
      _longitude = widget.task!.longitude;
      _locationName = widget.task!.locationName;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final photoPath = await CameraService.instance.takePicture(context);
    if (photoPath != null) {
      setState(() => _photoPaths.add(photoPath));
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _photoPaths.add(picked.path));
    }
  }

  Future<void> _applyFilter(int index, String type) async {
    if (_photoPaths.length <= index) return;
    final file = File(_photoPaths[index]);
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return;
    if (type == 'bw') {
      image = img.grayscale(image);
    } else if (type == 'sepia') {
      image = img.sepia(image);
    }
    final filtered = await file.writeAsBytes(img.encodeJpg(image));
    setState(() {
      _photoPaths[index] = filtered.path;
    });
  }

  void _removePhoto(int index) {
    setState(() => _photoPaths.removeAt(index));
  }

  void _viewPhoto(int index) {
    if (_photoPaths.length <= index) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(_photoPaths[index])),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _applyFilter(index, 'bw'),
                  child: const Text('P&B'),
                ),
                TextButton(
                  onPressed: () => _applyFilter(index, 'sepia'),
                  child: const Text('Sépia'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => LocationPicker(
        initialLatitude: _latitude,
        initialLongitude: _longitude,
        initialAddress: _locationName,
        onLocationSelected: (lat, lon, address) {
          setState(() {
            _latitude = lat;
            _longitude = lon;
            _locationName = address;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _removeLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _locationName = null;
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      completed: _completed,
      photoPaths: List<String>.from(_photoPaths),
      latitude: _latitude,
      longitude: _longitude,
      locationName: _locationName,
      createdAt: widget.task?.createdAt,
      completedAt: widget.task?.completedAt,
      completedBy: widget.task?.completedBy,
    );
    if (widget.task == null) {
      await DatabaseService.instance.create(task);
    } else {
      await DatabaseService.instance.update(task);
    }
    setState(() => _isLoading = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o título' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe a descrição' : null,
              ),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: [
                  DropdownMenuItem(value: 'low', child: Text('Baixa')),
                  DropdownMenuItem(value: 'medium', child: Text('Média')),
                  DropdownMenuItem(value: 'high', child: Text('Alta')),
                ],
                onChanged: (v) => setState(() => _priority = v ?? 'medium'),
              ),
              SwitchListTile(
                title: const Text('Concluída'),
                value: _completed,
                onChanged: (v) => setState(() => _completed = v),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Fotos da tarefa'),
                subtitle: _photoPaths.isNotEmpty
                  ? SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photoPaths.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _viewPhoto(index),
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.file(File(_photoPaths[index]), fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _removePhoto(index),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  : Text('Nenhuma foto adicionada'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: _takePicture,
                    ),
                    IconButton(
                      icon: Icon(Icons.photo_library),
                      onPressed: _pickFromGallery,
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.location_on, color: _latitude != null ? Colors.green : null),
                title: Text(_latitude != null ? 'Localização definida' : 'Adicionar localização'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_latitude != null)
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: _removeLocation,
                      ),
                    IconButton(
                      icon: Icon(Icons.map),
                      onPressed: _showLocationPicker,
                    ),
                  ],
                ),
                subtitle: _latitude != null && _longitude != null
                  ? Text('Coordenadas: ${LocationService.instance.formatCoordinates(_latitude!, _longitude!)}')
                  : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTask,
                child: Text(isEditing ? 'Salvar' : 'Criar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
