import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:mobile/models/chuKy.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/thongTinPhieu.dart';
import 'package:mobile/screens/scan_hoa_don.dart';
import 'package:mobile/utils/phieu_nhap_kho_file_parser.dart';
import 'package:mobile/utils/utils.dart';

class ThemHoaDon extends StatefulWidget {
  const ThemHoaDon({super.key, this.initialInvoice});

  final ThongTinPhieu? initialInvoice;

  @override
  State<ThemHoaDon> createState() => _ThemHoaDonState();
}

class _ThemHoaDonState extends State<ThemHoaDon> {
  final _formKey = GlobalKey<FormState>();

  final _soPhieuController = TextEditingController();
  final _donViController = TextEditingController();
  final _boPhanController = TextEditingController();
  final _noController = TextEditingController();
  final _coController = TextEditingController();
  final _maSoController = TextEditingController();
  final _nguoiGiaoController = TextEditingController();
  final _theoController = TextEditingController();
  final _tongTienController = TextEditingController();
  final _soChungTuGocController = TextEditingController();

  final _nguoiLapPhieuController = TextEditingController();
  final _nguoiGiaoHangController = TextEditingController();
  final _thuKhoController = TextEditingController();
  final _keToanTruongController = TextEditingController();

  DateTime? _ngayNhapKho;
  final List<_ProductFormData> _products = [];

  bool get _isEditing => widget.initialInvoice != null;

  @override
  void initState() {
    super.initState();

    final invoice = widget.initialInvoice;
    if (invoice == null) {
      _products.add(_ProductFormData(onChanged: _updateTongTien));
      return;
    }

    _soPhieuController.text = invoice.soPhieu;
    _donViController.text = invoice.donVi;
    _boPhanController.text = invoice.boPhan;
    _noController.text = invoice.no;
    _coController.text = invoice.co;
    _maSoController.text = invoice.maSo;
    _nguoiGiaoController.text = invoice.nguoiGiao;
    _theoController.text = invoice.theo;
    _tongTienController.text = invoice.tongTien;
    _soChungTuGocController.text = invoice.soChungTuGoc;
    _ngayNhapKho = invoice.ngayNhapKho;

    _nguoiLapPhieuController.text = invoice.chuKy.nguoiLapPhieu;
    _nguoiGiaoHangController.text = invoice.chuKy.nguoiGiaoHang;
    _thuKhoController.text = invoice.chuKy.thuKho;
    _keToanTruongController.text = invoice.chuKy.keToanTruong;

    for (final product in invoice.products) {
      final formData = _ProductFormData(onChanged: _updateTongTien);
      formData.idController.text = product.id;
      formData.nameController.text = product.name;
      formData.maSoController.text = product.maSo;
      formData.thucNhanController.text = product.thucNhan;
      formData.donGiaController.text = product.donGia;
      formData.thanhTienController.text = product.thanhTien;
      _products.add(formData);
    }

    if (_products.isEmpty) {
      _products.add(_ProductFormData(onChanged: _updateTongTien));
    }
  }

  @override
  void dispose() {
    _soPhieuController.dispose();
    _donViController.dispose();
    _boPhanController.dispose();
    _noController.dispose();
    _coController.dispose();
    _maSoController.dispose();
    _nguoiGiaoController.dispose();
    _theoController.dispose();
    _tongTienController.dispose();
    _soChungTuGocController.dispose();

    _nguoiLapPhieuController.dispose();
    _nguoiGiaoHangController.dispose();
    _thuKhoController.dispose();
    _keToanTruongController.dispose();

    for (final product in _products) {
      product.dispose();
    }

    super.dispose();
  }

  Future<void> _pickNgayNhapKho() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _ngayNhapKho ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _ngayNhapKho = picked;
      });
    }
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
        final imported = await PhieuNhapKhoFileParser.parse(file);
        if (!mounted) return;
        _applyImportedData(imported);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File type not supported')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  // Future<void> _parsePdfFile(File file) async {
  //   try {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text(
  //             'Đã tải file. Vui lòng nhập dữ liệu thủ công hoặc sử dụng scan.',
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Lỗi đọc PDF: $e')));
  //     }
  //   }
  // }

  // void _parseDocFile(File file) {
  //   try {
  //     // DOCX parsing được hỗ trợ tốt hơn thông qua external service
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text(
  //             'Đã tải file DOCX. Vui lòng nhập dữ liệu thủ công hoặc sử dụng scan.',
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Lỗi đọc DOC: $e')));
  //     }
  //   }
  // }

  void _applyImportedData(ImportedPhieuNhapKho imported) {
    setState(() {
      _soPhieuController.text = imported.soPhieu;
      _donViController.text = imported.donVi;
      _boPhanController.text = imported.boPhan;
      _ngayNhapKho = imported.ngayNhapKho;
      _noController.text = imported.no;
      _coController.text = imported.co;
      _maSoController.text = imported.maSo;
      _nguoiGiaoController.text = imported.nguoiGiao;
      _theoController.text = imported.theo;
      _tongTienController.clear();
      _soChungTuGocController.text = imported.soChungTuGoc;
      _nguoiLapPhieuController.text = imported.chuKy.nguoiLapPhieu;
      _nguoiGiaoHangController.text = imported.chuKy.nguoiGiaoHang;
      _thuKhoController.text = imported.chuKy.thuKho;
      _keToanTruongController.text = imported.chuKy.keToanTruong;

      if (imported.products.isNotEmpty) {
        for (final product in _products) {
          product.dispose();
        }
        _products
          ..clear()
          ..addAll(
            imported.products.map((product) {
              final data = _ProductFormData(onChanged: _updateTongTien);
              data.idController.text = product.id;
              data.nameController.text = product.name;
              data.maSoController.text = product.maSo;
              data.thucNhanController.text = product.thucNhan;
              data.donGiaController.text = product.donGia;
              return data;
            }),
          );
      }
    });
    _updateTongTien();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          imported.products.isEmpty
              ? 'Đã tự điền thông tin chung. Hãy kiểm tra lại sản phẩm.'
              : 'Đã tự điền thông tin và ${imported.products.length} sản phẩm.',
        ),
      ),
    );
  }

  void _addProduct() {
    setState(() {
      _products.add(_ProductFormData(onChanged: _updateTongTien));
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _products[index].dispose();
      _products.removeAt(index);
    });
    _updateTongTien();
  }

  void _updateTongTien() {
    final amounts = _products
        .map((product) => product.amount)
        .whereType<double>()
        .toList();
    _tongTienController.text = amounts.isEmpty
        ? ''
        : formatNumberVn(amounts.fold(0, (sum, amount) => sum + amount));
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final phieu = ThongTinPhieu(
      soPhieu: _soPhieuController.text.trim(),
      donVi: _donViController.text.trim(),
      boPhan: _boPhanController.text.trim(),
      ngayNhapKho: _ngayNhapKho,
      no: _noController.text.trim(),
      co: _coController.text.trim(),
      maSo: _maSoController.text.trim(),
      nguoiGiao: _nguoiGiaoController.text.trim(),
      theo: _theoController.text.trim(),
      tongTien: _tongTienController.text.trim(),
      soChungTuGoc: _soChungTuGocController.text.trim(),
      products: _products
          .map((product) => product.toProduct(_soPhieuController.text.trim()))
          .toList(),
      chuKy: ChuKy(
        nguoiLapPhieu: _nguoiLapPhieuController.text.trim(),
        nguoiGiaoHang: _nguoiGiaoHangController.text.trim(),
        thuKho: _thuKhoController.text.trim(),
        keToanTruong: _keToanTruongController.text.trim(),
      ),
    );

    Navigator.of(context).pop(phieu);
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

          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScanHoaDon()),
              );
            },
            icon: const Icon(Icons.camera_alt),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Thông tin chung'),
              TextFormField(
                controller: _soPhieuController,
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
                controller: _donViController,
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
                controller: _boPhanController,
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
                    _ngayNhapKho == null
                        ? 'Chọn ngày'
                        : formatDate(_ngayNhapKho!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _noController,
                      decoration: const InputDecoration(labelText: 'Nợ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _coController,
                      decoration: const InputDecoration(labelText: 'Có'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maSoController,
                decoration: const InputDecoration(labelText: 'Mã số'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nguoiGiaoController,
                decoration: const InputDecoration(labelText: 'Người giao'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _theoController,
                decoration: const InputDecoration(labelText: 'Theo'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tongTienController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Tổng tiền',
                  helperText: 'Tự động tính từ sản phẩm',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _soChungTuGocController,
                decoration: const InputDecoration(labelText: 'Số chứng từ gốc'),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Sản phẩm'),
              for (var index = 0; index < _products.length; index++)
                _buildProductCard(index),
              TextButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Thêm sản phẩm'),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Chữ ký'),
              TextFormField(
                controller: _nguoiLapPhieuController,
                decoration: const InputDecoration(labelText: 'Người lập phiếu'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nguoiGiaoHangController,
                decoration: const InputDecoration(labelText: 'Người giao hàng'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thuKhoController,
                decoration: const InputDecoration(labelText: 'Thủ kho'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keToanTruongController,
                decoration: const InputDecoration(labelText: 'Kế toán trưởng'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_isEditing ? 'Cập nhật hóa đơn' : 'Lưu hóa đơn'),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildProductCard(int index) {
    final product = _products[index];

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
                if (_products.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeProduct(index),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: product.nameController,
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
              controller: product.maSoController,
              decoration: const InputDecoration(labelText: 'Mã số'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: product.thucNhanController,
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
                    controller: product.donGiaController,
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
              controller: product.thanhTienController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Thành tiền'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFormData {
  _ProductFormData({this.onChanged}) {
    thucNhanController.addListener(_updateThanhTien);
    donGiaController.addListener(_updateThanhTien);
  }

  final VoidCallback? onChanged;
  final idController = TextEditingController();
  final nameController = TextEditingController();
  final maSoController = TextEditingController();
  final thucNhanController = TextEditingController();
  final donGiaController = TextEditingController();
  final thanhTienController = TextEditingController();

  void _updateThanhTien() {
    final soLuong = _parseNumber(thucNhanController.text);
    final donGia = _parseNumber(donGiaController.text);

    if (soLuong == null || donGia == null) {
      if (thanhTienController.text.isNotEmpty) {
        thanhTienController.clear();
      }
      onChanged?.call();
      return;
    }

    thanhTienController.text = formatNumberVn(soLuong * donGia);
    onChanged?.call();
  }

  double? get amount => _parseNumber(thanhTienController.text);

  double? _parseNumber(String input) {
    var value = input.trim();
    if (value.isEmpty) {
      return null;
    }

    final hasDot = value.contains('.');
    final hasComma = value.contains(',');

    if (hasDot && hasComma) {
      // Dạng Việt Nam: 1.234.567,89
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasComma) {
      // Dạng thập phân: 1234,56
      value = value.replaceAll(',', '.');
    } else if (hasDot) {
      final dotCount = '.'.allMatches(value).length;
      final decimalPart = value.split('.').last;
      final looksLikeThousandsSeparator =
          dotCount > 1 || decimalPart.length == 3;

      if (looksLikeThousandsSeparator) {
        value = value.replaceAll('.', '');
      }
    }

    return double.tryParse(value);
  }

  Product toProduct(String chungTu) {
    return Product(
      id: idController.text.trim(),
      name: nameController.text.trim(),
      maSo: maSoController.text.trim(),
      chungTu: chungTu,
      thucNhan: thucNhanController.text.trim(),
      donGia: donGiaController.text.trim(),
      thanhTien: thanhTienController.text.trim(),
    );
  }

  void dispose() {
    idController.dispose();
    nameController.dispose();
    maSoController.dispose();
    thucNhanController.dispose();
    donGiaController.dispose();
    thanhTienController.dispose();
  }
}
