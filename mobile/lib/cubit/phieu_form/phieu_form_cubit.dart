import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/cubit/phieu_form/phieu_form_state.dart';
import 'package:mobile/cubit/phieu_form/product_form_entry.dart';
import 'package:mobile/data/phieu_repository.dart';
import 'package:mobile/models/chuKy.dart';
import 'package:mobile/models/thongTinPhieu.dart';
import 'package:mobile/utils/phieu_nhap_kho_file_parser.dart';
import 'package:mobile/utils/utils.dart';


class PhieuFormCubit extends Cubit<PhieuFormState> {
  PhieuFormCubit(
    this._repository, {
    ThongTinPhieu? initialInvoice,
  })  : _initialId = initialInvoice?.id ?? '',
        super(PhieuFormState.initial(initialInvoice)) {
    _nextUid = state.products.fold(0, (max, p) => p.uid > max ? p.uid : max) + 1;
  }

  final PhieuRepository _repository;
  final String _initialId;
  int _nextUid = 1;


  void setSoPhieu(String value) => _emit(state.copyWith(soPhieu: value));
  void setDonVi(String value) => _emit(state.copyWith(donVi: value));
  void setBoPhan(String value) => _emit(state.copyWith(boPhan: value));
  void setNgayNhapKho(DateTime? value) =>
      _emit(state.copyWith(ngayNhapKho: value));
  void setNo(String value) => _emit(state.copyWith(no: value));
  void setCo(String value) => _emit(state.copyWith(co: value));
  void setMaSo(String value) => _emit(state.copyWith(maSo: value));
  void setNguoiGiao(String value) => _emit(state.copyWith(nguoiGiao: value));
  void setTheo(String value) => _emit(state.copyWith(theo: value));
  void setSoChungTuGoc(String value) =>
      _emit(state.copyWith(soChungTuGoc: value));


  void setNguoiLapPhieu(String value) =>
      _emit(state.copyWith(nguoiLapPhieu: value));
  void setNguoiGiaoHang(String value) =>
      _emit(state.copyWith(nguoiGiaoHang: value));
  void setThuKho(String value) => _emit(state.copyWith(thuKho: value));
  void setKeToanTruong(String value) =>
      _emit(state.copyWith(keToanTruong: value));

  void addProduct() {
    final products = [
      ...state.products,
      ProductFormEntry(uid: _nextUid++),
    ];
    _emit(
      state.copyWith(
        products: products,
        tongTien: _computeTongTien(products),
      ),
    );
  }

  void removeProduct(int index) {
    if (index < 0 || index >= state.products.length) return;
    final products = List.of(state.products)..removeAt(index);
    _emit(
      state.copyWith(
        products: products,
        tongTien: _computeTongTien(products),
      ),
    );
  }

  void setProductName(int index, String value) =>
      _updateProduct(index, (p) => p.copyWith(name: value));

  void setProductMaSo(int index, String value) =>
      _updateProduct(index, (p) => p.copyWith(maSo: value));

  void setProductThucNhan(int index, String value) =>
      _updateProduct(index, (p) => _withThanhTien(p.copyWith(thucNhan: value)));

  void setProductDonGia(int index, String value) =>
      _updateProduct(index, (p) => _withThanhTien(p.copyWith(donGia: value)));

  void _updateProduct(
    int index,
    ProductFormEntry Function(ProductFormEntry) update,
  ) {
    if (index < 0 || index >= state.products.length) return;
    final products = List.of(state.products);
    products[index] = update(products[index]);
    _emit(
      state.copyWith(
        products: products,
        tongTien: _computeTongTien(products),
      ),
    );
  }

  static ProductFormEntry _withThanhTien(ProductFormEntry entry) {
    final soLuong = parseNumberVn(entry.thucNhan);
    final donGia = parseNumberVn(entry.donGia);

    final thanhTien = (soLuong == null || donGia == null)
        ? ''
        : formatNumberVn(soLuong * donGia);

    return entry.copyWith(thanhTien: thanhTien);
  }

  static String _computeTongTien(List<ProductFormEntry> products) {
    final amounts = products
        .map((p) => parseNumberVn(p.thanhTien))
        .whereType<double>()
        .toList();
    if (amounts.isEmpty) return '';
    return formatNumberVn(amounts.fold(0.0, (sum, a) => sum + a));
  }

  Future<ImportedPhieuNhapKho> importFile(File file) async {
    final imported = await PhieuNhapKhoFileParser.parse(file);
    _applyImported(imported);
    return imported;
  }

  void _applyImported(ImportedPhieuNhapKho imported) {
    final products = imported.products.isEmpty
        ? state.products
        : [
            for (final product in imported.products)
              _withThanhTien(
                ProductFormEntry.fromProduct(product, uid: _nextUid++),
              ),
          ];

    _emit(
      PhieuFormState(
        soPhieu: imported.soPhieu,
        donVi: imported.donVi,
        boPhan: imported.boPhan,
        ngayNhapKho: imported.ngayNhapKho,
        no: imported.no,
        co: imported.co,
        maSo: imported.maSo,
        nguoiGiao: imported.nguoiGiao,
        theo: imported.theo,
        tongTien: _computeTongTien(products),
        soChungTuGoc: imported.soChungTuGoc,
        nguoiLapPhieu: imported.chuKy.nguoiLapPhieu,
        nguoiGiaoHang: imported.chuKy.nguoiGiaoHang,
        thuKho: imported.chuKy.thuKho,
        keToanTruong: imported.chuKy.keToanTruong,
        products: products,
        isSaving: state.isSaving,
        revision: state.revision + 1,
      ),
    );
  }

  Future<ThongTinPhieu?> save() async {
    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      final phieu = _buildPhieu();

      late ThongTinPhieu saved;
      if (phieu.id.isEmpty) {
        final id = await _repository.addPhieu(phieu);
        saved = phieu.copyWith(id: id);
      } else {
        await _repository.updatePhieu(phieu);
        saved = phieu;
      }

      _emit(state.copyWith(isSaving: false));
      return saved;
    } catch (e) {
      _emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Không thể lưu phiếu: $e',
        ),
      );
      return null;
    }
  }

  ThongTinPhieu _buildPhieu() {
    return ThongTinPhieu(
      id: _initialId,
      soPhieu: state.soPhieu.trim(),
      donVi: state.donVi.trim(),
      boPhan: state.boPhan.trim(),
      ngayNhapKho: state.ngayNhapKho,
      no: state.no.trim(),
      co: state.co.trim(),
      maSo: state.maSo.trim(),
      nguoiGiao: state.nguoiGiao.trim(),
      theo: state.theo.trim(),
      tongTien: state.tongTien.trim(),
      soChungTuGoc: state.soChungTuGoc.trim(),
      products: state.products
          .map((p) => p.toProduct(state.soPhieu.trim()))
          .toList(),
      chuKy: ChuKy(
        nguoiLapPhieu: state.nguoiLapPhieu.trim(),
        nguoiGiaoHang: state.nguoiGiaoHang.trim(),
        thuKho: state.thuKho.trim(),
        keToanTruong: state.keToanTruong.trim(),
      ),
    );
  }

  void _emit(PhieuFormState next) {
    if (!isClosed) {
      emit(next);
    }
  }
}
