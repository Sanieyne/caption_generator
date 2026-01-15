import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import '../utils/app_constants.dart';

class BackendCaptionService {
  Future<BackendCaptionResult> generate(Uint8List imageBytes) async {
    final baseUrl = AppConstants.backendBaseUrl;
    if (baseUrl.isEmpty) {
      throw Exception("Missing BACKEND_BASE_URL. Set it via --dart-define.");
    }

    final uri = Uri.parse("$baseUrl${AppConstants.captionEndpoint}");

    final request = http.MultipartRequest("POST", uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        "image",
        imageBytes,
        filename: "image.jpg",
        contentType: http_parser.MediaType("image", "jpeg"),
      ),
    );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    final data = jsonDecode(res.body);
    if (data is! Map) {
      throw Exception("Unexpected API response: ${res.body}");
    }

    final successValue = data["success"];
    final isSuccess = successValue == true ||
        successValue?.toString().toLowerCase() == "true";

    if (res.statusCode != 200 || !isSuccess) {
      final message = data["message"]?.toString() ??
          data["error"]?.toString() ??
          res.body;
      throw Exception("Caption API failed: $message");
    }

    final description = data["description"]?.toString() ??
        data["image_description"]?.toString() ??
        data["imageDescription"]?.toString();
    final captionsRaw = data["captions"];

    if (description == null) {
      throw Exception("Missing description in API response: ${res.body}");
    }

    final captions = <String>[];
    if (captionsRaw is List) {
      captions.addAll(
        captionsRaw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty),
      );
    } else if (captionsRaw is String) {
      captions.addAll(
        captionsRaw
            .split("\n")
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
    }

    return BackendCaptionResult(
      description: description,
      captions: captions,
    );
  }
}

class BackendCaptionResult {
  final String description;
  final List<String> captions;

  BackendCaptionResult({
    required this.description,
    required this.captions,
  });
}
