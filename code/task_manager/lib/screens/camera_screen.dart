import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';

class CameraScreen extends StatefulWidget {
  final CameraController controller;
  const CameraScreen({super.key, required this.controller});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    if (!widget.controller.value.isInitialized) {
      widget.controller.initialize().then((_) {});
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing || !widget.controller.value.isInitialized) return;
    setState(() => _isCapturing = true);
    try {
      final image = await widget.controller.takePicture();
      Navigator.of(context).pop(image.path);
    } catch (e) {
      print('❌ Erro ao capturar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao capturar foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(widget.controller),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: _takePicture,
                child: const Icon(Icons.camera_alt, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
