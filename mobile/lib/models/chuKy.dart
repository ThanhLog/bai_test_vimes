class ChuKy {
  const ChuKy({
    this.nguoiLapPhieu = '',
    this.nguoiGiaoHang = '',
    this.thuKho = '',
    this.keToanTruong = '',
  });

  final String nguoiLapPhieu;
  final String nguoiGiaoHang;
  final String thuKho;
  final String keToanTruong;

  factory ChuKy.fromJson(Map<String, dynamic> json) {
    return ChuKy(
      nguoiLapPhieu: json['nguoiLapPhieu']?.toString() ?? '',
      nguoiGiaoHang: json['nguoiGiaoHang']?.toString() ?? '',
      thuKho: json['thuKho']?.toString() ?? '',
      keToanTruong: json['keToanTruong']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nguoiLapPhieu': nguoiLapPhieu,
      'nguoiGiaoHang': nguoiGiaoHang,
      'thuKho': thuKho,
      'keToanTruong': keToanTruong,
    };
  }

  ChuKy copyWith({
    String? nguoiLapPhieu,
    String? nguoiGiaoHang,
    String? thuKho,
    String? keToanTruong,
  }) {
    return ChuKy(
      nguoiLapPhieu: nguoiLapPhieu ?? this.nguoiLapPhieu,
      nguoiGiaoHang: nguoiGiaoHang ?? this.nguoiGiaoHang,
      thuKho: thuKho ?? this.thuKho,
      keToanTruong: keToanTruong ?? this.keToanTruong,
    );
  }
}
