import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class EnvironmentConfig {
  static const String _localhostUrl = 'http://127.0.0.1:8000/api';
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000/api';
  static const String _localNetworkUrl =
      'http://192.168.43.82:8000/api'; // IP locale de votre ordinateur

  /// Détecte l'environnement actuel et retourne l'URL appropriée
  static String getBaseUrl() {
    if (kIsWeb) {
      // Pour le web, on utilise localhost
      return _localhostUrl;
    } else if (Platform.isAndroid) {
      // Pour Android (émulateur ou appareil physique)
      // Pour l'instant, on utilise l'IP locale pour les tests sur appareil physique
      // Si vous voulez tester sur émulateur, changez manuellement ci-dessous
      return _localNetworkUrl;
    } else if (Platform.isIOS) {
      // Pour iOS simulator, on utilise localhost
      return _localhostUrl;
    } else {
      // Pour desktop, etc.
      return _localhostUrl;
    }
  }

  /// Méthode pour configurer manuellement l'URL si nécessaire
  static String getCustomUrl(String customUrl) {
    return customUrl;
  }

  /// Retourne l'URL pour un appareil physique sur le réseau local
  static String getLocalNetworkUrl(String localIp) {
    return 'http://$localIp:8000/api';
  }

  /// Méthode pour obtenir l'URL de l'émulateur Android (si besoin de tester)
  static String getAndroidEmulatorUrl() {
    return _androidEmulatorUrl;
  }

  /// Méthode pour obtenir l'URL localhost
  static String getLocalhostUrl() {
    return _localhostUrl;
  }

  /// Méthode pour obtenir des informations de débogage sur l'environnement
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'platform': Platform.operatingSystem,
      'isAndroid': Platform.isAndroid,
      'isIOS': Platform.isIOS,
      'isWeb': kIsWeb,
      'isWindows': Platform.isWindows,
      'isMacOS': Platform.isMacOS,
      'isLinux': Platform.isLinux,
      'currentUrl': getBaseUrl(),
    };
  }
}
