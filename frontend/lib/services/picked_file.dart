import 'dart:typed_data';

/// A file selected by the user, with its bytes already loaded into memory.
///
/// We carry the bytes (not a path) so the same type works on web — where there
/// is no filesystem path — and on native platforms alike.
class PickedFile {
  final String name;
  final Uint8List bytes;

  const PickedFile({required this.name, required this.bytes});
}
