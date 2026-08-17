import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class InvoiceOcrResult {
  const InvoiceOcrResult({
    required this.text,
    required this.imagePath,
  });

  final String text;
  final String imagePath;
}

class InvoiceOcrService {
  InvoiceOcrService()
      : _recognizer = TextRecognizer(
          script: TextRecognitionScript.latin,
        );

  final TextRecognizer _recognizer;

  Future<InvoiceOcrResult> recognize(File image) async {
    if (!await image.exists()) {
      throw Exception(
        'Không tìm thấy ảnh: ${image.path}',
      );
    }

    final inputImage = InputImage.fromFile(image);

    final recognizedText = await _recognizer.processImage(
      inputImage,
    );

    return InvoiceOcrResult(
      text: recognizedText.text,
      imagePath: image.path,
    );
  }

  Future<String> recognizeMultiple(
    List<File> images,
  ) async {
    if (images.isEmpty) {
      throw Exception(
        'Không có ảnh để OCR.',
      );
    }

    final result = <String>[];

    for (var i = 0; i < images.length; i++) {
      final recognized = await recognize(images[i]);

      if (recognized.text.trim().isNotEmpty) {
        result.add(
          '''
========== TRANG ${i + 1} ==========

${recognized.text}
''',
        );
      }
    }

    if (result.isEmpty) {
      throw Exception(
        'Không nhận diện được nội dung trong ảnh.',
      );
    }

    return result.join('\n');
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}