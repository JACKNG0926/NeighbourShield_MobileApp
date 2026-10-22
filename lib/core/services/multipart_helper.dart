import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Sends form fields plus an optional photo as multipart/form-data
/// (what Django's MultiPartParser expects). Uses bytes, so it works on web too.
class MultipartHelper {
  static Future<http.Response> post({
    required Uri url,
    required String token,
    required Map<String, String> fields,
    XFile? image,
    String imageField = 'image',
  }) async {
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Token $token'
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final name = image.name.isNotEmpty ? image.name : 'upload.jpg';
      request.files.add(
        http.MultipartFile.fromBytes(imageField, bytes, filename: name),
      );
    }

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }
}
