/// Build-time values loaded from the `.env` file.
///
/// Pass the file when running or building:
/// `flutter run --dart-define-from-file=.env`
abstract final class AppEnv {
  /// PIN that unlocks the BMS Commands page. Empty when not configured.
  static const bmsCommandPin = String.fromEnvironment('BMS_COMMAND_PIN');
}
