import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/cubit/phieu_form/phieu_form_cubit.dart';
import 'package:mobile/cubit/phieu_list/phieu_list_cubit.dart';
import 'package:mobile/data/phieu_repository.dart';
import 'package:mobile/models/thongTinPhieu.dart';

/// Repository giả — không đụng Firestore, ghi nhớ các lần gọi để assert.
class FakePhieuRepository implements PhieuRepository {
  FakePhieuRepository({List<ThongTinPhieu> initial = const []})
      : _phieus = List.of(initial);

  final List<ThongTinPhieu> _phieus;
  final _controller = StreamController<List<ThongTinPhieu>>.broadcast();

  bool failSave = false;
  bool failDelete = false;
  int addCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  void emitList() => _controller.add(List.of(_phieus));

  @override
  Stream<List<ThongTinPhieu>> watchPhieuList() => _controller.stream;

  @override
  Future<String> addPhieu(ThongTinPhieu phieu) async {
    if (failSave) throw Exception('loi ghi');
    addCalls++;
    final id = 'doc-$addCalls';
    _phieus.add(phieu.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updatePhieu(ThongTinPhieu phieu) async {
    if (failSave) throw Exception('loi ghi');
    updateCalls++;
    final index = _phieus.indexWhere((p) => p.id == phieu.id);
    if (index != -1) _phieus[index] = phieu;
  }

  @override
  Future<void> deletePhieu(String id) async {
    if (failDelete) throw Exception('loi xoa');
    deleteCalls++;
    _phieus.removeWhere((p) => p.id == id);
    emitList();
  }
}

void main() {
  test('PhieuListCubit: loading -> loaded từ repository', () async {
    final repo = FakePhieuRepository(
      initial: [const ThongTinPhieu(id: '1', soPhieu: 'PN-001')],
    );
    final cubit = PhieuListCubit(repo);
    expect(cubit.state.isLoading, isTrue);

    repo.emitList();
    await pumpEventQueue();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.phieus, hasLength(1));
    expect(cubit.state.phieus.first.soPhieu, 'PN-001');
    await cubit.close();
  });

  test('PhieuListCubit: xóa thành công, list tự cập nhật qua stream', () async {
    final repo = FakePhieuRepository(
      initial: [const ThongTinPhieu(id: '1', soPhieu: 'PN-001')],
    );
    final cubit = PhieuListCubit(repo);
    repo.emitList();
    await pumpEventQueue();

    final error = await cubit.deletePhieu(cubit.state.phieus.first);

    expect(error, isNull);
    expect(repo.deleteCalls, 1);
    expect(cubit.state.phieus, isEmpty);
    await cubit.close();
  });

  test('PhieuListCubit: xóa lỗi trả về thông báo', () async {
    final repo = FakePhieuRepository()..failDelete = true;
    final cubit = PhieuListCubit(repo);
    repo.emitList();
    await pumpEventQueue();

    final error = await cubit.deletePhieu(const ThongTinPhieu(id: '1'));

    expect(error, isNotNull);
    expect(error, contains('Không thể xóa'));
    await cubit.close();
  });

  test('PhieuFormCubit: thêm mới trả về phiếu có id', () async {
    final repo = FakePhieuRepository();
    final cubit = PhieuFormCubit(repo);

    cubit.setSoPhieu('PN-001');
    final saved = await cubit.save();

    expect(saved, isNotNull);
    expect(saved!.id, isNotEmpty);
    expect(repo.addCalls, 1);
    expect(repo.updateCalls, 0);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.errorMessage, isNull);
    await cubit.close();
  });

  test('PhieuFormCubit: sửa giữ id và gọi update', () async {
    final repo = FakePhieuRepository();
    final cubit = PhieuFormCubit(
      repo,
      initialInvoice: const ThongTinPhieu(id: 'doc-1', soPhieu: 'PN-001'),
    );

    final saved = await cubit.save();

    expect(saved!.id, 'doc-1');
    expect(repo.updateCalls, 1);
    expect(repo.addCalls, 0);
    await cubit.close();
  });

  test('PhieuFormCubit: lỗi lưu trả null + errorMessage', () async {
    final repo = FakePhieuRepository()..failSave = true;
    final cubit = PhieuFormCubit(repo);

    cubit.setSoPhieu('PN-001');
    final saved = await cubit.save();

    expect(saved, isNull);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.errorMessage, isNotNull);
    await cubit.close();
  });

  test('PhieuFormCubit: tính thành tiền và tổng tiền từ sản phẩm', () async {
    final repo = FakePhieuRepository();
    final cubit = PhieuFormCubit(repo);

    cubit.setProductThucNhan(0, '2');
    cubit.setProductDonGia(0, '3.000');

    expect(cubit.state.products.first.thanhTien, '6.000');
    expect(cubit.state.tongTien, '6.000');

    cubit.addProduct();
    cubit.setProductThucNhan(1, '1,5');
    cubit.setProductDonGia(1, '100');

    expect(cubit.state.products[1].thanhTien, '150');
    expect(cubit.state.tongTien, '6.150');
    await cubit.close();
  });
}
