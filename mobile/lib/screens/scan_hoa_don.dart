import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/screens/preview_hoa_don_scan.dart';

class ScanHoaDon extends StatefulWidget {
  const ScanHoaDon({super.key, this.imagePaths});

  final List<File>? imagePaths;

  @override
  State<ScanHoaDon> createState() => _ScanHoaDonState();
}

class _ScanHoaDonState extends State<ScanHoaDon> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  FlashMode _flashMode = FlashMode.off;

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
                    top: 40,
                    left: 20,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: Icon(
                        _flashMode == FlashMode.off
                            ? Icons.flash_off
                            : Icons.flash_on,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          try {
                            await _initializeControllerFuture;
                            final imageFile = await _controller!.takePicture();
                            final imagePath = [
                              File(imageFile.path),
                              ...?widget.imagePaths,
                            ];
                            Navigator.push(
                              // ignore: use_build_context_synchronously
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PreviewHoaDonScan(imagePaths: imagePath),
                              ),
                            );
                            // Handle the captured image (e.g., save or display it)
                          } catch (e) {
                            print(e);
                          }
                        },
                        child: const Icon(Icons.camera_alt),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    right: 32,
                    child: IconButton(
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                      ),
                      onPressed: _selectImages,
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
    _controller = CameraController(cameras.last, ResolutionPreset.medium);
    _initializeControllerFuture = _controller!.initialize();

    await _initializeControllerFuture;
    if (!mounted) return;

    await _controller!.setFlashMode(_flashMode);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      await _initializeControllerFuture;
      if (!mounted) return;

      final nextFlashMode = _flashMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;
      await controller.setFlashMode(nextFlashMode);

      if (!mounted) return;
      setState(() {
        _flashMode = nextFlashMode;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thay đổi chế độ flash.')),
        );
      }
    }
  }

  Future<void> _selectImages() async {
    try {
      final images = await ImagePicker().pickMultiImage(
        imageQuality: 85,
        limit: 10,
      );

      if (!mounted || images.isEmpty) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã chọn ${images.length} ảnh.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể chọn ảnh từ thư viện.')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
