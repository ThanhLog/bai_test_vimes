import 'package:mobile/models/product.dart';


class ProductFormEntry {
  const ProductFormEntry({
    this.uid = 0,
    this.id = '',
    this.name = '',
    this.maSo = '',
    this.thucNhan = '',
    this.donGia = '',
    this.thanhTien = '',
  });

  factory ProductFormEntry.fromProduct(
    Product product, {
    required int uid,
  }) {
    return ProductFormEntry(
      uid: uid,
      id: product.id,
      name: product.name,
      maSo: product.maSo,
      thucNhan: product.thucNhan,
      donGia: product.donGia,
      thanhTien: product.thanhTien,
    );
  }

  final int uid;
  final String id;
  final String name;
  final String maSo;
  final String thucNhan;
  final String donGia;
  final String thanhTien;

  ProductFormEntry copyWith({
    String? id,
    String? name,
    String? maSo,
    String? thucNhan,
    String? donGia,
    String? thanhTien,
  }) {
    return ProductFormEntry(
      uid: uid,
      id: id ?? this.id,
      name: name ?? this.name,
      maSo: maSo ?? this.maSo,
      thucNhan: thucNhan ?? this.thucNhan,
      donGia: donGia ?? this.donGia,
      thanhTien: thanhTien ?? this.thanhTien,
    );
  }

  Product toProduct(String chungTu) {
    return Product(
      id: id.trim(),
      name: name.trim(),
      maSo: maSo.trim(),
      chungTu: chungTu,
      thucNhan: thucNhan.trim(),
      donGia: donGia.trim(),
      thanhTien: thanhTien.trim(),
    );
  }
}
