import 'package:file_picker/file_picker.dart';
import 'picked_file.dart';

/// Native (iOS/Android/macOS/Windows/Linux) implementation.
///
/// file_picker works correctly off the web, so we use it directly and request
/// the bytes in memory via `withData: true`.
Future<PickedFile?> pickContractFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'doc', 'docx'],
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) return null;

  return PickedFile(name: file.name, bytes: bytes);
}
