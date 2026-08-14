import 'package:flutter/material.dart';
import 'package:mobile/models/thongTinPhieu.dart';
import 'package:mobile/screens/them_hoa_don.dart';

class SuaHoaDon extends StatelessWidget {
  const SuaHoaDon({super.key, required this.phieu});

  final ThongTinPhieu phieu;

  @override
  Widget build(BuildContext context) {
    return ThemHoaDon(initialInvoice: phieu);
  }
}
