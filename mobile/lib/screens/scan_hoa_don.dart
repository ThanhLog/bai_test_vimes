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
  bool _isCapturing = false;
  bool _isDisposed = false;

  @override
  Widget build(BuildContext context) {
    final isReady = !_isDisposed && 
                    _controller != null && 
                    (_controller?.value.isInitialized ?? false);
    
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: SizedBox.expand(
          child: !isReady
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_controller != null && _controller!.value.isInitialized)
                      CameraPreview(_controller!),
                    Positioned(
                      top: 40,
                      left: 20,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
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
                          onPressed: _isCapturing ? null : _captureAndPreview,
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
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _initializeCamera();
  }

  Future<bool> _onBackPressed() async {
    if (_isDisposed) return true;
    
    _isDisposed = true;
    await _controller?.dispose();
    _controller = null;
    _initializeControllerFuture = null;
    
    if (mounted) {
      setState(() {});
    }
    
    return true;
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;
    _isDisposed = false;
    
    final cameras = await availableCameras();
    if (cameras.isEmpty || _isDisposed) return;
    _controller = CameraController(cameras.last, ResolutionPreset.medium);
    _initializeControllerFuture = _controller!.initialize();

    await _initializeControllerFuture;
    if (!mounted || _isDisposed) return;

    await _controller!.setFlashMode(_flashMode);
    if (!mounted || _isDisposed) return;
    setState(() {});
  }

  Future<void> _captureAndPreview() async {
    final controller = _controller;
    if (controller == null || _isDisposed) return;

    setState(() => _isCapturing = true);

    try {
      await _initializeControllerFuture;
      if (_isDisposed) return;
      
      final imageFile = await controller.takePicture();
      final imagePaths = [File(imageFile.path), ...?widget.imagePaths];

      if (!mounted) return;
      
      // Navigate to preview without disposing camera - camera stays active
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewHoaDonScan(imagePaths: imagePaths),
        ),
      );

      // Camera remains active when returning to scan page
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể chụp ảnh. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
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
    final controller = _controller;
    if (controller == null || _isDisposed) return;

    try {
      final images = await ImagePicker().pickMultiImage(
        imageQuality: 85,
        limit: 10,
      );

      if (!mounted || images.isEmpty || _isDisposed) return;

      final imagePaths = [
        ...images.map((img) => File(img.path)),
        ...?widget.imagePaths
      ];

      // Navigate to preview without disposing camera - camera stays active
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewHoaDonScan(imagePaths: imagePaths),
        ),
      );

      // Camera remains active when returning to scan page
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể chọn ảnh từ thư viện.')),
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller?.dispose();
    super.dispose();
  }
}
