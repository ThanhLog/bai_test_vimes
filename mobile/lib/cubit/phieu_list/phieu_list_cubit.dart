import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/cubit/phieu_list/phieu_list_state.dart';
import 'package:mobile/data/phieu_repository.dart';
import 'package:mobile/models/thongTinPhieu.dart';


class PhieuListCubit extends Cubit<PhieuListState> {
  PhieuListCubit(this._repository)
      : super(const PhieuListState(isLoading: true)) {
    _subscribe();
  }

  final PhieuRepository _repository;
  StreamSubscription<List<ThongTinPhieu>>? _subscription;

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _repository.watchPhieuList().listen(
      (phieus) {
        emit(PhieuListState(phieus: phieus, isLoading: false));
      },
      onError: (Object error) {
        emit(
          PhieuListState(
            phieus: state.phieus,
            isLoading: false,
            errorMessage: 'Không thể tải danh sách phiếu: $error',
          ),
        );
      },
    );
  }

  void retry() {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    _subscribe();
  }

  Future<String?> deletePhieu(ThongTinPhieu phieu) async {
    try {
      await _repository.deletePhieu(phieu.id);
      return null;
    } catch (e) {
      return 'Không thể xóa phiếu: $e';
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
