import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'web_image_picker_stub.dart'
    if (dart.library.html) 'web_image_picker_web.dart' as web_picker;

class PickedImageData {
  final String name;
  final Uint8List bytes;

  PickedImageData({required this.name, required this.bytes});
}

Future<PickedImageData?> pickImageFile() async {
  if (kIsWeb) {
    try {
      final res = await web_picker.pickImageCrossPlatform();
      if (res != null) {
        return PickedImageData(
          name: res['name'] as String,
          bytes: res['bytes'] as Uint8List,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Web HTML file picker error: $e');
    }
  }

  // Fallback / Mobile implementation using ImagePicker
  try {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      maxHeight: 1400,
      imageQuality: 70,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      return PickedImageData(name: img.name, bytes: bytes);
    }
  } catch (e) {
    debugPrint('ImagePicker error: $e');
  }
  return null;
}
