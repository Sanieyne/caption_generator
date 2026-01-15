import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/caption_provider.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  BannerAd? banner;

  @override
  void initState() {
    super.initState();
    final ads = context.read<CaptionProvider>().ads;

    banner = ads.createBanner()
      ..load();
  }

  @override
  void dispose() {
    banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CaptionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Results")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (vm.imageDescription != null) ...[
                  const Text("Image Description", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(vm.imageDescription!),
                  const SizedBox(height: 18),
                ],
                const Text("Captions", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (vm.captions.isEmpty)
                  const Text("No captions returned."),
                ...vm.captions.map((c) => Card(
                      child: ListTile(
                        title: Text(c),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () async {
                            // optional: clipboard copy
                          },
                        ),
                      ),
                    )),
              ],
            ),
          ),

          if (banner != null)
            SafeArea(
              child: SizedBox(
                height: banner!.size.height.toDouble(),
                width: banner!.size.width.toDouble(),
                child: AdWidget(ad: banner!),
              ),
            ),
        ],
      ),
    );
  }
}
