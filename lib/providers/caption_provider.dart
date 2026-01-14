import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/hf_image_caption_service.dart';
import '../services/hf_text_gen_service.dart';
import '../services/rate_limit_service.dart';
import '../services/admob_service.dart';

class CaptionProvider extends ChangeNotifier {
  final _imgService = HfImageCaptionService();
  final _textService = HfTextGenService();
  final _rate = RateLimitService();

  final AdMobService ads;

  CaptionProvider({required this.ads});

  bool loading = false;
  String? error;

  String? imageDescription;
  List<String> captions = [];

  Future<int> remainingToday() => _rate.remaining();

  void clear() {
    error = null;
    imageDescription = null;
    captions = [];
    notifyListeners();
  }

  Future<void> generateFromImageBytes(Uint8List? imageBytes) async {
    error = null;

    if (imageBytes == null) {
      error = "Please select an image first.";
      notifyListeners();
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      error = "No internet connection.";
      notifyListeners();
      return;
    }

    final can = await _rate.canGenerate();
    if (!can) {
      error = "Daily limit reached (5/day). Try tomorrow.";
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    try {
      // Interstitial on click
      ads.showInterstitialIfReady();

      final desc = await _imgService.captionImage(imageBytes);
      final caps = await _textService.generateCaptions(imageDescription: desc);

      imageDescription = desc;
      captions = caps;

      await _rate.consumeOne();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
