import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Class to manage API configurations
class ApiConfig {
  final String sepoliaEndpoint;
  final String mainnetEndpoint;
  final String serviceAccountPath;

  ApiConfig({
    required this.sepoliaEndpoint,
    required this.mainnetEndpoint,
    required this.serviceAccountPath,
  });

  /// Load configuration from secure storage if available,
  /// otherwise from assets and then save to secure storage
  static Future<ApiConfig> load() async {
    const secureStorage = FlutterSecureStorage();

    // Try to load from secure storage first
    String? configJson = await secureStorage.read(key: 'api_config');

    if (configJson == null) {
      // If not in secure storage, load from assets
      configJson = await rootBundle.loadString('assets/config/api_config.json');

      // Save to secure storage for future use
      await secureStorage.write(key: 'api_config', value: configJson);
    }

    final Map<String, dynamic> config = json.decode(configJson);

    return ApiConfig(
      sepoliaEndpoint: config['sepolia_endpoint'],
      mainnetEndpoint: config['mainnet_endpoint'],
      serviceAccountPath: config['service_account_path'],
    );
  }
}
