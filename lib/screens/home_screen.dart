import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/caption_provider.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final picker = ImagePicker();
  Uint8List? imageBytes;
  String? _lastError;

  Future<void> pickImage() async {
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => imageBytes = bytes);

    // clear old results
    context.read<CaptionProvider>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CaptionProvider>();

    if (vm.error != null && vm.error != _lastError) {
      _lastError = vm.error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error!)),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Caption Generator")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: imageBytes == null
                      ? const Center(child: Text("Tap to pick image"))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(imageBytes!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 14),
        
              FutureBuilder<int>(
                future: vm.remainingToday(),
                builder: (context, snap) {
                  final remaining = snap.data;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      remaining == null ? "Daily remaining: ..." : "Daily remaining: $remaining/5",
                      style: TextStyle(color: Colors.black.withOpacity(0.7)),
                    ),
                  );
                },
              ),
        
              const SizedBox(height: 12),
        
              if (vm.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: vm.error == "No internet connection."
                        ? Colors.orange.withOpacity(0.12)
                        : Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        vm.error == "No internet connection."
                            ? Icons.wifi_off
                            : Icons.error_outline,
                        color: vm.error == "No internet connection."
                            ? Colors.orange
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vm.error!,
                          style: TextStyle(
                            color: vm.error == "No internet connection."
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        
              const Spacer(),
        
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: vm.loading
                      ? null
                      : () async {
                          await vm.generateFromImageBytes(imageBytes);
                          if (vm.error == null && vm.captions.isNotEmpty && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ResultScreen()),
                            );
                          }
                        },
                  icon: vm.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(vm.loading ? "Generating..." : "Generate Captions"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
