import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/cubit/phieu_form/phieu_form_cubit.dart';
import 'package:mobile/cubit/phieu_form/phieu_form_state.dart';
import 'package:mobile/data/phieu_repository.dart';
import 'package:mobile/models/thongTinPhieu.dart';
import 'package:mobile/utils/utils.dart';

class ThemHoaDon extends StatefulWidget {
  const ThemHoaDon({super.key, this.initialInvoice});

  final ThongTinPhieu? initialInvoice;

  @override
  State<ThemHoaDon> createState() => _ThemHoaDonState();
}

class _ThemHoaDonState extends State<ThemHoaDon> {
  final _formKey = GlobalKey<FormState>();

  late final PhieuFormCubit _formCubit;

  bool get _isEditing => widget.initialInvoice != null;

  @override
  void initState() {
    super.initState();
    _formCubit = PhieuFormCubit(
      FirestorePhieuRepository(),
      initialInvoice: widget.initialInvoice,
    );
  }

  @override
  void dispose() {
    _formCubit.close();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickNgayNhapKho() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _formCubit.state.ngayNhapKho ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _formCubit.setNgayNhapKho(picked);
    }
  }

  Future<void> _selectAndUploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final path = result.files.single.path;
      if (path == null) {
        throw const FormatException('Không thể đọc đường dẫn file đã chọn.');
      }

      final file = File(path);
      final fileName = result.files.single.name.toLowerCase();

      if (fileName.endsWith('.pdf') || fileName.endsWith('.docx')) {
        final imported = await _formCubit.importFile(file);
        if (!mounted) return;
        _showSnackBar(
          imported.products.isEmpty
              ? 'Đã tự điền thông tin chung. Hãy kiểm tra lại sản phẩm.'
              : 'Đã tự điền thông tin và ${imported.products.length} sản phẩm.',
        );
      } else {
        _showSnackBar('File type not supported');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi: $e');
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final saved = await _formCubit.save();
    if (!mounted) return;

    if (saved == null) {
      _showSnackBar(_formCubit.state.errorMessage ?? 'Không thể lưu phiếu.');
      return;
    }

    Navigator.of(context).pop(saved);
  }

  TextInputFormatter _numberInputFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final text = formatNumberVnInput(newValue.text);
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa hóa đơn' : 'Thêm hóa đơn'),
        actions: [
          IconButton(
            onPressed: _selectAndUploadFiles,
            icon: const Icon(Icons.file_upload),
          ),
        ],
      ),
      body: BlocBuilder<PhieuFormCubit, PhieuFormState>(
        bloc: _formCubit,
        builder: (context, state) {
          return Form(
            key: ValueKey('form-${state.revision}'),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle('Thông tin chung'),
                  TextFormField(
                    initialValue: state.soPhieu,
                    onChanged: _formCubit.setSoPhieu,
                    decoration: const InputDecoration(labelText: 'Số phiếu *'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập số phiếu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.donVi,
                    onChanged: _formCubit.setDonVi,
                    decoration: const InputDecoration(labelText: 'Đơn vị *'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập đơn vị';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.boPhan,
                    onChanged: _formCubit.setBoPhan,
                    decoration: const InputDecoration(labelText: 'Bộ phận'),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickNgayNhapKho,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày nhập kho',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        state.ngayNhapKho == null
                            ? 'Chọn ngày'
                            : formatDate(state.ngayNhapKho!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: state.no,
                          onChanged: _formCubit.setNo,
                          decoration: const InputDecoration(labelText: 'Nợ'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: state.co,
                          onChanged: _formCubit.setCo,
                          decoration: const InputDecoration(labelText: 'Có'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.maSo,
                    onChanged: _formCubit.setMaSo,
                    decoration: const InputDecoration(labelText: 'Mã số'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.nguoiGiao,
                    onChanged: _formCubit.setNguoiGiao,
                    decoration: const InputDecoration(labelText: 'Người giao'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.theo,
                    onChanged: _formCubit.setTheo,
                    decoration: const InputDecoration(labelText: 'Theo'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: ValueKey('tongTien-${state.tongTien}'),
                    initialValue: state.tongTien,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Tổng tiền',
                      helperText: 'Tự động tính từ sản phẩm',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.soChungTuGoc,
                    onChanged: _formCubit.setSoChungTuGoc,
                    decoration: const InputDecoration(
                      labelText: 'Số chứng từ gốc',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Sản phẩm'),
                  for (var index = 0; index < state.products.length; index++)
                    _buildProductCard(context, state, index),
                  TextButton.icon(
                    onPressed: _formCubit.addProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm sản phẩm'),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Chữ ký'),
                  TextFormField(
                    initialValue: state.nguoiLapPhieu,
                    onChanged: _formCubit.setNguoiLapPhieu,
                    decoration: const InputDecoration(
                      labelText: 'Người lập phiếu',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.nguoiGiaoHang,
                    onChanged: _formCubit.setNguoiGiaoHang,
                    decoration: const InputDecoration(
                      labelText: 'Người giao hàng',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.thuKho,
                    onChanged: _formCubit.setThuKho,
                    decoration: const InputDecoration(labelText: 'Thủ kho'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.keToanTruong,
                    onChanged: _formCubit.setKeToanTruong,
                    decoration: const InputDecoration(
                      labelText: 'Kế toán trưởng',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: state.isSaving ? null : _save,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: state.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isEditing ? 'Cập nhật hóa đơn' : 'Lưu hóa đơn',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
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

  Widget _buildProductCard(
    BuildContext context,
    PhieuFormState state,
    int index,
  ) {
    final product = state.products[index];
    final uid = product.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sản phẩm ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (state.products.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _formCubit.removeProduct(index),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('$uid-name'),
              initialValue: product.name,
              onChanged: (value) => _formCubit.setProductName(index, value),
              decoration: const InputDecoration(labelText: 'Tên sản phẩm *'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên sản phẩm';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('$uid-maSo'),
              initialValue: product.maSo,
              onChanged: (value) => _formCubit.setProductMaSo(index, value),
              decoration: const InputDecoration(labelText: 'Mã số'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('$uid-thucNhan'),
                    initialValue: product.thucNhan,
                    onChanged: (value) =>
                        _formCubit.setProductThucNhan(index, value),
                    inputFormatters: [_numberInputFormatter()],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Thực nhận'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('$uid-donGia'),
                    initialValue: product.donGia,
                    onChanged: (value) =>
                        _formCubit.setProductDonGia(index, value),
                    inputFormatters: [_numberInputFormatter()],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Đơn giá'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('$uid-thanhTien-${product.thanhTien}'),
              initialValue: product.thanhTien,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Thành tiền'),
            ),
          ],
        ),
      ),
    );
  }
}
