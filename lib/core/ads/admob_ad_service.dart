import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';

import '../di/injection_container.dart';
import '../../features/monetization/data/datasources/in_app_purchase_datasource.dart';
import '../utils/logger.dart';
import 'ad_service.dart';

/// Implementación de producción para [IAdService] utilizando Google Mobile Ads (AdMob).
///
/// Gestiona el ciclo de vida de la inicialización, anuncios intersticiales precargados,
/// anuncios bonificados (rewarded) y banners nativos integrados en la UI.
///
/// Los identificadores de Ad Unit admiten sobreescritura mediante `--dart-define`:
/// ```sh
/// flutter build appbundle --release \
///   --dart-define=ADMOB_BANNER_ID=ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy \
///   --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy \
///   --dart-define=ADMOB_REWARDED_ID=ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy
/// ```
class AdMobAdService implements IAdService {
  static const String _tag = 'AdMobAdService';

  // ===========================================================================
  // Identificadores de Prueba Oficiales de Google AdMob
  // ===========================================================================
  static const String _androidDemoBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _androidDemoInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String _androidDemoRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const String _iosDemoBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const String _iosDemoInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const String _iosDemoRewarded = 'ca-app-pub-3940256099942544/1712485313';

  // ===========================================================================
  // Identificadores de Producción de SubZero (Inyectados vía secrets.json)
  // ===========================================================================
  // Para evitar filtraciones en repositorios públicos, el código base no almacena
  // IDs comerciales en texto plano. Los IDs reales se inyectan en tiempo de compilación
  // mediante '--dart-define-from-file=secrets.json'. Si no se definen, se usan
  // de forma segura los bloques de prueba oficiales de Google.
  static const String _androidProdBanner = _androidDemoBanner;
  static const String _androidProdInterstitial = _androidDemoInterstitial;
  static const String _androidProdRewarded = _androidDemoRewarded;

  final String? customBannerAdUnitId;
  final String? customInterstitialAdUnitId;
  final String? customRewardedAdUnitId;

  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  AdMobAdService({
    this.customBannerAdUnitId,
    this.customInterstitialAdUnitId,
    this.customRewardedAdUnitId,
  });

  bool get isInitialized => _isInitialized;

  String get bannerAdUnitId {
    if (customBannerAdUnitId != null) return customBannerAdUnitId!;
    const envId = String.fromEnvironment('ADMOB_BANNER_ID');
    if (envId.isNotEmpty) return envId;
    if (kReleaseMode) {
      return defaultTargetPlatform == TargetPlatform.iOS ? _iosDemoBanner : _androidProdBanner;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ? _iosDemoBanner : _androidDemoBanner;
  }

  String get interstitialAdUnitId {
    if (customInterstitialAdUnitId != null) return customInterstitialAdUnitId!;
    const envId = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
    if (envId.isNotEmpty) return envId;
    if (kReleaseMode) {
      return defaultTargetPlatform == TargetPlatform.iOS ? _iosDemoInterstitial : _androidProdInterstitial;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ? _iosDemoInterstitial : _androidDemoInterstitial;
  }

  String get rewardedAdUnitId {
    if (customRewardedAdUnitId != null) return customRewardedAdUnitId!;
    const envId = String.fromEnvironment('ADMOB_REWARDED_ID');
    if (envId.isNotEmpty) return envId;
    if (kReleaseMode) {
      return defaultTargetPlatform == TargetPlatform.iOS ? _iosDemoRewarded : _androidProdRewarded;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ? _iosDemoRewarded : _androidDemoRewarded;
  }

  /// Consulta si el usuario es Pro de forma segura y sin bloquear la UI.
  bool _checkIsProSafe() {
    try {
      if (sl.isRegistered<Box<dynamic>>(instanceName: 'monetization_box')) {
        final box = sl<Box<dynamic>>(instanceName: 'monetization_box');
        return box.get(IInAppPurchaseDataSource.proUserKey, defaultValue: false) == true;
      }
    } catch (_) {}
    return false;
  }

  /// Espera a que concluya la inicialización asíncrona del SDK de AdMob si está en curso.
  Future<void> waitForInitialization() {
    if (_isInitialized) return Future.value();
    final inFlight = _initCompleter;
    if (inFlight != null) return inFlight.future;
    return initialize();
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug('El SDK de Google Mobile Ads ya se encuentra inicializado.', tag: _tag);
      return;
    }

    final inFlight = _initCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<void>();
    _initCompleter = completer;

    try {
      _warnIfUsingDemoCredentialsInRelease();

      AppLogger.info('Iniciando Google Mobile Ads SDK...', tag: _tag);
      await MobileAds.instance.initialize();
      _isInitialized = true;
      AppLogger.info('Google Mobile Ads inicializado exitosamente.', tag: _tag);

      // Precargar anuncios en segundo plano tras inicialización solo si el usuario no es Pro
      final isPro = _checkIsProSafe();
      if (!isPro) {
        _loadInterstitial();
        _loadRewarded();
      } else {
        AppLogger.info('Usuario Pro detectado; se omite la precarga de anuncios para ahorrar memoria y red.', tag: _tag);
      }

      if (!completer.isCompleted) completer.complete();
    } catch (e, stackTrace) {
      _isInitialized = false;
      AppLogger.error(
        'Fallo al inicializar Google Mobile Ads',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      if (!completer.isCompleted) completer.complete();
      _initCompleter = null;
      rethrow;
    }
  }

  void _warnIfUsingDemoCredentialsInRelease() {
    if (!kReleaseMode) return;

    if (bannerAdUnitId == _androidDemoBanner || bannerAdUnitId == _iosDemoBanner) {
      AppLogger.warning(
        'AdMob está usando el banner de prueba en modo Release. Recuerda configurar ADMOB_BANNER_ID.',
        tag: _tag,
      );
    }
    if (interstitialAdUnitId == _androidDemoInterstitial || interstitialAdUnitId == _iosDemoInterstitial) {
      AppLogger.warning(
        'AdMob está usando el intersticial de prueba en modo Release. Recuerda configurar ADMOB_INTERSTITIAL_ID.',
        tag: _tag,
      );
    }
  }

  // ===========================================================================
  // Interstitial Ad Management
  // ===========================================================================

  void _loadInterstitial() {
    if (_checkIsProSafe()) return;
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    AppLogger.debug('Precargando anuncio Intersticial ($interstitialAdUnitId)...', tag: _tag);

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isInterstitialLoading = false;
          _interstitialAd = ad;
          AppLogger.info('Intersticial cargado exitosamente.', tag: _tag);

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              AppLogger.debug('Intersticial cerrado por el usuario. Liberando y recargando...', tag: _tag);
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              AppLogger.error('Error al mostrar intersticial: ${error.message}', tag: _tag);
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
          AppLogger.warning('Fallo al cargar Intersticial: [${error.code}] ${error.message}', tag: _tag);
        },
      ),
    );
  }

  @override
  Future<void> showInterstitial({required String placementName}) async {
    if (_checkIsProSafe()) {
      AppLogger.debug('Usuario Pro: omitiendo intersticial para $placementName', tag: _tag);
      return;
    }

    if (!_isInitialized) {
      AppLogger.warning('Intento de mostrar intersticial antes de inicializar SDK.', tag: _tag);
      return;
    }

    if (_interstitialAd != null) {
      AppLogger.info('Mostrando anuncio Intersticial para placement: $placementName', tag: _tag);
      await _interstitialAd!.show();
    } else {
      AppLogger.info('Intersticial no listo al momento de solicitar. Solicitando carga...', tag: _tag);
      _loadInterstitial();
    }
  }

  // ===========================================================================
  // Rewarded Ad Management
  // ===========================================================================

  void _loadRewarded() {
    if (_checkIsProSafe()) return;
    if (_isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;

    AppLogger.debug('Precargando anuncio Bonificado ($rewardedAdUnitId)...', tag: _tag);

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isRewardedLoading = false;
          _rewardedAd = ad;
          AppLogger.info('Anuncio Bonificado cargado exitosamente.', tag: _tag);

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              AppLogger.debug('Anuncio Bonificado cerrado. Liberando y recargando...', tag: _tag);
              ad.dispose();
              _rewardedAd = null;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              AppLogger.error('Error al mostrar anuncio bonificado: ${error.message}', tag: _tag);
              ad.dispose();
              _rewardedAd = null;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          _rewardedAd = null;
          AppLogger.warning('Fallo al cargar Anuncio Bonificado: [${error.code}] ${error.message}', tag: _tag);
        },
      ),
    );
  }

  @override
  Future<void> showRewardedVideo({
    required String placementName,
    required Function onRewarded,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('Intento de mostrar video bonificado antes de inicializar SDK.', tag: _tag);
      return;
    }

    if (_rewardedAd != null) {
      AppLogger.info('Mostrando Video Bonificado para placement: $placementName', tag: _tag);
      await _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          AppLogger.info(
            'Recompensa de AdMob otorgada: ${reward.type} (${reward.amount})',
            tag: _tag,
          );
          try {
            onRewarded();
          } catch (e, stack) {
            AppLogger.error('Error ejecutando callback onRewarded', tag: _tag, error: e, stackTrace: stack);
          }
        },
      );
    } else {
      AppLogger.info('Video bonificado no listo al momento de solicitar. Solicitando carga...', tag: _tag);
      _loadRewarded();
    }
  }

  // ===========================================================================
  // Banner Widget
  // ===========================================================================

  @override
  Widget getBannerWidget({required String placementName}) {
    AppLogger.debug('Construyendo AdMobBannerWidget para placement: $placementName', tag: _tag);
    return AdMobBannerWidget(
      adUnitId: bannerAdUnitId,
      placementName: placementName,
    );
  }

  // ===========================================================================
  // Dispose
  // ===========================================================================

  @override
  Future<void> dispose() async {
    try {
      await _interstitialAd?.dispose();
      await _rewardedAd?.dispose();
    } catch (e, stack) {
      AppLogger.warning('Error al liberar anuncios en AdMobAdService', tag: _tag, error: e, stackTrace: stack);
    } finally {
      _interstitialAd = null;
      _rewardedAd = null;
      _isInterstitialLoading = false;
      _isRewardedLoading = false;
      _isInitialized = false;
      _initCompleter = null;
    }
  }
}

/// Widget contenedor que gestiona el ciclo de vida del banner publicitario de AdMob.
class AdMobBannerWidget extends StatefulWidget {
  final String adUnitId;
  final String placementName;

  const AdMobBannerWidget({
    super.key,
    required this.adUnitId,
    required this.placementName,
  });

  @override
  State<AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> {
  static const String _bannerTag = 'AdMobBanner';
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerSafely();
  }

  Future<void> _loadBannerSafely() async {
    // Si la inicialización del SDK de AdMob aún está en curso en segundo plano,
    // esperamos asíncronamente antes de solicitar el banner.
    if (sl.isRegistered<IAdService>()) {
      final service = sl<IAdService>();
      if (service is AdMobAdService && !service.isInitialized) {
        try {
          await service.waitForInitialization();
        } catch (e) {
          AppLogger.warning('Fallo esperando inicialización de AdMob para el banner: $e', tag: _bannerTag);
          return;
        }
      }
    }

    if (!mounted) return;
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
          AppLogger.info('Banner de AdMob cargado exitosamente (${widget.placementName})', tag: _bannerTag);
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.warning('Fallo al cargar Banner AdMob: [${error.code}] ${error.message}', tag: _bannerTag);
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
            });
          }
        },
        onAdOpened: (_) => AppLogger.debug('Banner AdMob abierto', tag: _bannerTag),
        onAdClosed: (_) => AppLogger.debug('Banner AdMob cerrado', tag: _bannerTag),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
