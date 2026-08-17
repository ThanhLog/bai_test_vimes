import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile/screens/scan_hoa_don.dart';

class PreviewHoaDonScan extends StatefulWidget {
  const PreviewHoaDonScan({super.key, required this.imagePaths});

  final List<File> imagePaths;

  @override
  State<PreviewHoaDonScan> createState() => _PreviewHoaDonScanState();
}

class _PreviewHoaDonScanState extends State<PreviewHoaDonScan> {
  Future<void> _handleDeleteImage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        widget.imagePaths.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Hoá Đơn Scan')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.imagePaths.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    children: [
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                      child: Image.file(
                                        widget.imagePaths[index],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Image.file(widget.imagePaths[index]),
                            ),
                            Positioned(
                              top: 0,
                              right: 5,
                              child: GestureDetector(
                                onTap: () {
                                  _handleDeleteImage(index);
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle retake action
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ScanHoaDon(imagePaths: widget.imagePaths),
                      ),
                    );
                  },
                  child: const Icon(Icons.add_a_photo),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    // Handle confirm action
                    if (mounted) {
                      Navigator.pop(context, widget.imagePaths);
                    }
                  },
                  child: const Icon(Icons.check),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
