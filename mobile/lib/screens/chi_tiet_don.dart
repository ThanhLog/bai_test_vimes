import 'package:flutter/material.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/thongTinPhieu.dart';
import 'package:mobile/utils/utils.dart';

class ChiTietDon extends StatelessWidget {
  const ChiTietDon({super.key, required this.phieu});

  final ThongTinPhieu phieu;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết đơn ${phieu.soPhieu}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(context, 'Thông tin phiếu'),
          _infoRow(context, 'Số phiếu', phieu.soPhieu),
          _infoRow(context, 'Đơn vị', phieu.donVi),
          _infoRow(context, 'Bộ phận', phieu.boPhan),
          if (phieu.ngayNhapKho != null)
            _infoRow(context, 'Ngày nhập kho', formatDate(phieu.ngayNhapKho!)),
          _infoRow(context, 'Nợ', phieu.no),
          _infoRow(context, 'Có', phieu.co),
          _infoRow(context, 'Mã số', phieu.maSo),
          _infoRow(context, 'Người giao', phieu.nguoiGiao),
          _infoRow(context, 'Theo', phieu.theo),
          _infoRow(context, 'Tổng tiền', phieu.tongTien),
          _infoRow(context, 'Số chứng từ gốc', phieu.soChungTuGoc),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Danh sách sản phẩm'),
          if (phieu.products.isEmpty)
            const Text('Không có sản phẩm')
          else
            for (final product in phieu.products)
              _productCard(context, product),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Chữ ký'),
          _infoRow(context, 'Người lập phiếu', phieu.chuKy.nguoiLapPhieu),
          _infoRow(context, 'Người giao hàng', phieu.chuKy.nguoiGiaoHang),
          _infoRow(context, 'Thủ kho', phieu.chuKy.thuKho),
          _infoRow(context, 'Kế toán trưởng', phieu.chuKy.keToanTruong),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(BuildContext context, Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name.trim().isEmpty
                  ? 'Sản phẩm chưa đặt tên'
                  : product.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _productInfo(context, 'Mã số', product.maSo),
            _productInfo(context, 'Chứng từ', product.chungTu),
            _productInfo(context, 'Thực nhận', product.thucNhan),
            _productInfo(context, 'Đơn giá', product.donGia),
            _productInfo(context, 'Thành tiền', product.thanhTien),
          ],
        ),
      ),
    );
  }

  Widget _productInfo(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: ${value.trim().isEmpty ? '-' : value}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
