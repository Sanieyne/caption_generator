import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/admob_service.dart';
import 'providers/caption_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ads = AdMobService();
  await ads.init();
  ads.loadInterstitial();

  runApp(DevicePreview(
    enabled: kDebugMode,
    builder: (context) => MyApp(ads: ads),
  ));
}

class MyApp extends StatelessWidget {
  final AdMobService ads;
  const MyApp({super.key, required this.ads});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaptionProvider(ads: ads),
      child: MaterialApp(
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        debugShowCheckedModeBanner: false,
        title: 'Caption Generator',
        theme: ThemeData(useMaterial3: true),
        home: const HomeScreen(),
      ),
    );
  }
}
