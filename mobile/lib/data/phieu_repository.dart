import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/models/thongTinPhieu.dart';



abstract class PhieuRepository {
  Stream<List<ThongTinPhieu>> watchPhieuList();

  Future<String> addPhieu(ThongTinPhieu phieu);

  Future<void> updatePhieu(ThongTinPhieu phieu);

  Future<void> deletePhieu(String id);
}

class FirestorePhieuRepository implements PhieuRepository {
  FirestorePhieuRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const collectionName = 'phieu_nhap_kho';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  @override
  Stream<List<ThongTinPhieu>> watchPhieuList() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  @override
  Future<String> addPhieu(ThongTinPhieu phieu) async {
    final docRef = await _collection.add({
      ..._toDoc(phieu),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  @override
  Future<void> updatePhieu(ThongTinPhieu phieu) async {
    if (phieu.id.isEmpty) {
      throw ArgumentError('Phiếu không có id, không thể cập nhật.');
    }
    await _collection.doc(phieu.id).update(_toDoc(phieu));
  }

  @override
  Future<void> deletePhieu(String id) async {
    if (id.isEmpty) return;
    await _collection.doc(id).delete();
  }

  static Map<String, dynamic> _toDoc(ThongTinPhieu phieu) {
    final json = phieu.toJson();
    json.remove('id');
    final ngayNhapKho = phieu.ngayNhapKho;
    if (ngayNhapKho != null) {
      json['ngayNhapKho'] = Timestamp.fromDate(ngayNhapKho);
    }
    return json;
  }

  static ThongTinPhieu _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final json = Map<String, dynamic>.from(doc.data());
    json['id'] = doc.id;
    json['ngayNhapKho'] = _dateFromJson(json['ngayNhapKho']);
    return ThongTinPhieu.fromJson(json);
  }

  static DateTime? _dateFromJson(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
