import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ScanHoaDon extends StatefulWidget {
  const ScanHoaDon({super.key});

  @override
  State<ScanHoaDon> createState() => _ScanHoaDonState();
}

class _ScanHoaDonState extends State<ScanHoaDon> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: _controller == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _initializeControllerFuture;
                          final image = await _controller!.takePicture();
                          // Handle the captured image (e.g., save or display it)
                        } catch (e) {
                          print(e);
                        }
                      },
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras.first, ResolutionPreset.medium);
    _initializeControllerFuture = _controller!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
