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

    if (res.statusCode != 200 || data["success"] != true) {
      final message = data["message"]?.toString() ?? res.body;
      throw Exception("Caption API failed: $message");
    }

    final description = data["description"]?.toString();
    final captionsRaw = data["captions"];

    if (description == null || captionsRaw is! List) {
      throw Exception("Missing fields in API response: ${res.body}");
    }

    final captions = captionsRaw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

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
