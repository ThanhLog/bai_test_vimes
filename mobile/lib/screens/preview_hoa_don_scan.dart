import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile/compoents/custom_dialog.dart';
import 'package:mobile/screens/scan_hoa_don.dart';

class PreviewHoaDonScan extends StatelessWidget {
  const PreviewHoaDonScan({super.key, required this.imagePaths});

  final List<File> imagePaths;

  Function _handleDeleteImage(BuildContext context, int index) {
    return () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Image'),
          content: Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                imagePaths.removeAt(index);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text('Preview Hoá Đơn Scan')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
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
                              color: Colors.black.withValues(alpha: 0.8),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Image.file(imagePaths[index]),
                                ),
                                Positioned(
                                  top: 40,
                                  right: 20,
                                  child: 
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.white),
                                        onPressed: () {
                                          _handleDeleteImage(context, index);
                                        },
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Image.file(imagePaths[index]),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
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
                            ScanHoaDon(imagePaths: imagePaths),
                      ),
                    );
                  },
                  child: Icon(Icons.add_a_photo),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    // Handle confirm action
                    showDialog(
                      context: context,
                      builder: (context) => CustomDialog(
                        title: 'Confirm',
                        child: Text('Confirm'),
                      ),
                    );
                  },
                  child: Icon(Icons.check),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
