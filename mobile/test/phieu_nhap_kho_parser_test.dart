import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/utils/phieu_nhap_kho_file_parser.dart';
import 'package:mobile/utils/phieu_nhap_kho_ocr_normalizer.dart';

/// Text mô phỏng output của ML Kit khi chụp ảnh form
/// 'Mẫu Phiếu Nhập Kho - VIMES' (đọc theo dòng ngang như pdftotext -layout).
const layoutFixture = '''
Đơn vị: Công ty A
Bộ phận: Kho Vật Tư Trung Tâm
                                              Mẫu số 01 - VT
                                    (Ban hành theo Thông tư số 200/2014/TT-BTC
                                         Ngày 22/12/2014 của Bộ Tài chính)


                              PHIẾU NHẬP KHO
                                        Ngày 13 tháng 08 năm 2026
Số: NK-2026/08-01
                                                                                                   Nợ: 152
                                                                                                   Có: 331
- Họ và tên người giao: Ông B
- Theo Hóa đơn GTGT số 0001245 ngày 12 tháng 08 năm 2026 của Công ty C
- Nhập tại kho: Kho Tổng Số 1 địa điểm: KCN Yên Mỹ, Hưng Yên
 ST      Tên, nhãn hiệu,      Mã         Đơn vị              Số lượng             Đơn giá          Thành tiền
  T      quy cách, phẩm       số          tính
        chất vật tư, dụng                               Theo           Thực
          cụ sản phẩm,                                chứng từ         nhập
            hàng hoá

  1    Thép cuộn Phi 8 Hòa    VT-0          Kg              1.000         1.000           15.500    15.500.000
       Phát                    01

  2    Xi măng Hà Tiên        VT-0         Bao                200           200           88.000    17.600.000
       PCB40                   02

  3    Gạch tuynel 2 lỗ A1    VT-0         Viên             5.000         5.000            1.300     6.500.000
                               03

  4    Cát xây trát vàng      VT-0          m3                 50            50          250.000    12.500.000
                               04

  5    Sơn nội thất cao cấp   VT-0        Thùng                10            10     1.500.000       15.000.000
                               05

  6    Ống nhựa PVC Tiền      VT-0         Mét                100           100           25.000     2.500.000
       Phong                   06

           Cộng                 x            x              6.360         6.360      x              69.600.000
- Tổng số tiền (viết bằng chữ): Sáu mươi chín triệu sáu trăm nghìn đồng chẵn.
- Số chứng từ gốc kèm theo: 01 Hóa đơn GTGT gốc + 01 Biên bản giao nhận
                                                                    Ngày 13 tháng 08 năm 2026


    Người lập phiếu         Người giao hàng              Thủ kho              Kế toán trưởng
      (Ký, họ tên)            (Ký, họ tên)              (Ký, họ tên)        (Hoặc bộ phận có nhu
                                                                                 cầu nhập)
                                                                                (Ký, họ tên)



          A                      B                        C                      D
    Nguyễn Văn A               Trần Thị B                Lê Văn C               Phạm Thị D
''';

void _expectCommonFields(ImportedPhieuNhapKho result) {
  expect(result.soPhieu, 'NK-2026/08-01');
  expect(result.donVi, 'Công ty A');
  expect(result.boPhan, 'Kho Vật Tư Trung Tâm');
  expect(result.ngayNhapKho, DateTime(2026, 08, 13));
  expect(result.no, '152');
  expect(result.co, '331');
  expect(result.maSo, '01 - VT');
  expect(result.nguoiGiao, 'Ông B');
  expect(
    result.theo,
    'Hóa đơn GTGT số 0001245 ngày 12 tháng 08 năm 2026 của Công ty C',
  );
  expect(result.tongTien, '69.600.000');
  expect(
    result.soChungTuGoc,
    '01 Hóa đơn GTGT gốc + 01 Biên bản giao nhận',
  );
}

void _expectProducts(List<Product> products) {
  expect(products, hasLength(6));
  final expected = [
    ('1', 'Thép cuộn Phi 8 Hòa Phát', 'VT-001', '1.000', '1.000', '15.500', '15.500.000'),
    ('2', 'Xi măng Hà Tiên PCB40', 'VT-002', '200', '200', '88.000', '17.600.000'),
    ('3', 'Gạch tuynel 2 lỗ A1', 'VT-003', '5.000', '5.000', '1.300', '6.500.000'),
    ('4', 'Cát xây trát vàng', 'VT-004', '50', '50', '250.000', '12.500.000'),
    ('5', 'Sơn nội thất cao cấp', 'VT-005', '10', '10', '1.500.000', '15.000.000'),
    ('6', 'Ống nhựa PVC Tiền Phong', 'VT-006', '100', '100', '25.000', '2.500.000'),
  ];
  for (var i = 0; i < expected.length; i++) {
    final (id, name, maSo, chungTu, thucNhan, donGia, thanhTien) = expected[i];
    expect(products[i].id, id);
    expect(products[i].name, name);
    expect(products[i].maSo, maSo);
    expect(products[i].chungTu, chungTu);
    expect(products[i].thucNhan, thucNhan);
    expect(products[i].donGia, donGia);
    expect(products[i].thanhTien, thanhTien);
  }
}

void _expectSignatures(ImportedPhieuNhapKho result) {
  expect(result.chuKy.nguoiLapPhieu, 'Nguyễn Văn A');
  expect(result.chuKy.nguoiGiaoHang, 'Trần Thị B');
  expect(result.chuKy.thuKho, 'Lê Văn C');
  expect(result.chuKy.keToanTruong, 'Phạm Thị D');
}

void main() {
  test('OCR dạng dòng ngang (layout): đủ các trường', () {
    // Thêm ký tự zero-width giữa 'A' và 'B' để test bước strip.
    final raw = layoutFixture.replaceAll(
      'A                      B',
      'A${String.fromCharCode(0x200B)}                      B',
    );

    final normalized = PhieuNhapKhoOcrNormalizer.normalize(raw);
    final result = PhieuNhapKhoFileParser.parseText(normalized);

    _expectCommonFields(result);
    _expectProducts(result.products);
    _expectSignatures(result);
  });

  test('OCR tách nhãn và giá trị ra 2 dòng', () {
    const raw = '''
Đơn vị:
Công ty A
Bộ phận: Kho Vật Tư Trung Tâm
Số:
NK-2026/08-01
Nợ: 152 Có: 331
- Họ và tên người giao:
Ông B
- Theo Hóa đơn GTGT số 0001245 ngày 12 tháng 08 năm 2026 của Công ty C
Số chứng từ gốc kèm theo:
01 Hóa đơn GTGT gốc + 01 Biên bản giao nhận
''';

    final result = PhieuNhapKhoFileParser.parseText(
      PhieuNhapKhoOcrNormalizer.normalize(raw),
    );

    expect(result.soPhieu, 'NK-2026/08-01');
    expect(result.donVi, 'Công ty A');
    expect(result.no, '152');
    expect(result.co, '331');
    expect(result.nguoiGiao, 'Ông B');
    expect(
      result.soChungTuGoc,
      '01 Hóa đơn GTGT gốc + 01 Biên bản giao nhận',
    );
  });

  test('OCR đọc chung Nợ/Có trên 1 dòng', () {
    final result = PhieuNhapKhoFileParser.parseText(
      PhieuNhapKhoOcrNormalizer.normalize('Nợ: 152 Có: 331'),
    );
    expect(result.no, '152');
    expect(result.co, '331');
  });

  test('Không khớp nhầm Theo chứng từ / Ban hành theo', () {
    final result = PhieuNhapKhoFileParser.parseText(
      PhieuNhapKhoOcrNormalizer.normalize(layoutFixture),
    );
    expect(
      result.theo,
      'Hóa đơn GTGT số 0001245 ngày 12 tháng 08 năm 2026 của Công ty C',
    );
  });

  group('File thực tế', () {
    final pdfFile = File('../Mẫu Phiếu Nhập Kho - VIMES.pdf');
    final docxFile = File('../Mẫu Phiếu Nhập Kho - VIMES.docx');

    test(
      'PDF',
      () async {
        final result = await PhieuNhapKhoFileParser.parse(pdfFile);
        _expectCommonFields(result);
        _expectProducts(result.products);
        _expectSignatures(result);
      },
      skip: !pdfFile.existsSync(),
    );

    test(
      'DOCX (2 trang, trang 2 là bản sao không ký)',
      () async {
        final result = await PhieuNhapKhoFileParser.parse(docxFile);
        _expectCommonFields(result);
        _expectProducts(result.products);
        _expectSignatures(result);
      },
      skip: !docxFile.existsSync(),
    );
  });
}
