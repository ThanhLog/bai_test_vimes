class PhieuNhapKhoOcrNormalizer {
  const PhieuNhapKhoOcrNormalizer._();

  /// Chuẩn hóa text OCR từ ảnh trước khi đưa vào
  /// PhieuNhapKhoFileParser._fromText()
  static String normalize(String text) {
    if (text.trim().isEmpty) {
      return '';
    }

    var lines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[\u200b\u200c\u200d\ufeff\xa0]'), ' ')
        .split('\n')
        .map(
          (line) => line
              .replaceAll(RegExp(r'[ \t]+'), ' ')
              .trim(),
        )
        .where((line) => line.isNotEmpty)
        .toList();

    // 1. ST + T -> STT
    lines = _mergeStt(lines);

    // 2. Tách 'Nợ: 152 Có: 331' nằm chung 1 dòng
    lines = _splitNoCoLines(lines);

    // 3. Chuẩn hóa Nợ
    lines = _normalizeNo(lines);

    // 4. Chuẩn hóa Có
    lines = _normalizeCo(lines);

    // 5. Chuẩn hóa Số phiếu
    lines = _normalizeSoPhieu(lines);

    // 6. Chuẩn hóa số chứng từ gốc
    lines = _normalizeSoChungTu(lines);

    // 7. Ghép mã sản phẩm bị OCR tách dòng
    //
    // VT-0
    // 01
    //
    // =>
    //
    // VT-001
    lines = _mergeProductCodes(lines);

    // 8. Ghép tên sản phẩm bị xuống dòng
    lines = _mergeProductNames(lines);

    // 9. Chuẩn hóa header bảng
    lines = _normalizeTableHeaders(lines);

    // 10. Chuẩn hóa vùng chữ ký
    lines = _normalizeSignatureSection(lines);

    return lines.join('\n');
  }

  // ============================================================
  // STT
  // ============================================================

  static List<String> _mergeStt(
    List<String> lines,
  ) {
    final result = <String>[];

    var i = 0;

    while (i < lines.length) {
      final current = lines[i].trim();

      if (current.toUpperCase() == 'ST' &&
          i + 1 < lines.length &&
          lines[i + 1].trim().toUpperCase() == 'T') {
        result.add('STT');
        i += 2;
        continue;
      }

      // Một số OCR có thể đọc thành:
      // S T T
      if (current.replaceAll(' ', '').toUpperCase() == 'STT') {
        result.add('STT');
        i++;
        continue;
      }

      result.add(current);
      i++;
    }

    return result;
  }

  // ============================================================
  // NỢ / CÓ
  // ============================================================

  /// Tách dòng OCR đọc chung 2 tài khoản, VD:
  ///
  /// Nợ: 152 Có: 331
  ///
  /// =>
  ///
  /// Nợ: 152
  /// Có: 331
  static List<String> _splitNoCoLines(
    List<String> lines,
  ) {
    final result = <String>[];

    for (final line in lines) {
      final match = RegExp(
        r'^(N[ợơọôo]\s*:\s*\S.*?)(?=\s+-?\s*C[óoô]\s*:)',
        caseSensitive: false,
      ).firstMatch(line);

      if (match == null) {
        result.add(line);
        continue;
      }

      result.add(match.group(1)!);
      result.add(line.substring(match.end).trim());
    }

    return result;
  }

  // ============================================================
  // NỢ
  // ============================================================

  static List<String> _normalizeNo(
    List<String> lines,
  ) {
    final result = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      final match = RegExp(
        r'^N[ợơọôo]\s*:?\s*(.*)$',
        caseSensitive: false,
      ).firstMatch(line);

      if (match == null) {
        result.add(line);
        continue;
      }

      var value = match.group(1)?.trim() ?? '';

      // 'Nợ:' đứng riêng 1 dòng — regex có thể bắt nhầm chính dấu ':'.
      if (value == ':') {
        value = '';
      }

      // Không có dấu ':' mà giá trị không giống mã tài khoản
      // (VD: 'Nơi sản xuất...') thì không phải nhãn Nợ — giữ nguyên.
      if (!line.contains(':') &&
          value.isNotEmpty &&
          !_looksLikeAccountCode(value)) {
        result.add(line);
        continue;
      }

      // OCR có thể đọc:
      //
      // Nợ:
      // 152
      //
      if (value.isEmpty &&
          i + 1 < lines.length &&
          _looksLikeAccountCode(lines[i + 1])) {
        value = lines[i + 1].trim();
        i++;
      }

      result.add(
        value.isEmpty
            ? 'Nợ:'
            : 'Nợ: $value',
      );
    }

    return result;
  }

  // ============================================================
  // CÓ
  // ============================================================

  static List<String> _normalizeCo(
    List<String> lines,
  ) {
    final result = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      final match = RegExp(
        r'^C[óoô]\s*:?\s*(.*)$',
        caseSensitive: false,
      ).firstMatch(line);

      if (match == null) {
        result.add(line);
        continue;
      }

      var value = match.group(1)?.trim() ?? '';

      // 'Có:' đứng riêng 1 dòng — regex có thể bắt nhầm chính dấu ':'.
      if (value == ':') {
        value = '';
      }

      // Không có dấu ':' mà giá trị không giống mã tài khoản
      // (VD: 'Công ty...') thì không phải nhãn Có — giữ nguyên.
      if (!line.contains(':') &&
          value.isNotEmpty &&
          !_looksLikeAccountCode(value)) {
        result.add(line);
        continue;
      }

      // OCR:
      //
      // Có:
      // 331
      //
      if (value.isEmpty &&
          i + 1 < lines.length &&
          _looksLikeAccountCode(lines[i + 1])) {
        value = lines[i + 1].trim();
        i++;
      }

      result.add(
        value.isEmpty
            ? 'Có:'
            : 'Có: $value',
      );
    }

    return result;
  }

  static bool _looksLikeAccountCode(
    String value,
  ) {
    return RegExp(
      r'^\d{2,6}([./-]\d+)*$',
    ).hasMatch(value.trim());
  }

  // ============================================================
  // SỐ PHIẾU
  // ============================================================

  static List<String> _normalizeSoPhieu(
    List<String> lines,
  ) {
    return lines.map((line) {
      // Dòng 'Số chứng từ gốc kèm theo...' không phải số phiếu.
      if (RegExp(
        r'chứng\s*từ',
        caseSensitive: false,
      ).hasMatch(line)) {
        return line;
      }

      final match = RegExp(
        r'^S[ốoô]\s*:?\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(line);

      if (match == null) {
        return line;
      }

      // 'Số:' đứng riêng 1 dòng — regex có thể bắt nhầm chính dấu ':'.
      final value = match.group(1)!.trim();
      if (value == ':') {
        return line;
      }

      return 'Số: $value';
    }).toList();
  }

  // ============================================================
  // SỐ CHỨNG TỪ GỐC
  // ============================================================

  static List<String> _normalizeSoChungTu(
    List<String> lines,
  ) {
    final result = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      final isLabel = RegExp(
        r'Số\s*chứng\s*từ\s*gốc\s*kèm\s*theo',
        caseSensitive: false,
      ).hasMatch(line);

      if (!isLabel) {
        result.add(line);
        continue;
      }

      final colonIndex = line.indexOf(':');

      // Trường hợp:
      //
      // Số chứng từ gốc kèm theo:
      // 01 Hóa đơn...
      //
      if (colonIndex == -1) {
        result.add(
          'Số chứng từ gốc kèm theo:',
        );

        if (i + 1 < lines.length) {
          final next = lines[i + 1].trim();

          if (next.isNotEmpty) {
            result.add(next);
            i++;
          }
        }

        continue;
      }

      final label = line.substring(
        0,
        colonIndex + 1,
      );

      final value = line
          .substring(colonIndex + 1)
          .trim();

      result.add(
        value.isEmpty
            ? label
            : '$label $value',
      );
    }

    return result;
  }

  // ============================================================
  // PRODUCT CODE
  // ============================================================

  static List<String> _mergeProductCodes(
    List<String> lines,
  ) {
    final result = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final current = lines[i].trim();

      // VT-0
      // 01
      //
      // =>
      //
      // VT-001
      if (RegExp(
            r'^[A-Z]{1,6}-\d+$',
            caseSensitive: false,
          ).hasMatch(current) &&
          i + 1 < lines.length) {
        final next = lines[i + 1].trim();

        if (RegExp(
          r'^\d{1,4}$',
        ).hasMatch(next)) {
          result.add('$current$next');
          i++;
          continue;
        }
      }

      // VT- 001
      final spacedCode = RegExp(
        r'^([A-Z]{1,6})-\s+(\d+)$',
        caseSensitive: false,
      ).firstMatch(current);

      if (spacedCode != null) {
        result.add(
          '${spacedCode.group(1)}-${spacedCode.group(2)}',
        );
        continue;
      }

      result.add(current);
    }

    return result;
  }

  // ============================================================
  // PRODUCT NAME
  // ============================================================

  static List<String> _mergeProductNames(
    List<String> lines,
  ) {
    final result = <String>[];

    var i = 0;

    while (i < lines.length) {
      final current = lines[i].trim();

      // Tìm STT
      if (RegExp(r'^\d+$').hasMatch(current)) {
        // Dòng số đứng ngay trước 1 dòng sản phẩm hoàn chỉnh
        // (bắt đầu bằng STT + nội dung, VD: '05' nằm dưới dòng sản phẩm)
        // là mã sản phẩm bị OCR tách dòng — không phải STT, giữ nguyên.
        final next = i + 1 < lines.length ? lines[i + 1].trim() : '';

        if (next.isNotEmpty && RegExp(r'^\d+\s+\S').hasMatch(next)) {
          result.add(current);
          i++;
          continue;
        }

        result.add(current);

        i++;

        final nameParts = <String>[];

        while (i < lines.length) {
          final line = lines[i].trim();

          // Mã sản phẩm => kết thúc tên
          if (_isProductCode(line)) {
            break;
          }

          // STT mới
          if (RegExp(r'^\d+$').hasMatch(line)) {
            break;
          }

          // Đơn vị
          if (_isUnit(line)) {
            break;
          }

          // Header/footer
          if (_isTableBoundary(line)) {
            break;
          }

          // Dòng chứa cả mã sản phẩm lẫn số liệu là
          // 1 dòng sản phẩm hoàn chỉnh — không phải phần tên.
          if (_looksLikeFullRow(line)) {
            break;
          }

          if (_looksLikeProductName(line)) {
            nameParts.add(line);
            i++;
            continue;
          }

          break;
        }

        if (nameParts.isNotEmpty) {
          result.add(
            nameParts.join(' ').trim(),
          );
        }

        continue;
      }

      result.add(current);
      i++;
    }

    return result;
  }

  static bool _isProductCode(
    String line,
  ) {
    return RegExp(
      r'^[A-Z]{1,6}-\d+$',
      caseSensitive: false,
    ).hasMatch(line);
  }

  /// Dòng chứa cả mã sản phẩm (XXX-NNN) lẫn >= 4 số liệu liên tiếp
  /// — tức là cả dòng sản phẩm đã nằm gọn trên 1 dòng (dạng layout).
  static bool _looksLikeFullRow(
    String line,
  ) {
    return RegExp(
      r'[A-Za-zÀ-ỹĐđ]{1,6}-\d+',
    ).hasMatch(line) &&
        RegExp(
          r'\d[\d.,]*(?:\s+\d[\d.,]*){3}',
        ).hasMatch(line);
  }

  static bool _looksLikeProductName(
    String line,
  ) {
    if (line.isEmpty) {
      return false;
    }

    if (RegExp(
      r'^\d[\d.,]*$',
    ).hasMatch(line)) {
      return false;
    }

    if (_isProductCode(line)) {
      return false;
    }

    if (_isUnit(line)) {
      return false;
    }

    if (_isTableBoundary(line)) {
      return false;
    }

    return RegExp(
      r'[A-Za-zÀ-ỹĐđ]',
    ).hasMatch(line);
  }

  // ============================================================
  // UNIT
  // ============================================================

  static bool _isUnit(
    String line,
  ) {
    const units = {
      'kg',
      'g',
      'mg',
      'tấn',
      'tan',
      'bao',
      'viên',
      'vien',
      'm3',
      'm²',
      'm2',
      'mét',
      'met',
      'thùng',
      'thung',
      'cái',
      'cai',
      'cây',
      'cay',
      'chiếc',
      'chiec',
      'bộ',
      'bo',
      'hộp',
      'hop',
      'lít',
      'lit',
    };

    return units.contains(
      line.toLowerCase().trim(),
    );
  }

  // ============================================================
  // TABLE BOUNDARY
  // ============================================================

  static bool _isTableBoundary(
    String line,
  ) {
    final lower = line
        .toLowerCase()
        .trim();

    return lower == 'stt' ||
        lower == 'tên, nhãn hiệu' ||
        lower == 'tên nhãn hiệu' ||
        lower == 'mã số' ||
        lower == 'đơn vị tính' ||
        lower == 'số lượng' ||
        lower == 'đơn giá' ||
        lower == 'thành tiền' ||
        lower == 'theo chứng từ' ||
        lower == 'thực nhập' ||
        lower.startsWith('cộng') ||
        lower.contains('tổng số tiền') ||
        lower.contains('số chứng từ gốc') ||
        lower.contains('người lập phiếu') ||
        lower.contains('người giao hàng') ||
        lower.contains('thủ kho') ||
        lower.contains('kế toán trưởng');
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  static List<String> _normalizeTableHeaders(
    List<String> lines,
  ) {
    return lines.map((line) {
      final upper = line
          .toUpperCase()
          .replaceAll(' ', '');

      if (upper == 'STT') {
        return 'STT';
      }

      if (upper == 'THỰCNHẬP') {
        return 'Thực nhập';
      }

      if (upper == 'THEOCHỨNGTỪ') {
        return 'Theo chứng từ';
      }

      if (upper == 'ĐƠNVỊTÍNH') {
        return 'Đơn vị tính';
      }

      if (upper == 'SỐLƯỢNG') {
        return 'Số lượng';
      }

      if (upper == 'ĐƠNGIÁ') {
        return 'Đơn giá';
      }

      if (upper == 'THÀNHTIỀN') {
        return 'Thành tiền';
      }

      return line;
    }).toList();
  }

  // ============================================================
  // SIGNATURE
  // ============================================================

  static List<String> _normalizeSignatureSection(
    List<String> lines,
  ) {
    final result = <String>[];

    for (final line in lines) {
      var normalized = line;

      normalized = normalized
          .replaceAll(
            RegExp(
              r'Kế\s*toán\s*trưởng',
              caseSensitive: false,
            ),
            'Kế toán trưởng',
          )
          .replaceAll(
            RegExp(
              r'Người\s*lập\s*phiếu',
              caseSensitive: false,
            ),
            'Người lập phiếu',
          )
          .replaceAll(
            RegExp(
              r'Người\s*giao\s*hàng',
              caseSensitive: false,
            ),
            'Người giao hàng',
          )
          .replaceAll(
            RegExp(
              r'Thủ\s*kho',
              caseSensitive: false,
            ),
            'Thủ kho',
          );

      result.add(normalized.trim());
    }

    return result;
  }
}