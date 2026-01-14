import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_constants.dart';

class HfTextGenService {
  Future<List<String>> generateCaptions({
    required String imageDescription,
  }) async {
    final uri = Uri.parse(
      "https://api-inference.huggingface.co/models/${AppConstants.textGenModel}",
    );

    final headers = <String, String>{
      "Content-Type": "application/json",
    };

    if (AppConstants.hfToken.isNotEmpty) {
      headers["Authorization"] = "Bearer ${AppConstants.hfToken}";
    }

    final prompt = """
You are a social media caption writer.
Image description: "$imageDescription"

Generate 5 short captions.
Rules:
- Friendly, catchy
- No hashtags-only lines
- Each caption on a new line
""";

    final body = jsonEncode({
      "inputs": prompt,
      "parameters": {
        "max_new_tokens": 120,
        "temperature": 0.9,
        "return_full_text": false,
      }
    });

    final res = await http.post(uri, headers: headers, body: body);
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

      throw Exception("Text generation API failed: ${res.statusCode} $message");
    }

    final data = jsonDecode(res.body);

    if (data is Map && data["error"] != null) {
      throw Exception("Text generation API failed: ${data["error"]}");
    }

    // Many HF text models return: [{"generated_text":"..."}]
    String raw;
    if (data is List && data.isNotEmpty && data[0]["generated_text"] != null) {
      raw = data[0]["generated_text"].toString();
    } else if (data is Map && data["generated_text"] != null) {
      raw = data["generated_text"].toString();
    } else {
      throw Exception("Unexpected text gen response: ${res.body}");
    }

    // Split into lines, clean, keep top 5
    final lines = raw
        .split("\n")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // If model outputs bullets like "1) caption", clean them:
    final cleaned = lines.map((line) {
      return line.replaceAll(RegExp(r"^\d+[\)\.\-]\s*"), "").trim();
    }).toList();

    return cleaned.take(5).toList();
  }
}
