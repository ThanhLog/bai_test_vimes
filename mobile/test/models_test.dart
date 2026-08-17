import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/chuKy.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/thongTinPhieu.dart';

void main() {
  group('Product', () {
    test('toJson and fromJson should preserve data', () {
      const product = Product(
        id: '1',
        name: 'Sản phẩm A',
        maSo: 'SP001',
        chungTu: 'PN001',
        thucNhan: '10',
        donGia: '50.000',
        thanhTien: '500.000',
      );

      final json = product.toJson();
      final restored = Product.fromJson(json);

      expect(restored.id, '1');
      expect(restored.name, 'Sản phẩm A');
      expect(restored.maSo, 'SP001');
      expect(restored.chungTu, 'PN001');
      expect(restored.thucNhan, '10');
      expect(restored.donGia, '50.000');
      expect(restored.thanhTien, '500.000');
    });

    test('copyWith should only change requested fields', () {
      const product = Product(
        id: '1',
        name: 'Sản phẩm A',
        maSo: 'SP001',
      );

      final copied = product.copyWith(
        name: 'Sản phẩm B',
      );

      expect(copied.id, '1');
      expect(copied.name, 'Sản phẩm B');
      expect(copied.maSo, 'SP001');

      expect(product.name, 'Sản phẩm A');
    });
  });

  group('ChuKy', () {
    test('toJson and fromJson should preserve data', () {
      const chuKy = ChuKy(
        nguoiLapPhieu: 'Nguyễn Văn A',
        nguoiGiaoHang: 'Nguyễn Văn B',
        thuKho: 'Nguyễn Văn C',
        keToanTruong: 'Nguyễn Văn D',
      );

      final restored = ChuKy.fromJson(chuKy.toJson());

      expect(restored.nguoiLapPhieu, 'Nguyễn Văn A');
      expect(restored.nguoiGiaoHang, 'Nguyễn Văn B');
      expect(restored.thuKho, 'Nguyễn Văn C');
      expect(restored.keToanTruong, 'Nguyễn Văn D');
    });
  });

  group('ThongTinPhieu', () {
    test('should serialize nested products and chuKy', () {
      final phieu = ThongTinPhieu(
        id: 'phieu-1',
        soPhieu: 'PN001',
        donVi: 'VIMES',
        boPhan: 'Kho',
        ngayNhapKho: DateTime(2026, 8, 17),
        tongTien: '500.000',
        products: const [
          Product(
            id: 'sp-1',
            name: 'Sản phẩm A',
            maSo: 'SP001',
            thucNhan: '10',
            donGia: '50.000',
            thanhTien: '500.000',
          ),
        ],
        chuKy: ChuKy(
          nguoiLapPhieu: 'Nguyễn Văn A',
        ),
      );

      final restored = ThongTinPhieu.fromJson(phieu.toJson());

      expect(restored.id, 'phieu-1');
      expect(restored.soPhieu, 'PN001');
      expect(restored.products.length, 1);
      expect(restored.products.first.name, 'Sản phẩm A');
      expect(restored.chuKy.nguoiLapPhieu, 'Nguyễn Văn A');
    });
  });
}