import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../screens/camera_screen.dart';

class CameraService {
  static final CameraService instance = CameraService._init();
  CameraService._init();

  List<CameraDescription>? _cameras;

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      print('✅ CameraService: ${_cameras?.length ?? 0} câmera(s) encontrada(s)');
    } catch (e) {
      print('⚠️ Erro ao inicializar câmera: $e');
      _cameras = [];
    }
  }

  bool get hasCameras => _cameras != null && _cameras!.isNotEmpty;

  Future<String?> takePicture(BuildContext context) async {
    if (!hasCameras) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma câmera disponível')),
      );
      return null;
    }
    final camera = _cameras!.first;
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      final image = await controller.takePicture();
      final imagePath = await savePicture(image);
      return imagePath;
    } catch (e) {
      print('❌ Erro ao abrir câmera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir câmera: $e')),
      );
      return null;
    } finally {
      controller.dispose();
    }
  }

  Future<String> savePicture(XFile image) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(image.path);
      final savedImage = await image.saveTo(path.join(appDir.path, fileName));
      return path.join(appDir.path, fileName);
    } catch (e) {
      print('❌ Erro ao salvar foto: $e');
      rethrow;
    }
  }

  Future<bool> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erro ao deletar foto: $e');
      return false;
    }
  }
}
