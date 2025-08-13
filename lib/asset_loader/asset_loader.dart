import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AssetLoader {
  static final AssetLoader _instance = AssetLoader._internal();
  factory AssetLoader() => _instance;
  AssetLoader._internal();

  bool _started = false;
  late Future<void> _loadingFuture;

  // Store loaded JSON/text data
  final Map<String, String> _jsonCache = {};

  Future<void> startLoading(BuildContext context) {
    if (_started) return _loadingFuture;
    _started = true;

    _loadingFuture = _loadAssets(context);
    return _loadingFuture;
  }

  Future<void> _loadAssets(BuildContext context) async {
    debugPrint("🔄 Starting asset preloading...");

    await Future.wait([
      // Images (requires context)
      precacheImage(
        const AssetImage("assets/icons/auto_marker_top_view.png"),
        context,
      ),
      precacheImage(const AssetImage("assets/icons/auto_marker.png"), context),
      precacheImage(const AssetImage("assets/icons/bike_marker.png"), context),
      precacheImage(const AssetImage("assets/icons/green_marker.png"), context),
      precacheImage(const AssetImage("assets/icons/red_marker.png"), context),
      precacheImage(const AssetImage("assets/icons/splash.png"), context),
      precacheImage(const AssetImage("assets/icons/taxi.png"), context),
      precacheImage(const AssetImage("assets/icons/car.png"), context),
      precacheImage(const AssetImage("assets/icons/motorbike.png"), context),

      // JSON / text files (no context needed)
      // rootBundle.loadString("assets/map/map_style.json"),
      _loadAndCacheJson("assets/map/map_style.json"),
    ]);

    debugPrint("✅ All assets loaded.");
  }

  Future<void> _loadAndCacheJson(String path) async {
    final data = await rootBundle.loadString(path);
    _jsonCache[path] = data;
  }

  String getJson(String path) => _jsonCache[path] ?? '';

  Future<void> whenReady() => _loadingFuture;
}
