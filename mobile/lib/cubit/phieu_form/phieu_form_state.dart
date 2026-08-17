import 'package:mobile/cubit/phieu_form/product_form_entry.dart';
import 'package:mobile/models/thongTinPhieu.dart';



class PhieuFormState {
  const PhieuFormState({
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
    this.nguoiLapPhieu = '',
    this.nguoiGiaoHang = '',
    this.thuKho = '',
    this.keToanTruong = '',
    this.products = const <ProductFormEntry>[],
    this.isSaving = false,
    this.errorMessage,
    this.revision = 0,
  });

  factory PhieuFormState.initial(ThongTinPhieu? invoice) {
    if (invoice == null) {
      return const PhieuFormState(
        products: [ProductFormEntry(uid: 1)],
      );
    }

    return PhieuFormState(
      soPhieu: invoice.soPhieu,
      donVi: invoice.donVi,
      boPhan: invoice.boPhan,
      ngayNhapKho: invoice.ngayNhapKho,
      no: invoice.no,
      co: invoice.co,
      maSo: invoice.maSo,
      nguoiGiao: invoice.nguoiGiao,
      theo: invoice.theo,
      tongTien: invoice.tongTien,
      soChungTuGoc: invoice.soChungTuGoc,
      nguoiLapPhieu: invoice.chuKy.nguoiLapPhieu,
      nguoiGiaoHang: invoice.chuKy.nguoiGiaoHang,
      thuKho: invoice.chuKy.thuKho,
      keToanTruong: invoice.chuKy.keToanTruong,
      products: invoice.products.isEmpty
          ? const [ProductFormEntry(uid: 1)]
          : [
              for (var i = 0; i < invoice.products.length; i++)
                ProductFormEntry.fromProduct(invoice.products[i], uid: i + 1),
            ],
    );
  }

  static const _unset = Object();

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
  final String nguoiLapPhieu;
  final String nguoiGiaoHang;
  final String thuKho;
  final String keToanTruong;
  final List<ProductFormEntry> products;
  final bool isSaving;
  final String? errorMessage;

  final int revision;

  PhieuFormState copyWith({
    Object? soPhieu = _unset,
    Object? donVi = _unset,
    Object? boPhan = _unset,
    Object? ngayNhapKho = _unset,
    Object? no = _unset,
    Object? co = _unset,
    Object? maSo = _unset,
    Object? nguoiGiao = _unset,
    Object? theo = _unset,
    Object? tongTien = _unset,
    Object? soChungTuGoc = _unset,
    Object? nguoiLapPhieu = _unset,
    Object? nguoiGiaoHang = _unset,
    Object? thuKho = _unset,
    Object? keToanTruong = _unset,
    List<ProductFormEntry>? products,
    bool? isSaving,
    Object? errorMessage = _unset,
    int? revision,
  }) {
    return PhieuFormState(
      soPhieu: identical(soPhieu, _unset) ? this.soPhieu : soPhieu as String,
      donVi: identical(donVi, _unset) ? this.donVi : donVi as String,
      boPhan: identical(boPhan, _unset) ? this.boPhan : boPhan as String,
      ngayNhapKho: identical(ngayNhapKho, _unset)
          ? this.ngayNhapKho
          : ngayNhapKho as DateTime?,
      no: identical(no, _unset) ? this.no : no as String,
      co: identical(co, _unset) ? this.co : co as String,
      maSo: identical(maSo, _unset) ? this.maSo : maSo as String,
      nguoiGiao:
          identical(nguoiGiao, _unset) ? this.nguoiGiao : nguoiGiao as String,
      theo: identical(theo, _unset) ? this.theo : theo as String,
      tongTien:
          identical(tongTien, _unset) ? this.tongTien : tongTien as String,
      soChungTuGoc: identical(soChungTuGoc, _unset)
          ? this.soChungTuGoc
          : soChungTuGoc as String,
      nguoiLapPhieu: identical(nguoiLapPhieu, _unset)
          ? this.nguoiLapPhieu
          : nguoiLapPhieu as String,
      nguoiGiaoHang: identical(nguoiGiaoHang, _unset)
          ? this.nguoiGiaoHang
          : nguoiGiaoHang as String,
      thuKho: identical(thuKho, _unset) ? this.thuKho : thuKho as String,
      keToanTruong: identical(keToanTruong, _unset)
          ? this.keToanTruong
          : keToanTruong as String,
      products: products ?? this.products,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      revision: revision ?? this.revision,
    );
  }
}
