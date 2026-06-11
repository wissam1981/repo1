/// Cross-platform contract file picker library.
///
/// The concrete implementation is chosen at compile time:
///   - Web  -> `file_pick_helper_web.dart` (browser `<input type=file>`)
///   - Native (iOS/Android/desktop) -> `file_pick_helper_io.dart` (file_picker)
///
/// This avoids the file_picker 6.x web bug where its static platform detector
/// calls `Platform.operatingSystem`, which is unsupported on web.
export 'picked_file.dart';
export 'file_pick_helper_io.dart'
    if (dart.library.html) 'file_pick_helper_web.dart';
