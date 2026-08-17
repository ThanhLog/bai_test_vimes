# VIMES - Phiếu Nhập Kho

Ứng dụng Flutter quản lý **Phiếu Nhập Kho** theo mẫu VIMES.

Ứng dụng hỗ trợ:

* Nhập thông tin phiếu nhập kho.
* Nhập danh sách sản phẩm.
* Tự động tính thành tiền và tổng tiền.
* Chỉnh sửa và xóa phiếu.
* Lưu dữ liệu lên Firebase Cloud Firestore.
* Nhập dữ liệu từ file PDF/DOCX.
* Kiểm thử bằng Unit Test.

## 1. Yêu cầu bài test

Project đáp ứng các yêu cầu:

| Yêu cầu                         | Trạng thái |
| ------------------------------- | ---------- |
| Thiết kế cấu trúc cơ sở dữ liệu | ✅          |
| Thiết kế giao diện nhập liệu    | ✅          |
| Nhập liệu và lưu dữ liệu        | ✅          |
| Viết Unit Test                  | ✅          |

Theo yêu cầu đề bài, project sử dụng:

* **Ngôn ngữ:** Dart
* **Framework:** Flutter
* **Database:** Firebase Cloud Firestore
* **State management:** flutter_bloc
* **Testing:** flutter_test

---

# 2. Công nghệ sử dụng

* Flutter
* Dart
* Firebase Core
* Firebase Cloud Firestore
* Flutter Bloc
* File Picker
* Syncfusion PDF
* Archive
* Flutter Test

Các dependency chính được khai báo trong `mobile/pubspec.yaml`.

---

# 3. Kiến trúc project

```text
bai_test_vimes/
│
├── README.md
├── Mẫu Phiếu Nhập Kho - VIMES.docx
├── Mẫu Phiếu Nhập Kho - VIMES.pdf
│
└── mobile/
    │
    ├── lib/
    │   │
    │   ├── compoents/
    │   │   ├── cubit/
    │   │   │   ├── phieu_form/
    │   │   │   └── phieu_list/
    │   │   │
    │   │   ├── data/
    │   │   │   └── phieu_repository.dart
    │   │   │
    │   │   ├── models/
    │   │   │   ├── chuKy.dart
    │   │   │   ├── product.dart
    │   │   │   └── thongTinPhieu.dart
    │   │   │
    │   │   ├── screens/
    │   │   │   ├── them_hoa_don.dart
    │   │   │   ├── sua_hoa_don.dart
    │   │   │   ├── chi_tiet_don.dart
    │   │   │   └── list_hoa_don.dart
    │   │   │
    │   │   └── utils/
    │   │       ├── utils.dart
    │   │       ├── phieu_nhap_kho_file_parser.dart
    │   │       └── phieu_nhap_kho_ocr_normalizer.dart
    │   │
    │   ├── test/
    │   │
    │   ├── firebase.json
    │   └── pubspec.yaml
    │
    └── ...
```

---

# 4. Thiết kế cơ sở dữ liệu

Project sử dụng Firebase Cloud Firestore.

Collection chính:

```text
phieu_nhap_kho
```

Mỗi document đại diện cho một phiếu nhập kho.

## 4.1. Collection `phieu_nhap_kho`

```text
phieu_nhap_kho
│
└── {documentId}
    │
    ├── soPhieu
    ├── donVi
    ├── boPhan
    ├── ngayNhapKho
    ├── no
    ├── co
    ├── maSo
    ├── nguoiGiao
    ├── theo
    ├── tongTien
    ├── soChungTuGoc
    ├── createdAt
    │
    ├── products[]
    │   ├── id
    │   ├── name
    │   ├── maSo
    │   ├── chungTu
    │   ├── thucNhan
    │   ├── donGia
    │   └── thanhTien
    │
    └── chuKy
        ├── nguoiLapPhieu
        ├── nguoiGiaoHang
        ├── thuKho
        └── keToanTruong
```

## 4.2. Thông tin phiếu

| Field          | Type      | Mô tả           |
| -------------- | --------- | --------------- |
| `soPhieu`      | String    | Số phiếu        |
| `donVi`        | String    | Đơn vị          |
| `boPhan`       | String    | Bộ phận         |
| `ngayNhapKho`  | Timestamp | Ngày nhập kho   |
| `no`           | String    | Tài khoản Nợ    |
| `co`           | String    | Tài khoản Có    |
| `maSo`         | String    | Mã số           |
| `nguoiGiao`    | String    | Người giao      |
| `theo`         | String    | Theo chứng từ   |
| `tongTien`     | String    | Tổng tiền       |
| `soChungTuGoc` | String    | Số chứng từ gốc |
| `createdAt`    | Timestamp | Thời gian tạo   |

## 4.3. Sản phẩm

Mỗi phiếu có thể chứa nhiều sản phẩm:

```json
{
  "id": "",
  "name": "Tên sản phẩm",
  "maSo": "SP001",
  "chungTu": "PN001",
  "thucNhan": "10",
  "donGia": "50.000",
  "thanhTien": "500.000"
}
```

## 4.4. Chữ ký

```json
{
  "nguoiLapPhieu": "",
  "nguoiGiaoHang": "",
  "thuKho": "",
  "keToanTruong": ""
}
```

Các cấu trúc trên tương ứng với các model `ThongTinPhieu`, `Product` và `ChuKy` trong source code.

---

# 5. Repository Pattern

Project tách phần Firebase ra khỏi UI thông qua interface:

```text
PhieuRepository
```

Repository cung cấp:

```dart
Stream<List<ThongTinPhieu>> watchPhieuList();

Future<String> addPhieu(ThongTinPhieu phieu);

Future<void> updatePhieu(ThongTinPhieu phieu);

Future<void> deletePhieu(String id);
```

Implementation:

```text
FirestorePhieuRepository
```

Collection được sử dụng:

```text
phieu_nhap_kho
```

Khi thêm phiếu, Firestore tự tạo document ID.

Khi cập nhật hoặc xóa, document được truy cập thông qua ID.

---

# 6. Giao diện nhập liệu

Màn hình chính để nhập phiếu:

```text
lib/screens/them_hoa_don.dart
```

Giao diện được chia thành 3 phần.

## 6.1. Thông tin chung

Các trường:

* Số phiếu
* Đơn vị
* Bộ phận
* Ngày nhập kho
* Nợ
* Có
* Mã số
* Người giao
* Theo
* Tổng tiền
* Số chứng từ gốc

Trong đó:

```text
Số phiếu *
Đơn vị *
```

là các trường bắt buộc.

## 6.2. Danh sách sản phẩm

Người dùng có thể:

```text
+ Thêm sản phẩm
```

Mỗi sản phẩm gồm:

* Tên sản phẩm
* Mã số
* Thực nhận
* Đơn giá
* Thành tiền

`Thành tiền` được tính tự động:

```text
Thành tiền = Thực nhận × Đơn giá
```

Tổng tiền của phiếu:

```text
Tổng tiền = Σ Thành tiền của tất cả sản phẩm
```

## 6.3. Chữ ký

Các trường:

* Người lập phiếu
* Người giao hàng
* Thủ kho
* Kế toán trưởng

---

# 7. Luồng lưu dữ liệu

```text
User
 │
 ▼
ThemHoaDon
 │
 ▼
PhieuFormCubit
 │
 ▼
_buildPhieu()
 │
 ▼
PhieuRepository
 │
 ▼
FirestorePhieuRepository
 │
 ▼
Firebase Cloud Firestore
 │
 ▼
phieu_nhap_kho
```

---

# 8. Import PDF/DOCX

Ứng dụng hỗ trợ chọn file:

```text
PDF
DOCX
```

Sau khi người dùng chọn file:

```text
File
 │
 ▼
File Picker
 │
 ▼
PhieuNhapKhoFileParser
 │
 ▼
ImportedPhieuNhapKho
 │
 ▼
PhieuFormCubit
 │
 ▼
Form nhập liệu
```

Thông tin có thể được tự động điền từ file:

* Số phiếu
* Đơn vị
* Bộ phận
* Ngày nhập kho
* Người giao
* Thông tin chứng từ
* Danh sách sản phẩm
* Thông tin chữ ký

Người dùng vẫn có thể kiểm tra và chỉnh sửa dữ liệu trước khi lưu.

---

# 9. Unit Test

Unit test nằm tại:

```text
mobile/test/
```

Các nhóm test nên bao gồm:

## Model

Kiểm tra:

* `Product.toJson()`
* `Product.fromJson()`
* `Product.copyWith()`
* `ChuKy.toJson()`
* `ChuKy.fromJson()`
* `ThongTinPhieu.toJson()`
* `ThongTinPhieu.fromJson()`
* Serialize/deserialize danh sách sản phẩm.

## Utils

Kiểm tra:

* Format ngày.
* Parse số Việt Nam.
* Format số Việt Nam.
* Format input số.
* Số nguyên.
* Số thập phân.
* Dữ liệu rỗng.
* Dữ liệu không hợp lệ.

## PhieuFormCubit

Kiểm tra:

* Khởi tạo form.
* Cập nhật số phiếu.
* Thêm sản phẩm.
* Xóa sản phẩm.
* Cập nhật tên sản phẩm.
* Cập nhật số lượng.
* Cập nhật đơn giá.
* Tự động tính thành tiền.
* Tự động tính tổng tiền.
* Lưu phiếu mới.
* Cập nhật phiếu.
* Xử lý lỗi repository.

---

# 10. Chạy project

Di chuyển vào thư mục Flutter:

```bash
cd mobile
```

Cài dependency:

```bash
flutter pub get
```

Kiểm tra code:

```bash
flutter analyze
```

Chạy ứng dụng:

```bash
flutter run
```

---

# 11. Chạy Unit Test

Chạy toàn bộ test:

```bash
flutter test
```

Chạy test với thông tin chi tiết:

```bash
flutter test -r expanded
```

Chạy một file test:

```bash
flutter test test/models_test.dart
```

---

# 12. Firebase

Project sử dụng:

```text
firebase_core
cloud_firestore
```

Firebase configuration nằm trong:

```text
mobile/firebase.json
mobile/lib/firebase_options.dart
```

Database:

```text
Cloud Firestore
```

Collection:

```text
phieu_nhap_kho
```

---

# 13. Đối chiếu yêu cầu

### Yêu cầu 1 - Thiết kế cấu trúc cơ sở dữ liệu

Đã thực hiện:

```text
phieu_nhap_kho
 ├── thông tin phiếu
 ├── products[]
 ├── chuKy
 └── createdAt
```

### Yêu cầu 2 - Thiết kế giao diện nhập liệu

Đã thực hiện tại:

```text
lib/screens/them_hoa_don.dart
```

Có form nhập thông tin phiếu, sản phẩm và chữ ký.

### Yêu cầu 3 - Nhập liệu và lưu dữ liệu

Đã thực hiện thông qua:

```text
ThemHoaDon
    ↓
PhieuFormCubit
    ↓
PhieuRepository
    ↓
FirestorePhieuRepository
    ↓
Cloud Firestore
```

### Yêu cầu 4 - Unit Test

Test được đặt trong:

```text
mobile/test/
```

và chạy bằng:

```bash
flutter test
```

---

# 14. Kết luận

Project sử dụng kiến trúc tách biệt giữa:

```text
UI
 ↓
Cubit
 ↓
Repository
 ↓
Firebase
```

Giúp code dễ bảo trì, dễ mở rộng và thuận tiện cho việc viết Unit Test.

**Author:** ThanhLog
