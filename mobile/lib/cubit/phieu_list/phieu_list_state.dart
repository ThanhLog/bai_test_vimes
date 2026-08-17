import 'package:mobile/models/thongTinPhieu.dart';

class PhieuListState {
  const PhieuListState({
    this.phieus = const <ThongTinPhieu>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ThongTinPhieu> phieus;
  final bool isLoading;
  final String? errorMessage;

  PhieuListState copyWith({
    List<ThongTinPhieu>? phieus,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PhieuListState(
      phieus: phieus ?? this.phieus,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
