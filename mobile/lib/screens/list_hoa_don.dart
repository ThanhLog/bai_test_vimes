import 'package:flutter/material.dart';
import 'package:mobile/data/mock_data.dart';
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
  final List<ThongTinPhieu> thongTinPhieuList = [...mockThongTinPhieuList];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final newInvoice = await Navigator.push<ThongTinPhieu>(
                context,
                MaterialPageRoute(builder: (context) => const ThemHoaDon()),
              );

              if (newInvoice != null) {
                setState(() {
                  thongTinPhieuList.insert(0, newInvoice);
                });
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: thongTinPhieuList.length,
        itemBuilder: (context, index) {
          return _itemBuilder(
            context,
            thongTinPhieuList[index],
            onEdit: _editInvoice,
          );
        },
      ),
    );
  }

  Future<void> _editInvoice(ThongTinPhieu phieu) async {
    final updated = await Navigator.push<ThongTinPhieu>(
      context,
      MaterialPageRoute(builder: (context) => SuaHoaDon(phieu: phieu)),
    );

    if (!mounted || updated == null) {
      return;
    }

    final index = thongTinPhieuList.indexOf(phieu);
    if (index != -1) {
      setState(() {
        thongTinPhieuList[index] = updated;
      });
    }
  }
}

Widget _itemBuilder(
  BuildContext context,
  ThongTinPhieu phieu, {
  required Future<void> Function(ThongTinPhieu) onEdit,
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
                          height: 260,
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
  double height = 220,
}) {
  return Center(
    child: Container(
      // height: height,
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
                    // Xử lý khi nhấn nút xóa
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
