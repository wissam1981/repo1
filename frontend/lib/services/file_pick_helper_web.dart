import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'picked_file.dart';

/// Web implementation using a native browser `<input type="file">` element.
///
/// This sidesteps file_picker entirely on web, avoiding its static
/// `Platform.operatingSystem` detection which throws `Unsupported operation`
/// when compiled for the browser.
Future<PickedFile?> pickContractFile() async {
  final input = html.FileUploadInputElement()
    ..accept = '.pdf,.doc,.docx,.txt,.md'
    ..multiple = false;
  input.click();

  // Wait for the user to choose a file (or cancel the dialog).
  await input.onChange.first;

  final files = input.files;
  if (files == null || files.isEmpty) return null;

  final file = files.first;

  final reader = html.FileReader();
  final completer = Completer<Uint8List>();
  reader.onLoadEnd.listen((_) {
    completer.complete(reader.result as Uint8List);
  });
  reader.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(Exception('Failed to read file'));
    }
  });
  reader.readAsArrayBuffer(file);

  final bytes = await completer.future;
  return PickedFile(name: file.name, bytes: bytes);
}
