import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../utils/app_constants.dart';

class HfImageCaptionService {
  Future<String> captionImage(Uint8List imageBytes) async {
    final uri = Uri.parse(
      "https://api-inference.huggingface.co/models/${AppConstants.blipModel}",
    );

    final headers = <String, String>{
      "Content-Type": "application/octet-stream",
    };

    if (AppConstants.hfToken.isNotEmpty) {
      headers["Authorization"] = "Bearer ${AppConstants.hfToken}";
    }

    final res = await http.post(uri, headers: headers, body: imageBytes);

    if (res.statusCode != 200) {
      throw Exception("Image caption API failed: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body);

    // BLIP inference often returns: [{"generated_text":"..."}]
    if (data is List && data.isNotEmpty && data[0]["generated_text"] != null) {
      return data[0]["generated_text"].toString();
    }

    throw Exception("Unexpected BLIP response: ${res.body}");
  }
}
