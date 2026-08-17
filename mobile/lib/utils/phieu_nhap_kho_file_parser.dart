import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile/models/chuKy.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/utils/phieu_nhap_kho_ocr_normalizer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ImportedPhieuNhapKho {
  const ImportedPhieuNhapKho({
    required this.soPhieu,
    required this.donVi,
    required this.boPhan,
    required this.ngayNhapKho,
    required this.no,
    required this.co,
    required this.maSo,
    required this.nguoiGiao,
    required this.theo,
    required this.tongTien,
    required this.soChungTuGoc,
    required this.products,
    required this.chuKy,
  });

  final String soPhieu;
  final String donVi;
  final String boPhan;
  final DateTime? ngayNhapKho;
  final String no;
  final String co;
  final String maSo;
  final String nguoiGiao;
  final String theo;
  final String tongTien;
  final String soChungTuGoc;
  final List<Product> products;
  final ChuKy chuKy;
}

/// Extracts the fields used by the VIMES "Phiếu nhập kho" template.
class PhieuNhapKhoFileParser {
  static Future<ImportedPhieuNhapKho> parse(File file) async {
    final name = file.path.toLowerCase();
    final text = name.endsWith('.pdf')
        ? await _pdfText(file)
        : name.endsWith('.docx')
        ? await _docxText(file)
        : throw const FormatException('Chỉ hỗ trợ file PDF hoặc DOCX.');

    if (text.trim().isEmpty) {
      throw const FormatException(
        'Không tìm thấy văn bản trong file. Với file PDF scan, hãy dùng OCR.',
      );
    }
    return _fromText(text);
  }

  static ImportedPhieuNhapKho parseText(String text) {
    if (text.trim().isEmpty) {
      throw const FormatException('Không nhận diện được nội dung hóa đơn.');
    }

    return _fromText(text);
  }

  static Future<ImportedPhieuNhapKho> parseImages(List<File> images) async {
    if (images.isEmpty) {
      throw const FormatException('Không có ảnh hóa đơn để scan.');
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final pages = <String>[];

      for (var i = 0; i < images.length; i++) {
        final image = images[i];

        if (!await image.exists()) {
          continue;
        }

        final inputImage = InputImage.fromFile(image);

        final recognizedText = await recognizer.processImage(inputImage);

        final rawText = recognizedText.text.trim();

        if (rawText.isEmpty) {
          continue;
        }

        // Normalize riêng từng page.
        final normalizedText = PhieuNhapKhoOcrNormalizer.normalize(rawText);

        if (normalizedText.trim().isEmpty) {
          continue;
        }

        pages.add('''
========== TRANG ${i + 1} ==========

$normalizedText
''');
      }

      if (pages.isEmpty) {
        throw const FormatException(
          'OCR không nhận diện được nội dung hóa đơn.',
        );
      }

      final rawText = pages.join('\n');

      return _fromText(rawText);
    } finally {
      await recognizer.close();
    }
  }

  static Future<String> _pdfText(File file) async {
    final document = PdfDocument(inputBytes: await file.readAsBytes());
    try {
      return PdfTextExtractor(document).extractText(layoutText: true);
    } finally {
      document.dispose();
    }
  }

  static Future<String> _docxText(File file) async {
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final document = archive.findFile('word/document.xml');
    if (document == null) {
      throw const FormatException('File DOCX không hợp lệ.');
    }

    final bytes = document.readBytes();
    if (bytes == null) {
      throw const FormatException('Không thể đọc nội dung file DOCX.');
    }
    final xml = utf8.decode(bytes);
    final paragraphs = RegExp(r'<w:p(?:\s[^>]*)?>(.*?)</w:p>', dotAll: true)
        .allMatches(xml)
        .map((paragraph) {
          return RegExp(r'<w:t(?:\s[^>]*)?>(.*?)</w:t>', dotAll: true)
              .allMatches(paragraph.group(1)!)
              .map((text) => _decodeXml(text.group(1)!))
              .join();
        })
        .where((line) => line.trim().isNotEmpty);
    return paragraphs.join('\n');
  }

  static String _decodeXml(String value) => value
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");

  static ImportedPhieuNhapKho _fromText(String value) {
    final lines = value
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final allText = lines.join('\n');

    String labelled(String label) {
      final match = RegExp(
        label,
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(allText);
      return match?.group(1)?.trim() ?? '';
    }

    final total = _findTotal(lines);
    return ImportedPhieuNhapKho(
      soPhieu: labelled(r'Số\s*:\s*([^\n]+)'),
      donVi: labelled(r'Đơn vị\s*:\s*([^\n]+)'),
      boPhan: labelled(r'Bộ phận\s*:\s*([^\n]+)'),
      ngayNhapKho: _findDate(allText),
      no: labelled(r'Nợ\s*:\s*([^\n]+)'),
      co: labelled(r'Có\s*:\s*([^\n]+)'),
      maSo: labelled(r'Mẫu số\s*([^\n]+)'),
      nguoiGiao: labelled(r'Họ và tên người giao\s*:\s*([^\n]+)'),
      theo: labelled(r'-?\s*Theo\s+([^\n]+)'),
      tongTien: total,
      soChungTuGoc: labelled(r'Số chứng từ gốc kèm theo\s*:\s*([^\n]+)'),
      products: _findProducts(lines, allText),
      chuKy: _findSignatures(lines),
    );
  }

  static DateTime? _findDate(String text) {
    final match = RegExp(
      r'Ngày\s*(\d{1,2})\s*tháng\s*(\d{1,2})\s*năm\s*(\d{4})',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
  }

  static String _findTotal(List<String> lines) {
    final totalIndex = lines.indexWhere(
      (line) => RegExp(r'^Cộng\b', caseSensitive: false).hasMatch(line),
    );
    if (totalIndex == -1) return '';
    final valuesOnTotalLine = RegExp(
      r'\d[\d.,]*',
    ).allMatches(lines[totalIndex]).map((match) => match.group(0)!).toList();
    if (valuesOnTotalLine.isNotEmpty) return valuesOnTotalLine.last;
    final values = RegExp(r'\d[\d.,]*')
        .allMatches(lines.skip(totalIndex + 1).take(8).join(' '))
        .map((match) => match.group(0)!)
        .toList();
    return values.isEmpty ? '' : values.last;
  }

  static List<Product> _findProducts(List<String> lines, String allText) {
    // PDF text extraction splits the "STT" heading into two lines, while
    // DOCX keeps it intact. Only use the layout-based parser for that PDF form.
    if (lines.contains('ST') && lines.contains('T')) {
      final layoutProducts = _findLayoutProducts(allText);
      if (layoutProducts.isNotEmpty) return layoutProducts;
    }

    final products = <Product>[];
    final tableStart = lines.indexWhere((line) => line == 'Thực nhập');
    if (tableStart == -1) return products;

    for (var index = tableStart + 1; index < lines.length; index++) {
      if (RegExp(r'^Cộng$', caseSensitive: false).hasMatch(lines[index])) break;
      if (!RegExp(r'^\d+$').hasMatch(lines[index])) continue;
      if (index + 7 >= lines.length) break;

      final row = lines.sublist(index + 1, index + 8);
      if (!RegExp(r'^\d[\d.,]*$').hasMatch(row[4]) ||
          !RegExp(r'^\d[\d.,]*$').hasMatch(row[5]) ||
          !RegExp(r'^\d[\d.,]*$').hasMatch(row[6])) {
        continue;
      }
      products.add(
        Product(
          id: lines[index],
          name: row[0],
          maSo: row[1],
          thucNhan: row[4],
          donGia: row[5],
        ),
      );
      index += 7;
    }
    return products;
  }

  static List<Product> _findLayoutProducts(String text) {
    final rowPattern = RegExp(
      r'^\s*(\d+)\s+(.+?)\s+([A-Z]{1,6}-\d\s*\d+)\s+(\S+)\s+'
      r'(\d[\d.,]*)\s+(\d[\d.,]*)\s+(\d[\d.,]*)\s+(\d[\d.,]*)\s*'
      r'(?=^\s*(?:\d+\s+|Cộng\b))',
      multiLine: true,
      dotAll: true,
    );

    return rowPattern.allMatches(text).map((match) {
      return Product(
        id: match.group(1)!,
        name: match.group(2)!.replaceAll(RegExp(r'\s+'), ' ').trim(),
        maSo: match.group(3)!.replaceAll(RegExp(r'\s+'), ''),
        thucNhan: match.group(6)!,
        donGia: match.group(7)!,
      );
    }).toList();
  }

  static ChuKy _findSignatures(List<String> lines) {
    for (var index = lines.length - 1; index >= 0; index--) {
      if (!lines[index].contains('Kế toán trưởng')) continue;
      final names = _signatureNames(lines.skip(index + 1));
      if (names.length >= 4) {
        return ChuKy(
          nguoiLapPhieu: names[0],
          nguoiGiaoHang: names[1],
          thuKho: names[2],
          keToanTruong: names[3],
        );
      }
    }

    return const ChuKy(
      nguoiLapPhieu: '',
      nguoiGiaoHang: '',
      thuKho: '',
      keToanTruong: '',
    );
  }

  static List<String> _signatureNames(Iterable<String> lines) {
    return lines
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where(
          (line) =>
              !line.startsWith('(') &&
              !line.startsWith('Ngày ') &&
              line.split(' ').length >= 2 &&
              RegExp(r'^[A-ZÀ-ỸĐ]').hasMatch(line),
        )
        .map(_removeInitialPrefix)
        .take(4)
        .toList();
  }

  static String _removeInitialPrefix(String value) {
    if (RegExp(
      r'^[A-ZĐ][A-ZĐÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĨŨƠƯẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀỂỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪỬỮỰỲỴỶỸ]',
    ).hasMatch(value)) {
      return value.substring(1);
    }
    return value;
  }
}
