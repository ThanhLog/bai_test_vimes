import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/cubit/phieu_list/phieu_list_cubit.dart';
import 'package:mobile/cubit/phieu_list/phieu_list_state.dart';
import 'package:mobile/data/phieu_repository.dart';
import 'package:mobile/models/thongTinPhieu.dart';
import 'package:mobile/screens/chi_tiet_don.dart';
import 'package:mobile/screens/sua_hoa_don.dart';
import 'package:mobile/screens/them_hoa_don.dart';
import 'package:mobile/utils/utils.dart';

class ListHoaDon extends StatefulWidget {
  const ListHoaDon({super.key});

  @override
  State<ListHoaDon> createState() => _ListHoaDonState();
}

class _ListHoaDonState extends State<ListHoaDon> {
  late final PhieuListCubit _phieuListCubit;

  @override
  void initState() {
    super.initState();
    _phieuListCubit = PhieuListCubit(FirestorePhieuRepository());
  }

  @override
  void dispose() {
    _phieuListCubit.close();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addInvoice() async {
    final newInvoice = await Navigator.push<ThongTinPhieu>(
      context,
      MaterialPageRoute(builder: (context) => const ThemHoaDon()),
    );

    if (!mounted || newInvoice == null) return;
    _showSnackBar('Đã lưu phiếu ${newInvoice.soPhieu}.');
  }

  Future<void> _editInvoice(ThongTinPhieu phieu) async {
    final updated = await Navigator.push<ThongTinPhieu>(
      context,
      MaterialPageRoute(builder: (context) => SuaHoaDon(phieu: phieu)),
    );

    if (!mounted || updated == null) return;
    _showSnackBar('Đã cập nhật phiếu ${updated.soPhieu}.');
  }

  Future<void> _deleteInvoice(ThongTinPhieu phieu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa phiếu'),
        content: Text('Bạn có chắc muốn xóa phiếu ${phieu.soPhieu}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await _phieuListCubit.deletePhieu(phieu);
    if (!mounted) return;
    _showSnackBar(error ?? 'Đã xóa phiếu ${phieu.soPhieu}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addInvoice,
          ),
        ],
      ),
      body: BlocBuilder<PhieuListCubit, PhieuListState>(
        bloc: _phieuListCubit,
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final errorMessage = state.errorMessage;
          if (errorMessage != null && state.phieus.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _phieuListCubit.retry,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state.phieus.isEmpty) {
            return const Center(child: Text('Chưa có phiếu nào.'));
          }

          return ListView.builder(
            itemCount: state.phieus.length,
            itemBuilder: (context, index) {
              return _itemBuilder(
                context,
                state.phieus[index],
                onEdit: _editInvoice,
                onDelete: _deleteInvoice,
              );
            },
          );
        },
      ),
    );
  }
}

Widget _itemBuilder(
  BuildContext context,
  ThongTinPhieu phieu, {
  required Future<void> Function(ThongTinPhieu) onEdit,
  required Future<void> Function(ThongTinPhieu) onDelete,
}) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChiTietDon(phieu: phieu)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Số phiếu: ${phieu.soPhieu}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return _dialogBuilder(
                          context,
                          phieu,
                          onEdit: onEdit,
                          onDelete: onDelete,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Đơn vị: ${phieu.donVi}'),
            Text('Bộ phận: ${phieu.boPhan}'),
            if (phieu.ngayNhapKho != null)
              Text(
                'Ngày nhập kho: ${formatDate(phieu.ngayNhapKho!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (phieu.ngayNhapKho != null)
              Text('Người giao: ${phieu.nguoiGiao}'),
            Text('Tổng tiền: ${phieu.tongTien}'),
            Text('Số chứng từ gốc: ${phieu.soChungTuGoc}'),
          ],
        ),
      ),
    ),
  );
}

Widget _dialogBuilder(
  BuildContext context,
  ThongTinPhieu phieu, {
  required Future<void> Function(ThongTinPhieu) onEdit,
  required Future<void> Function(ThongTinPhieu) onDelete,
}) {
  return Center(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số phiếu: ${phieu.soPhieu}'),
            Text('Đơn vị: ${phieu.donVi}'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await onEdit(phieu);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDelete(phieu);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
