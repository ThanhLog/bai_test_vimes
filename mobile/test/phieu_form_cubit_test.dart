import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/cubit/phieu_form/phieu_form_cubit.dart';
import 'package:mobile/data/phieu_repository.dart';
import 'package:mobile/models/thongTinPhieu.dart';

class FakePhieuRepository implements PhieuRepository {
  final List<ThongTinPhieu> saved = [];

  int addCount = 0;
  int updateCount = 0;
  int deleteCount = 0;

  @override
  Future<String> addPhieu(ThongTinPhieu phieu) async {
    addCount++;

    const id = 'test-id';

    saved.add(
      phieu.copyWith(id: id),
    );

    return id;
  }

  @override
  Future<void> updatePhieu(ThongTinPhieu phieu) async {
    updateCount++;

    final index = saved.indexWhere(
      (item) => item.id == phieu.id,
    );

    if (index >= 0) {
      saved[index] = phieu;
    }
  }

  @override
  Future<void> deletePhieu(String id) async {
    deleteCount++;

    saved.removeWhere(
      (item) => item.id == id,
    );
  }

  @override
  Stream<List<ThongTinPhieu>> watchPhieuList() {
    return Stream.value(saved);
  }
}

void main() {
  late FakePhieuRepository repository;
  late PhieuFormCubit cubit;

  setUp(() {
    repository = FakePhieuRepository();
    cubit = PhieuFormCubit(repository);
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state should be empty', () {
    expect(cubit.state.soPhieu, '');
    expect(cubit.state.donVi, '');
    expect(cubit.state.products.length, 1);
    expect(cubit.state.tongTien, '');
  });

  test('should update invoice information', () {
    cubit.setSoPhieu(' PN001 ');
    cubit.setDonVi(' VIMES ');

    expect(cubit.state.soPhieu, ' PN001 ');
    expect(cubit.state.donVi, ' VIMES ');
  });

  test('should add product', () {
    final initialLength = cubit.state.products.length;

    cubit.addProduct();

    expect(
      cubit.state.products.length,
      initialLength + 1,
    );
  });

  test('should remove product', () {
    cubit.addProduct();

    final lengthBeforeRemove = cubit.state.products.length;

    cubit.removeProduct(0);

    expect(
      cubit.state.products.length,
      lengthBeforeRemove - 1,
    );
  });

  test('should calculate product amount', () {
    cubit.setProductThucNhan(0, '10');
    cubit.setProductDonGia(0, '50.000');

    expect(
      cubit.state.products[0].thanhTien,
      '500.000',
    );
  });

  test('should calculate total amount', () {
    cubit.setProductThucNhan(0, '10');
    cubit.setProductDonGia(0, '50.000');

    cubit.addProduct();

    cubit.setProductThucNhan(1, '5');
    cubit.setProductDonGia(1, '20.000');

    expect(
      cubit.state.tongTien,
      '600.000',
    );
  });

  test('should save a new invoice', () async {
    cubit.setSoPhieu(' PN001 ');
    cubit.setDonVi(' VIMES ');

    cubit.setProductName(
      0,
      ' Sản phẩm A ',
    );

    cubit.setProductThucNhan(
      0,
      '10',
    );

    cubit.setProductDonGia(
      0,
      '50.000',
    );

    final result = await cubit.save();

    expect(result, isNotNull);
    expect(result!.id, 'test-id');

    expect(repository.addCount, 1);
    expect(repository.saved.length, 1);

    expect(
      repository.saved.first.soPhieu,
      'PN001',
    );

    expect(
      repository.saved.first.donVi,
      'VIMES',
    );

    expect(
      repository.saved.first.products.first.name,
      'Sản phẩm A',
    );
  });

  test('should update existing invoice', () async {
    final initial = ThongTinPhieu(
      id: 'existing-id',
      soPhieu: 'PN001',
      donVi: 'VIMES',
    );

    repository.saved.add(initial);

    final editCubit = PhieuFormCubit(
      repository,
      initialInvoice: initial,
    );

    editCubit.setSoPhieu('PN002');

    final result = await editCubit.save();

    expect(result, isNotNull);
    expect(repository.updateCount, 1);
    expect(repository.addCount, 0);

    expect(
      repository.saved.first.soPhieu,
      'PN002',
    );

    await editCubit.close();
  });
}