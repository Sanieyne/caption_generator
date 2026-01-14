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
    final contentType = res.headers["content-type"] ?? "";

    if (res.statusCode != 200) {
      String message = res.body;
      if (contentType.contains("application/json")) {
        try {
          final data = jsonDecode(res.body);
          if (data is Map) {
            if (data["error"] != null) {
              message = data["error"].toString();
            } else if (data["estimated_time"] != null) {
              message =
                  "Model loading. Try again in ~${data["estimated_time"]}s.";
            }
          }
        } catch (_) {
          // Leave message as raw body if JSON parsing fails.
        }
      } else if (contentType.contains("text/html")) {
        message =
            "Hugging Face returned HTML. Ensure the model supports Inference API and set HF_TOKEN via --dart-define.";
      }

      throw Exception("Image caption API failed: ${res.statusCode} $message");
    }

    final data = jsonDecode(res.body);

    if (data is Map && data["error"] != null) {
      throw Exception("Image caption API failed: ${data["error"]}");
    }

    // BLIP inference often returns: [{"generated_text":"..."}]
    if (data is List && data.isNotEmpty && data[0]["generated_text"] != null) {
      return data[0]["generated_text"].toString();
    }

    throw Exception("Unexpected BLIP response: ${res.body}");
  }
}
