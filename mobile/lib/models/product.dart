class Product {
  const Product({
    this.id = '',
    this.name = '',
    this.maSo = '',
    this.chungTu = '',
    this.thucNhan = '',
    this.donGia = '',
    this.thanhTien = '',
  });

  final String id;
  final String name;
  final String maSo;
  final String chungTu;
  final String thucNhan;
  final String donGia;
  final String thanhTien;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      maSo: json['maSo']?.toString() ?? '',
      chungTu: json['chungTu']?.toString() ?? '',
      thucNhan: json['thucNhan']?.toString() ?? '',
      donGia: json['donGia']?.toString() ?? '',
      thanhTien: json['thanhTien']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'maSo': maSo,
      'chungTu': chungTu,
      'thucNhan': thucNhan,
      'donGia': donGia,
      'thanhTien': thanhTien,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? maSo,
    String? chungTu,
    String? thucNhan,
    String? donGia,
    String? thanhTien,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      maSo: maSo ?? this.maSo,
      chungTu: chungTu ?? this.chungTu,
      thucNhan: thucNhan ?? this.thucNhan,
      donGia: donGia ?? this.donGia,
      thanhTien: thanhTien ?? this.thanhTien,
    );
  }
}
