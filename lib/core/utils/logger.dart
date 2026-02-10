import 'package:logger/logger.dart' as log;
import 'package:multi_bt_audio/core/constants/app_enums.dart';
import '../errors/app_exception.dart';

class AppLogger {
  static final _logger = log.Logger(
    printer: log.PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  static void debug(String message) => _logger.d(message);
  static void info(String message) => _logger.i(message);
  static void warning(String message) => _logger.w(message);

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void logException(AppException exception) {
    switch (exception.severity) {
      case ErrorSeverity.info:
        info('[${exception.code}] ${exception.message}');
        break;
      case ErrorSeverity.warning:
        warning('[${exception.code}] ${exception.message}');
        break;
      case ErrorSeverity.error:
      case ErrorSeverity.critical:
        error(
          '[${exception.code}] ${exception.message}',
          exception.originalError,
          exception.stackTrace,
        );
        break;
    }
  }
}