import 'package:connectivity_plus/connectivity_plus.dart';

/// 네트워크 관련 유틸리티
class NetworkUtils {
  static final NetworkUtils instance = NetworkUtils._init();
  final Connectivity _connectivity = Connectivity();

  NetworkUtils._init();

  /// 네트워크 연결 상태 확인
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      print('네트워크 상태 확인 실패: $e');
      return false;
    }
  }

  /// 네트워크 연결 상태 스트림
  Stream<List<ConnectivityResult>> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }

  /// 재시도 로직 (지수 백오프)
  Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          rethrow;
        }
        
        print('재시도 $attempt/$maxAttempts, ${delay.inSeconds}초 후 재시도...');
        await Future.delayed(delay);
        delay *= 2; // 지수 백오프
      }
    }

    throw Exception('최대 재시도 횟수 초과');
  }
}
