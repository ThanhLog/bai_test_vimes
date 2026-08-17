import 'chuKy.dart';
import 'product.dart';

class ThongTinPhieu {
  const ThongTinPhieu({
    this.id = '',
    this.soPhieu = '',
    this.donVi = '',
    this.boPhan = '',
    this.ngayNhapKho,
    this.no = '',
    this.co = '',
    this.maSo = '',
    this.nguoiGiao = '',
    this.theo = '',
    this.tongTien = '',
    this.soChungTuGoc = '',
    this.products = const <Product>[],
    this.chuKy = const ChuKy(),
  });

  final String id;
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

  factory ThongTinPhieu.fromJson(Map<String, dynamic> json) {
    return ThongTinPhieu(
      soPhieu: json['soPhieu'] as String? ?? '',
      donVi: json['donVi'] as String? ?? '',
      boPhan: json['boPhan'] as String? ?? '',
      ngayNhapKho: json['ngayNhapKho'] as DateTime?,
      no: json['no'] as String? ?? '',
      co: json['co'] as String? ?? '',
      maSo: json['maSo'] as String? ?? '',
      nguoiGiao: json['nguoiGiao'] as String? ?? '',
      theo: json['theo'] as String? ?? '',
      tongTien: json['tongTien'] as String? ?? '',
      soChungTuGoc: json['soChungTuGoc'] as String? ?? '',
      id: json['id'] as String? ?? '',
      products:
          (json['products'] as List<dynamic>?)
              ?.map((e) => Product.fromJson(e))
              .toList() ??
          const <Product>[],
      chuKy: ChuKy.fromJson(json['chuKy'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {

      'soPhieu': soPhieu,
      'donVi': donVi,
      'boPhan': boPhan,
      'ngayNhapKho': ngayNhapKho?.toIso8601String(),
      'no': no,
      'co': co,
      'maSo': maSo,
      'nguoiGiao': nguoiGiao,
      'theo': theo,
      'tongTien': tongTien,
      'soChungTuGoc': soChungTuGoc,
      'products': products.map((product) => product.toJson()).toList(),
      'chuKy': chuKy.toJson(),
      'id': id,
    };
  }

  ThongTinPhieu copyWith({
    String? soPhieu,
    String? donVi,
    String? boPhan,
    DateTime? ngayNhapKho,
    String? no,
    String? co,
    String? maSo,
    String? nguoiGiao,
    String? theo,
    String? tongTien,
    String? soChungTuGoc,
    List<Product>? products,
    ChuKy? chuKy,
    String? id,
  }) {
    return ThongTinPhieu(
      soPhieu: soPhieu ?? this.soPhieu,
      donVi: donVi ?? this.donVi,
      boPhan: boPhan ?? this.boPhan,
      ngayNhapKho: ngayNhapKho ?? this.ngayNhapKho,
      no: no ?? this.no,
      co: co ?? this.co,
      maSo: maSo ?? this.maSo,
      nguoiGiao: nguoiGiao ?? this.nguoiGiao,
      theo: theo ?? this.theo,
      tongTien: tongTien ?? this.tongTien,
      soChungTuGoc: soChungTuGoc ?? this.soChungTuGoc,
      products: products ?? this.products,
      chuKy: chuKy ?? this.chuKy,
      id: id ?? this.id
    );
  }
}
