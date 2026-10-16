// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Map<String, dynamic>?> pickImageCrossPlatform() async {
  final completer = Completer<Map<String, dynamic>?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();

  input.onChange.listen((e) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files[0];
    final reader = html.FileReader();
    reader.onLoadEnd.listen((e) {
      final result = reader.result;
      if (result is Uint8List) {
        if (!completer.isCompleted) {
          completer.complete({
            'name': file.name,
            'bytes': result,
          });
        }
      } else if (result is ByteBuffer) {
        if (!completer.isCompleted) {
          completer.complete({
            'name': file.name,
            'bytes': Uint8List.view(result),
          });
        }
      } else {
        if (!completer.isCompleted) completer.complete(null);
      }
    });
    reader.onError.listen((e) {
      if (!completer.isCompleted) completer.complete(null);
    });
    reader.readAsArrayBuffer(file);
  });

  return completer.future;
}
