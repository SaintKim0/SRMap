/// 앱에서 발생하는 에러 타입
enum AppErrorType {
  network,
  server,
  database,
  permission,
  validation,
  unknown,
}

/// 앱 에러 클래스
class AppError implements Exception {
  final AppErrorType type;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'AppError($type): $message';
  }
}

/// 에러 핸들러
class ErrorHandler {
  /// 에러를 사용자 친화적인 메시지로 변환
  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppError) {
      return error.message;
    }

    // 네트워크 에러
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException') ||
        error.toString().contains('Failed host lookup')) {
      return '인터넷 연결을 확인해주세요';
    }

    // 타임아웃 에러
    if (error.toString().contains('TimeoutException')) {
      return '요청 시간이 초과되었습니다. 다시 시도해주세요';
    }

    // 서버 에러
    if (error.toString().contains('500') ||
        error.toString().contains('502') ||
        error.toString().contains('503')) {
      return '서버에 일시적인 문제가 발생했습니다';
    }

    // 권한 에러
    if (error.toString().contains('Permission') ||
        error.toString().contains('Denied')) {
      return '필요한 권한이 없습니다';
    }

    // 기본 메시지
    return '오류가 발생했습니다. 잠시 후 다시 시도해주세요';
  }

  /// 에러 로깅
  static void logError(dynamic error, StackTrace? stackTrace) {
    print('=== 에러 발생 ===');
    print('Error: $error');
    if (stackTrace != null) {
      print('StackTrace: $stackTrace');
    }
    print('================');
    
    // TODO: 프로덕션에서는 Firebase Crashlytics 등으로 전송
  }

  /// 에러 처리 및 사용자 메시지 반환
  static String handleError(dynamic error, [StackTrace? stackTrace]) {
    logError(error, stackTrace);
    return getUserFriendlyMessage(error);
  }
}
