import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:mobile/models/chuKy.dart';
import 'package:mobile/models/product.dart';
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
        .replaceAll(RegExp(r'[\u200b\u200c\u200d\ufeff\xa0]'), ' ')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final allText = lines.join('\n');

    String labelled(
      String label, {
      bool requireColon = false,
      String? stopBefore,
    }) {
      final pattern = requireColon
          ? '$label\\s*:\\s*([^\\n]*)'
          : '$label\\s*:?\\s*([^\\n]*)';
      final match = RegExp(
        pattern,
        caseSensitive: false,
      ).firstMatch(allText);
      if (match == null) return '';
      var result = (match.group(1) ?? '').trim();
      if (result.isEmpty || result == ':') {
        result = _nextLineValue(allText, match.end);
      }
      if (stopBefore != null) {
        final cut = RegExp(
          stopBefore,
          caseSensitive: false,
        ).firstMatch(result);
        if (cut != null) {
          result = result.substring(0, cut.start).trim();
        }
      }
      return result;
    }

    var nguoiGiao = labelled(r'Họ\s*(?:và\s*)?tên\s*người\s*giao');
    if (nguoiGiao.isEmpty) {
      nguoiGiao = labelled(r'Người\s*giao', requireColon: true);
    }

    final total = _findTotal(lines);

    return ImportedPhieuNhapKho(
      soPhieu: labelled(
        r'S[ốoô]',
        requireColon: true,
        stopBefore: r'\s+(?:N[ợơọôo]|C[óoô])\s*:',
      ),
      donVi: labelled('Đơn vị', requireColon: true),
      boPhan: labelled('Bộ phận'),
      ngayNhapKho: _findDate(allText),
      no: labelled(r'N[ợơọôo]', requireColon: true),
      co: labelled(r'C[óoô]', requireColon: true),
      maSo: labelled('Mẫu số'),
      nguoiGiao: nguoiGiao,
      theo: _findTheo(allText),
      tongTien: total,
      soChungTuGoc: labelled(
        r'Số\s*chứng\s*từ\s*gốc\s*kèm\s*theo',
        stopBefore: r'\s+Ngày\s',
      ),
      products: _findProducts(lines),
      chuKy: _findSignatures(lines),
    );
  }

  static String _nextLineValue(String allText, int fromIndex) {
    final rest = allText.substring(fromIndex);
    final first = rest
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    if (first.isEmpty || _looksLikeLabel(first)) return '';
    return first;
  }

  static bool _looksLikeLabel(String line) {
    return RegExp(
      r'^[\s\-–—~.>=]*('
      r'Số|Đơn vị|Bộ phận|Ngày|Mẫu số|Nợ|Có|Họ và tên|Họ tên|Theo|Nhập tại|'
      r'Người lập|Người giao|Thủ kho|Kế toán|Tổng số tiền|PHIẾU|STT|Tên|Mã số|TRANG)\b',
      caseSensitive: false,
    ).hasMatch(line);
  }

  static DateTime? _findDate(String text) {
    final match = RegExp(
      r'Ngày\s*(\d{1,2})\s*th(?:á|a)ng\s*(\d{1,2})\s*n(?:ă|a)m\s*(\d{4})',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
  }

  static String _findTheo(String allText) {
    final match = RegExp(
      r'^[\s\-–—~.>=]*Theo\s*:?\s*(?!\s*chứng\s*từ)'
      r'([^\n]+(?:\n\s*ngày[^\n]*)?)',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(allText);
    if (match == null) return '';
    var value = match.group(1)!
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cut = RegExp(
      r'\s+-\s+(?:Nhập tại|Số chứng từ)',
      caseSensitive: false,
    ).firstMatch(value);
    if (cut != null) {
      value = value.substring(0, cut.start).trim();
    }
    return value;
  }

  static String _findTotal(List<String> lines) {
    final totalIndex = lines.indexWhere(
      (line) => RegExp(r'^Cộng\b', caseSensitive: false).hasMatch(line),
    );
    if (totalIndex == -1) return '';

    final numbers = <String>[];

    numbers.addAll(
      RegExp(r'\d[\d.,]*')
          .allMatches(lines[totalIndex])
          .map((match) => match.group(0)!),
    );

    for (final line in lines.skip(totalIndex + 1)) {
      if (!RegExp(r'^[\d.,xX\s]+$').hasMatch(line)) break;
      numbers.addAll(
        RegExp(r'\d[\d.,]*').allMatches(line).map((match) => match.group(0)!),
      );
    }

    return numbers.isEmpty ? '' : numbers.last;
  }

  static List<Product> _findProducts(List<String> lines) {
    final products = <Product>[];

    final tableStart = lines.indexWhere(
      (line) => line.toLowerCase() == 'thực nhập',
    );

    if (tableStart != -1) {
      for (var index = tableStart + 1; index < lines.length; index++) {
        if (RegExp(r'^Cộng$', caseSensitive: false).hasMatch(lines[index])) {
          break;
        }
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
            chungTu: row[3],
            thucNhan: row[4],
            donGia: row[5],
            thanhTien: row[6],
          ),
        );
        index += 7;
      }
    }

    if (products.isNotEmpty) return products;

    return _findLayoutProducts(lines);
  }

  static List<Product> _findLayoutProducts(List<String> lines) {
    final products = <Product>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (RegExp(r'^Cộng\b', caseSensitive: false).hasMatch(line)) break;
      if (line.contains('Tổng số tiền') || line.startsWith('Người lập')) {
        break;
      }

      String id;
      String content;

      if (RegExp(r'^\d+\s+\S').hasMatch(line)) {
        final idMatch = RegExp(r'^\d+').firstMatch(line)!;
        id = idMatch.group(0)!;
        content = line.substring(idMatch.end).trim();
      } else if (RegExp(r'^\d+$').hasMatch(line) &&
          i + 1 < lines.length &&
          RegExp(r'[A-Za-zÀ-ỹĐđ]{1,6}-\d+').hasMatch(lines[i + 1])) {
        id = line;
        content = lines[i + 1];
        i++;
      } else {
        continue;
      }

      while (i + 1 < lines.length) {
        final next = lines[i + 1];
        if (RegExp(r'^\d+\s+\S').hasMatch(next)) break;
        if (RegExp(r'^Cộng\b', caseSensitive: false).hasMatch(next)) break;
        if (next.contains('Tổng số tiền') || next.startsWith('Người lập')) {
          break;
        }
        if (!_isRowContinuation(next)) break;
        content = '$content ${next.trim()}';
        i++;
      }

      final product = _parseLayoutRow(id, content);
      if (product != null) {
        products.add(product);
      }
    }

    return products;
  }

  static bool _isRowContinuation(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('-')) return false;
    if (RegExp(
      r'^(Cộng|Ngày|Người lập|Kế toán|Thủ kho|Tổng số)',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return false;
    }
    return RegExp(
      r'^(?:[A-Za-zÀ-ỹĐđ][\wÀ-ỹĐđ]*|[A-Za-zÀ-ỹĐđ]{1,6}-\d+|\d[\d.,]*)'
      r'(?:\s+(?:[A-Za-zÀ-ỹĐđ][\wÀ-ỹĐđ]*|[A-Za-zÀ-ỹĐđ]{1,6}-\d+|\d[\d.,]*))*$',
    ).hasMatch(trimmed);
  }

  static Product? _parseLayoutRow(String id, String content) {
    final tokens = content
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;

    bool isNumber(String token) => RegExp(r'^\d[\d.,]*$').hasMatch(token);

    var runStart = -1;
    var runEnd = -1;
    var i = 0;
    while (i < tokens.length) {
      if (isNumber(tokens[i])) {
        final start = i;
        while (i < tokens.length && isNumber(tokens[i])) {
          i++;
        }
        if (i - start >= 4) {
          runStart = start;
          runEnd = start + 4;
        }
      } else {
        i++;
      }
    }
    if (runStart == -1) return null;

    if (runStart == 0 || isNumber(tokens[runStart - 1])) return null;

    String? code;
    var nameEnd = runStart - 1;
    for (var j = 0; j < runStart - 1; j++) {
      if (RegExp(r'^[A-Za-z]{1,6}-\d+$').hasMatch(tokens[j])) {
        code = tokens[j];
        nameEnd = j;
        break;
      }
    }
    if (code == null) return null;

    final codeFragments = <String>[];

    for (var j = nameEnd + 1; j < runStart - 1; j++) {
      if (RegExp(r'^\d{1,4}$').hasMatch(tokens[j])) {
        codeFragments.add(tokens[j]);
      }
    }

    final nameTail = <String>[];
    for (var j = runEnd; j < tokens.length; j++) {
      if (RegExp(r'^\d{1,4}$').hasMatch(tokens[j])) {
        codeFragments.add(tokens[j]);
      } else {
        nameTail.add(tokens[j]);
      }
    }

    final name = [
      ...tokens.sublist(0, nameEnd),
      ...nameTail,
    ].join(' ').trim();
    if (name.isEmpty) return null;

    var finalCode = code;
    for (final fragment in codeFragments) {
      if (!finalCode.endsWith(fragment)) {
        finalCode = '$finalCode$fragment';
      }
    }

    return Product(
      id: id,
      name: name,
      maSo: finalCode,
      chungTu: tokens[runStart],
      thucNhan: tokens[runStart + 1],
      donGia: tokens[runStart + 2],
      thanhTien: tokens[runStart + 3],
    );
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
    final names = <String>[];

    for (final raw in lines) {
      final line = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty) continue;
      if (line.startsWith('(')) continue;
      if (line.startsWith('Ngày ')) continue;
      if (_isNoiseLine(line)) continue;
      if (_isLetterMarkerLine(line)) continue;

      final tokens = line.split(' ');
      final singleLetters = tokens
          .where((token) => RegExp(r'^[A-ZĐ]$').hasMatch(token))
          .length;

      if (singleLetters >= 2) {
        for (final chunk in _splitConcatenatedNames(tokens)) {
          if (_isValidName(chunk)) {
            names.add(_removeInitialPrefix(chunk));
          }
        }
      } else if (_isValidName(line)) {
        names.add(_removeInitialPrefix(line));
      }

      if (names.length >= 4) break;
    }

    return names;
  }

  static bool _isLetterMarkerLine(String line) {
    final tokens = line.split(' ');
    return tokens.length >= 2 &&
        tokens.every(
          (token) => RegExp(r'^[A-ZĐ]$').hasMatch(token),
        );
  }

  static bool _isNoiseLine(String line) {
    return RegExp(
      r'bản sao|thẻ|trang',
      caseSensitive: false,
    ).hasMatch(line);
  }

  static bool _isValidName(String value) {
    final tokens = value.split(' ');
    if (tokens.length < 2 || tokens.length > 4) return false;
    return tokens.every(
      (token) => RegExp(
        r'^[A-ZÀ-ỸĐ][A-Za-zÀ-ỹĐđ]*$',
      ).hasMatch(token),
    );
  }

  static List<String> _splitConcatenatedNames(List<String> tokens) {
    final chunks = <String>[];
    var current = <String>[];

    for (final token in tokens) {
      current.add(token);
      if (RegExp(r'^[A-ZĐ]$').hasMatch(token)) {
        chunks.add(current.join(' '));
        current = <String>[];
      }
    }
    if (current.isNotEmpty) {
      chunks.add(current.join(' '));
    }

    return chunks;
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
