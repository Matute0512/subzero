import 'package:flutter/widgets.dart';

/// Contrato abstracto para el servicio de anuncios y mediación (Google AdMob).
///
/// Encapsula la interacción con redes publicitarias garantizando que las capas de presentación
/// y dominio permanezcan agnósticas de implementaciones de terceros.
abstract class IAdService {
  /// Inicializa el SDK de mediación y prepara los listeners de ciclo de vida.
  Future<void> initialize();

  /// Muestra un anuncio de pantalla completa intersticial configurado en [placementName].
  Future<void> showInterstitial({required String placementName});

  /// Muestra un anuncio de video bonificado asociado a [placementName] y ejecuta [onRewarded] al completarse.
  Future<void> showRewardedVideo({
    required String placementName,
    required Function onRewarded,
  });

  /// Retorna un widget embebible con el anuncio Banner asociado al [placementName].
  Widget getBannerWidget({required String placementName});

  /// Libera los recursos del SDK de ads.
  ///
  /// Debe llamarse cuando la app deja de necesitar anuncios: los objetos de
  /// anuncio quedan vivos en el SDK si no se liberan (P1-4).
  Future<void> dispose();
}

