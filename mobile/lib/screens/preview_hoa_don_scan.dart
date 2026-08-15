import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile/compoents/custom_dialog.dart';
import 'package:mobile/screens/scan_hoa_don.dart';

class PreviewHoaDonScan extends StatelessWidget {
  const PreviewHoaDonScan({super.key, required this.imagePaths});

  final List<File> imagePaths;

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
                            child: Image.file(
                              imagePaths[index],
                              width: double.infinity,
                              fit: BoxFit.contain,
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
